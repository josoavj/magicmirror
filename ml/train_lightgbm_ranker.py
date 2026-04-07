#!/usr/bin/env python3
# ruff: noqa: E402
from __future__ import annotations

"""Train a lightweight outfit relevance model with LightGBM.

Input file supports CSV or JSONL and must include a binary label column named
`label` (1 = relevant/liked, 0 = not relevant/disliked).

Example:
    python ml/train_lightgbm_ranker.py \\
      --input data/outfit_feedback_events.jsonl \\
      --model-out ml/artifacts/outfit_ranker.joblib \\
      --metrics-out ml/artifacts/metrics.json
"""

import argparse
import json
import logging
import sys
import time
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from lightgbm import LGBMClassifier, early_stopping, log_evaluation
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    classification_report,
    log_loss,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

REQUIRED_COLUMNS = {"label"}

# NOTE: user_id and outfit_id are intentionally excluded — including raw IDs
# as features causes data leakage and prevents generalisation to unseen users
# or outfits. If you need entity embeddings, handle them separately.
NUMERIC_CANDIDATES = [
    "age",
    "height_cm",
    "weather_temp",
    "weather_humidity",
    "weather_wind",
    "seen_7d_count",
    "feedback_style_bias",
    "feedback_outfit_bias",
]

# Boolean-like columns that are better treated as 0/1 numerics
BOOLEAN_CANDIDATES = [
    "strict_weather_mode",
    "is_weekend",
]

CATEGORICAL_CANDIDATES = [
    "morphology",
    "planning_context",
    "weather_main",
    "hour_slot",
    "styles",
    "preferred_styles",
]

# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------


def _read_input(path: Path) -> pd.DataFrame:
    """Read CSV or JSONL into a DataFrame."""
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {path}")

    suffix = path.suffix.lower()

    if suffix == ".csv":
        df = pd.read_csv(path)
        log.info("Loaded %d rows from CSV: %s", len(df), path)
        return df

    if suffix in {".jsonl", ".ndjson"}:
        rows: list[dict[str, Any]] = []
        with path.open("r", encoding="utf-8") as f:
            for i, line in enumerate(f, start=1):
                raw = line.strip()
                if not raw:
                    continue
                try:
                    row = json.loads(raw)
                except json.JSONDecodeError as exc:
                    raise ValueError(f"Invalid JSON on line {i}: {exc}") from exc
                if isinstance(row, dict):
                    rows.append(row)
        df = pd.DataFrame(rows)
        log.info("Loaded %d rows from JSONL: %s", len(df), path)
        return df

    raise ValueError(f"Unsupported input format '{suffix}'. Use .csv or .jsonl")


def _ensure_columns(df: pd.DataFrame) -> None:
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")


def _validate_labels(df: pd.DataFrame) -> None:
    """Ensure the label column contains only 0 and 1 (after dropping NaNs)."""
    null_count = df["label"].isna().sum()
    if null_count:
        raise ValueError(f"Column 'label' has {null_count} missing value(s). Fill or drop them.")

    unique_vals = set(df["label"].unique())
    allowed = {0, 1, 0.0, 1.0, True, False}
    if not unique_vals.issubset(allowed):
        raise ValueError(
            f"Column 'label' must contain only 0/1, got unexpected values: "
            f"{unique_vals - allowed}"
        )


def _log_class_distribution(y: pd.Series, split_name: str = "full") -> float:
    """Log class distribution and return the positive rate."""
    pos = int(y.sum())
    total = len(y)
    rate = pos / total if total else 0.0
    log.info(
        "[%s] class distribution — positives: %d/%d (%.1f%%)",
        split_name,
        pos,
        total,
        rate * 100,
    )
    return rate


# ---------------------------------------------------------------------------
# Feature engineering
# ---------------------------------------------------------------------------


def _normalize_multivalue_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Join list-valued columns into pipe-separated strings for OHE."""
    out = df.copy()
    for col in ["styles", "preferred_styles"]:
        if col in out.columns:
            out[col] = out[col].apply(
                lambda v: "|".join(sorted(v))  # sorted for reproducibility
                if isinstance(v, list)
                else ("" if pd.isna(v) else str(v))
            )
    return out


def _cast_boolean_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Cast boolean-like columns to 0/1 integers so they feed into numeric pipeline."""
    out = df.copy()
    for col in BOOLEAN_CANDIDATES:
        if col in out.columns:
            out[col] = out[col].map(
                {True: 1, False: 0, "true": 1, "false": 0, "True": 1, "False": 0, 1: 1, 0: 0}
            )
    return out


def _build_preprocessor(df: pd.DataFrame) -> tuple[ColumnTransformer, list[str], list[str], list[str]]:
    """Build a ColumnTransformer that handles numeric, boolean, and categorical features."""
    numeric_cols = [c for c in NUMERIC_CANDIDATES if c in df.columns]
    boolean_cols = [c for c in BOOLEAN_CANDIDATES if c in df.columns]
    categorical_cols = [c for c in CATEGORICAL_CANDIDATES if c in df.columns]

    all_feature_cols = numeric_cols + boolean_cols + categorical_cols
    if not all_feature_cols:
        raise ValueError("No supported feature columns found in dataset")

    log.info(
        "Features — numeric: %s | boolean: %s | categorical: %s",
        numeric_cols,
        boolean_cols,
        categorical_cols,
    )

    numeric_pipe = Pipeline(
        steps=[("imputer", SimpleImputer(strategy="median"))]
    )
    boolean_pipe = Pipeline(
        steps=[("imputer", SimpleImputer(strategy="most_frequent"))]
    )
    categorical_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]
    )

    transformers: list[tuple[str, Any, list[str]]] = []
    if numeric_cols:
        transformers.append(("num", numeric_pipe, numeric_cols))
    if boolean_cols:
        transformers.append(("bool", boolean_pipe, boolean_cols))
    if categorical_cols:
        transformers.append(("cat", categorical_pipe, categorical_cols))

    preprocessor = ColumnTransformer(transformers=transformers, remainder="drop")
    return preprocessor, numeric_cols, boolean_cols, categorical_cols


# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------


def _compute_scale_pos_weight(y: pd.Series) -> float:
    """Return scale_pos_weight to handle class imbalance (LightGBM native param)."""
    neg = (y == 0).sum()
    pos = (y == 1).sum()
    if pos == 0:
        raise ValueError("No positive samples in training set.")
    weight = neg / pos
    if weight > 2.0:
        log.warning(
            "Class imbalance detected (neg/pos=%.2f). Applying scale_pos_weight.",
            weight,
        )
    return float(weight)


def _find_optimal_threshold(y_true: np.ndarray, proba: np.ndarray) -> float:
    """Find the probability threshold that maximises F1 on the validation set."""
    best_f1, best_thr = 0.0, 0.5
    for thr in np.arange(0.1, 0.91, 0.01):
        pred = (proba >= thr).astype(int)
        tp = ((pred == 1) & (y_true == 1)).sum()
        fp = ((pred == 1) & (y_true == 0)).sum()
        fn = ((pred == 0) & (y_true == 1)).sum()
        precision = tp / (tp + fp) if (tp + fp) else 0.0
        recall = tp / (tp + fn) if (tp + fn) else 0.0
        f1 = (
            2 * precision * recall / (precision + recall)
            if (precision + recall)
            else 0.0
        )
        if f1 > best_f1:
            best_f1, best_thr = f1, float(thr)
    log.info("Optimal threshold: %.2f  (val F1=%.4f)", best_thr, best_f1)
    return best_thr


def _safe_metric(fn, *args, **kwargs) -> float | None:
    """Call a metric function, returning None on failure instead of crashing."""
    try:
        return float(fn(*args, **kwargs))
    except Exception as exc:  # noqa: BLE001
        log.warning("Metric %s could not be computed: %s", fn.__name__, exc)
        return None


def train(args: argparse.Namespace) -> dict[str, Any]:
    t0 = time.perf_counter()

    # --- Load & validate ---
    df = _read_input(Path(args.input))
    _ensure_columns(df)
    _validate_labels(df)
    df = _normalize_multivalue_columns(df)
    df = _cast_boolean_columns(df)

    if len(df) < args.min_samples:
        raise ValueError(
            f"Dataset too small: {len(df)} rows, require >= {args.min_samples}"
        )

    y = df["label"].astype(int)
    # Drop IDs and label — IDs are excluded to prevent leakage
    drop_cols = {"label", "user_id", "outfit_id"} & set(df.columns)
    X = df.drop(columns=list(drop_cols))

    _log_class_distribution(y, "full dataset")

    preprocessor, numeric_cols, boolean_cols, categorical_cols = _build_preprocessor(X)

    # --- Train / validation split ---
    X_train, X_valid, y_train, y_valid = train_test_split(
        X,
        y,
        test_size=args.valid_size,
        random_state=args.seed,
        stratify=y if y.nunique() > 1 else None,
    )
    _log_class_distribution(y_train, "train")
    _log_class_distribution(y_valid, "valid")

    # --- Classifier ---
    scale_pos_weight = _compute_scale_pos_weight(y_train)

    clf = LGBMClassifier(
        n_estimators=args.n_estimators,
        learning_rate=args.learning_rate,
        num_leaves=args.num_leaves,
        subsample=0.9,
        colsample_bytree=0.9,
        scale_pos_weight=scale_pos_weight,
        random_state=args.seed,
        n_jobs=-1,           # use all available CPU cores
        verbose=-1,          # suppress LightGBM's own stdout spam
    )

    model = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("classifier", clf),
        ]
    )

    # Fit with early stopping when supported (requires eval set passthrough)
    # We pass the raw X_valid because the preprocessor is part of the pipeline.
    # LightGBM early stopping inside a sklearn Pipeline requires fit_params trick.
    fit_params: dict[str, Any] = {}
    if args.early_stopping_rounds:
        # sklearn Pipeline routes fit params via step__param naming convention
        fit_params["classifier__eval_set"] = [
            (preprocessor.fit_transform(X_train, y_train), y_train),
            (preprocessor.transform(X_valid), y_valid),
        ]
        fit_params["classifier__callbacks"] = [
            early_stopping(stopping_rounds=args.early_stopping_rounds, verbose=False),
            log_evaluation(period=50),
        ]
        # We must fit preprocessor first to pass transformed data to eval_set
        preprocessor.fit(X_train, y_train)
        clf.fit(
            preprocessor.transform(X_train),
            y_train,
            **{k.replace("classifier__", ""): v for k, v in fit_params.items()},
        )
        # Reassemble pipeline with already-fitted steps
        model = Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("classifier", clf),
            ]
        )
    else:
        model.fit(X_train, y_train)

    # --- Metrics ---
    proba = model.predict_proba(X_valid)[:, 1]
    y_valid_np = np.array(y_valid)

    optimal_threshold = _find_optimal_threshold(y_valid_np, proba)
    pred = (proba >= optimal_threshold).astype(int)

    n_unique_valid = len(np.unique(y_valid_np))

    metrics: dict[str, Any] = {
        "train_rows": int(len(X_train)),
        "valid_rows": int(len(X_valid)),
        "features_numeric": numeric_cols,
        "features_boolean": boolean_cols,
        "features_categorical": categorical_cols,
        "optimal_threshold": round(optimal_threshold, 4),
        "accuracy": float(accuracy_score(y_valid_np, pred)),
        "log_loss": _safe_metric(log_loss, y_valid_np, proba, labels=[0, 1]),
        "auc_roc": _safe_metric(roc_auc_score, y_valid_np, proba) if n_unique_valid > 1 else None,
        "auc_pr": _safe_metric(average_precision_score, y_valid_np, proba) if n_unique_valid > 1 else None,
        "classification_report": classification_report(
            y_valid_np, pred, output_dict=True, zero_division=0
        ),
        "training_time_s": round(time.perf_counter() - t0, 2),
    }

    # --- Cross-validation summary (optional) ---
    if args.cv_folds and args.cv_folds > 1:
        log.info("Running %d-fold cross-validation …", args.cv_folds)
        cv_aucs: list[float] = []
        skf = StratifiedKFold(n_splits=args.cv_folds, shuffle=True, random_state=args.seed)
        for fold, (train_idx, val_idx) in enumerate(skf.split(X, y), start=1):
            cv_model = Pipeline(
                steps=[
                    ("preprocessor", ColumnTransformer(
                        transformers=preprocessor.transformers, remainder="drop"
                    )),
                    ("classifier", LGBMClassifier(
                        n_estimators=args.n_estimators,
                        learning_rate=args.learning_rate,
                        num_leaves=args.num_leaves,
                        subsample=0.9,
                        colsample_bytree=0.9,
                        scale_pos_weight=scale_pos_weight,
                        random_state=args.seed,
                        n_jobs=-1,
                        verbose=-1,
                    )),
                ]
            )
            cv_model.fit(X.iloc[train_idx], y.iloc[train_idx])
            cv_proba = cv_model.predict_proba(X.iloc[val_idx])[:, 1]
            auc = _safe_metric(roc_auc_score, y.iloc[val_idx].values, cv_proba)
            if auc is not None:
                cv_aucs.append(auc)
                log.info("  Fold %d AUC-ROC: %.4f", fold, auc)
        if cv_aucs:
            metrics["cv_auc_mean"] = round(float(np.mean(cv_aucs)), 4)
            metrics["cv_auc_std"] = round(float(np.std(cv_aucs)), 4)
            log.info(
                "CV AUC-ROC: %.4f ± %.4f", metrics["cv_auc_mean"], metrics["cv_auc_std"]
            )

    # --- Persist ---
    out_path = Path(args.model_out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump({"model": model, "threshold": optimal_threshold}, out_path)
    log.info("Model saved → %s", out_path)

    metrics_path = Path(args.metrics_out)
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    log.info("Metrics saved → %s", metrics_path)

    return metrics


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Train LightGBM outfit ranker",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--input", required=True, help="Path to CSV or JSONL training data")
    parser.add_argument(
        "--model-out",
        default="ml/artifacts/outfit_ranker.joblib",
        help="Output path for serialized model (joblib dict with 'model' and 'threshold')",
    )
    parser.add_argument(
        "--metrics-out",
        default="ml/artifacts/metrics.json",
        help="Output path for metrics JSON",
    )
    parser.add_argument("--min-samples", type=int, default=200,
                        help="Minimum number of rows required to train")
    parser.add_argument("--valid-size", type=float, default=0.2,
                        help="Fraction of data used for validation")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--n-estimators", type=int, default=300)
    parser.add_argument("--learning-rate", type=float, default=0.05)
    parser.add_argument("--num-leaves", type=int, default=31)
    parser.add_argument(
        "--early-stopping-rounds",
        type=int,
        default=30,
        help="Stop training if validation metric does not improve for N rounds (0 = disabled)",
    )
    parser.add_argument(
        "--cv-folds",
        type=int,
        default=0,
        help="Number of cross-validation folds (0 = disabled)",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    try:
        metrics = train(args)
    except (FileNotFoundError, ValueError) as exc:
        log.error("%s", exc)
        sys.exit(1)

    # Print a clean summary (exclude verbose classification report)
    summary = {k: v for k, v in metrics.items() if k != "classification_report"}
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()