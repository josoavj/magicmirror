#!/usr/bin/env python3
"""Score outfit candidates with a trained LightGBM model.

The model artefact is expected to be a dict saved by train_lightgbm_ranker.py:
    {"model": <sklearn Pipeline>, "threshold": <float>}

Example:
    python ml/score_lightgbm_ranker.py \\
      --model ml/artifacts/outfit_ranker.joblib \\
      --input data/outfit_candidates.jsonl \\
      --output ml/artifacts/scored_candidates.csv

Output columns added:
    ml_score  – raw positive-class probability  [0.0, 1.0]
    ml_label  – binary prediction using the threshold from training
    ml_rank   – rank within each (user_id, context_id) group (1 = best)
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
import time
from pathlib import Path
from typing import Any

import joblib
import pandas as pd
from sklearn.pipeline import Pipeline

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# Columns that must be dropped before inference (not seen during training)
# and that should NOT appear in the scored output either (privacy / leakage).
_INFERENCE_DROP_COLS = {"label"}

# Columns excluded from model features but kept in output for traceability
_OUTPUT_KEEP_COLS = {"user_id", "outfit_id", "context_id"}

# ---------------------------------------------------------------------------
# I/O helpers  (kept in sync with train_lightgbm_ranker.py)
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


def _normalize_multivalue_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Join list-valued columns into pipe-separated strings.

    IMPORTANT: uses sorted() to match the encoding used at training time.
    """
    out = df.copy()
    for col in ["styles", "preferred_styles"]:
        if col in out.columns:
            out[col] = out[col].apply(
                lambda v: "|".join(sorted(v))   # sorted → consistent with training
                if isinstance(v, list)
                else ("" if pd.isna(v) else str(v))
            )
    return out


def _cast_boolean_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Cast boolean-like columns to 0/1 integers (mirrors train preprocessing)."""
    BOOLEAN_CANDIDATES = ["strict_weather_mode", "is_weekend"]
    out = df.copy()
    for col in BOOLEAN_CANDIDATES:
        if col in out.columns:
            out[col] = out[col].map(
                {True: 1, False: 0, "true": 1, "false": 0,
                 "True": 1, "False": 0, 1: 1, 0: 0}
            )
    return out


# ---------------------------------------------------------------------------
# Model loading
# ---------------------------------------------------------------------------


def _load_artefact(model_path: Path) -> tuple[Pipeline, float]:
    """Load the joblib artefact and return (pipeline, threshold).

    Supports both the new dict format {"model": ..., "threshold": ...}
    and the legacy format where the pipeline was saved directly, in which
    case the threshold defaults to 0.5.
    """
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")

    artefact = joblib.load(model_path)

    if isinstance(artefact, dict):
        model: Pipeline = artefact["model"]
        threshold: float = float(artefact.get("threshold", 0.5))
        log.info(
            "Loaded model artefact (dict format) — threshold=%.4f", threshold
        )
    else:
        # Legacy: raw pipeline saved directly
        model = artefact
        threshold = 0.5
        log.warning(
            "Legacy model format detected (raw pipeline). "
            "Using default threshold=0.5. "
            "Retrain with the latest train_lightgbm_ranker.py for optimal thresholding."
        )

    return model, threshold


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------


def score(args: argparse.Namespace) -> pd.DataFrame:
    t0 = time.perf_counter()

    model, threshold = _load_artefact(Path(args.model))

    df_raw = _read_input(Path(args.input))

    if df_raw.empty:
        raise ValueError("Input file is empty — nothing to score.")

    # Allow caller to override the trained threshold
    if args.threshold is not None:
        threshold = args.threshold
        log.info("Threshold overridden by --threshold flag: %.4f", threshold)

    # --- Preprocessing (must mirror train_lightgbm_ranker.py exactly) ---
    df = _normalize_multivalue_columns(df_raw)
    df = _cast_boolean_columns(df)

    # Separate identity/output columns from feature columns
    output_meta = df[[c for c in _OUTPUT_KEEP_COLS if c in df.columns]].copy()

    # Drop columns not seen during training
    cols_to_drop = list(_INFERENCE_DROP_COLS & set(df.columns))
    if cols_to_drop:
        log.info("Dropping inference-only columns: %s", cols_to_drop)
        df = df.drop(columns=cols_to_drop)

    # --- Inference ---
    try:
        proba = model.predict_proba(df)[:, 1]
    except Exception as exc:
        raise RuntimeError(
            f"Model prediction failed. Check that the input features match "
            f"the training schema.\nOriginal error: {exc}"
        ) from exc

    # --- Assemble output ---
    out = output_meta.copy()
    out["ml_score"] = proba
    out["ml_label"] = (proba >= threshold).astype(int)

    # Ranking within groups
    group_cols = [c for c in ["user_id", "context_id"] if c in out.columns]

    if group_cols:
        sort_cols = group_cols + ["ml_score"]
        sort_asc = [True] * len(group_cols) + [False]
        out = out.sort_values(sort_cols, ascending=sort_asc).reset_index(drop=True)
        out["ml_rank"] = out.groupby(group_cols).cumcount() + 1
    else:
        out = out.sort_values("ml_score", ascending=False).reset_index(drop=True)
        out["ml_rank"] = list(range(1, len(out) + 1))

    elapsed = time.perf_counter() - t0
    log.info(
        "Scored %d candidates in %.3fs (%.0f rows/s)",
        len(out),
        elapsed,
        len(out) / elapsed if elapsed > 0 else float("inf"),
    )
    log.info(
        "Predicted positives: %d / %d (%.1f%%)",
        int(out["ml_label"].sum()),
        len(out),
        out["ml_label"].mean() * 100,
    )

    return out


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Score outfit candidates with a trained LightGBM model",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--model", required=True, help="Path to .joblib model artefact")
    parser.add_argument("--input", required=True, help="Path to CSV or JSONL candidates")
    parser.add_argument(
        "--output",
        default="ml/artifacts/scored_candidates.csv",
        help="Output CSV path",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=None,
        help=(
            "Override the decision threshold stored in the model artefact. "
            "Useful for precision/recall trade-off tuning at inference time."
        ),
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=None,
        help="If set, keep only the top-K candidates per group (or globally if no groups).",
    )
    parser.add_argument(
        "--output-format",
        choices=["csv", "jsonl"],
        default="csv",
        help="Output file format.",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()

    try:
        out = score(args)
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        log.error("%s", exc)
        sys.exit(1)

    # --- Optional top-K filter ---
    if args.top_k is not None:
        group_cols = [c for c in ["user_id", "context_id"] if c in out.columns]
        if group_cols:
            out = out[out["ml_rank"] <= args.top_k]
        else:
            out = out.head(args.top_k)
        log.info("Filtered to top-%d → %d rows remaining", args.top_k, len(out))

    # --- Save ---
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.output_format == "jsonl":
        output_path = output_path.with_suffix(".jsonl")
        with output_path.open("w", encoding="utf-8") as f:
            for record in out.to_dict(orient="records"):
                f.write(json.dumps(record, default=str) + "\n")
    else:
        out.to_csv(output_path, index=False)

    log.info("Saved %d rows → %s", len(out), output_path)

    # --- Console preview ---
    preview_cols = [c for c in ["user_id", "outfit_id", "ml_score", "ml_label", "ml_rank"] if c in out.columns]
    print(out[preview_cols].head(10).to_string(index=False))
    print(f"\n✓ {len(out)} rows saved to {output_path}")


if __name__ == "__main__":
    main()