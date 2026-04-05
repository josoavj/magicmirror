#!/usr/bin/env python3
"""Train a lightweight outfit relevance model with LightGBM.

Input file supports CSV or JSONL and must include a binary label column named
`label` (1 = relevant/liked, 0 = not relevant/disliked).

Example:
    python ml/train_lightgbm_ranker.py \
      --input data/outfit_feedback_events.jsonl \
      --model-out ml/artifacts/outfit_ranker.joblib \
      --metrics-out ml/artifacts/metrics.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from lightgbm import LGBMClassifier
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score, log_loss, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder


REQUIRED_COLUMNS = {"label"}

NUMERIC_CANDIDATES = [
    "age",
    "weather_temp",
    "weather_humidity",
    "weather_wind",
    "seen_7d_count",
    "feedback_style_bias",
    "feedback_outfit_bias",
]

CATEGORICAL_CANDIDATES = [
    "user_id",
    "outfit_id",
    "morphology",
    "planning_context",
    "weather_main",
    "hour_slot",
    "strict_weather_mode",
    "is_weekend",
    "styles",
    "preferred_styles",
]


def _read_input(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {path}")

    if path.suffix.lower() == ".csv":
        return pd.read_csv(path)

    if path.suffix.lower() in {".jsonl", ".ndjson"}:
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
        return pd.DataFrame(rows)

    raise ValueError("Unsupported input format. Use .csv or .jsonl")


def _ensure_columns(df: pd.DataFrame) -> None:
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")


def _normalize_multivalue_columns(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    for col in ["styles", "preferred_styles"]:
        if col in out.columns:
            out[col] = out[col].apply(
                lambda v: "|".join(v) if isinstance(v, list) else ("" if pd.isna(v) else str(v))
            )
    return out


def _build_preprocessor(df: pd.DataFrame) -> tuple[ColumnTransformer, list[str], list[str]]:
    numeric_cols = [c for c in NUMERIC_CANDIDATES if c in df.columns]
    categorical_cols = [c for c in CATEGORICAL_CANDIDATES if c in df.columns]

    if not numeric_cols and not categorical_cols:
        raise ValueError("No supported feature columns found in dataset")

    numeric_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
        ]
    )
    categorical_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]
    )

    transformers = []
    if numeric_cols:
        transformers.append(("num", numeric_pipe, numeric_cols))
    if categorical_cols:
        transformers.append(("cat", categorical_pipe, categorical_cols))

    preprocessor = ColumnTransformer(transformers=transformers)
    return preprocessor, numeric_cols, categorical_cols


def train(args: argparse.Namespace) -> dict[str, Any]:
    df = _read_input(Path(args.input))
    _ensure_columns(df)
    df = _normalize_multivalue_columns(df)

    if len(df) < args.min_samples:
        raise ValueError(
            f"Dataset too small: {len(df)} rows, require >= {args.min_samples}"
        )

    y = df["label"].astype(int)
    X = df.drop(columns=["label"])

    preprocessor, numeric_cols, categorical_cols = _build_preprocessor(X)

    X_train, X_valid, y_train, y_valid = train_test_split(
        X,
        y,
        test_size=args.valid_size,
        random_state=args.seed,
        stratify=y if y.nunique() > 1 else None,
    )

    clf = LGBMClassifier(
        n_estimators=args.n_estimators,
        learning_rate=args.learning_rate,
        num_leaves=args.num_leaves,
        subsample=0.9,
        colsample_bytree=0.9,
        random_state=args.seed,
    )

    model = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("classifier", clf),
        ]
    )

    model.fit(X_train, y_train)

    proba = model.predict_proba(X_valid)[:, 1]
    pred = (proba >= 0.5).astype(int)

    metrics: dict[str, Any] = {
        "train_rows": int(len(X_train)),
        "valid_rows": int(len(X_valid)),
        "features_numeric": numeric_cols,
        "features_categorical": categorical_cols,
        "accuracy": float(accuracy_score(y_valid, pred)),
        "log_loss": float(log_loss(y_valid, proba, labels=[0, 1])),
    }

    if len(np.unique(y_valid)) > 1:
        metrics["auc"] = float(roc_auc_score(y_valid, proba))
    else:
        metrics["auc"] = None

    out_path = Path(args.model_out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, out_path)

    metrics_path = Path(args.metrics_out)
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    return metrics


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Train LightGBM outfit ranker")
    parser.add_argument("--input", required=True, help="Path to CSV or JSONL training data")
    parser.add_argument(
        "--model-out",
        default="ml/artifacts/outfit_ranker.joblib",
        help="Output path for serialized model",
    )
    parser.add_argument(
        "--metrics-out",
        default="ml/artifacts/metrics.json",
        help="Output path for metrics JSON",
    )
    parser.add_argument("--min-samples", type=int, default=200)
    parser.add_argument("--valid-size", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--n-estimators", type=int, default=300)
    parser.add_argument("--learning-rate", type=float, default=0.05)
    parser.add_argument("--num-leaves", type=int, default=31)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    metrics = train(args)
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
