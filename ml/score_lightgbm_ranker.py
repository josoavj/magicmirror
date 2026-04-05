#!/usr/bin/env python3
"""Score outfit candidates with a trained LightGBM model.

Example:
    python ml/score_lightgbm_ranker.py \
      --model ml/artifacts/outfit_ranker.joblib \
      --input data/outfit_candidates.jsonl \
      --output ml/artifacts/scored_candidates.csv
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import joblib
import pandas as pd


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


def _normalize_multivalue_columns(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    for col in ["styles", "preferred_styles"]:
        if col in out.columns:
            out[col] = out[col].apply(
                lambda v: "|".join(v) if isinstance(v, list) else ("" if pd.isna(v) else str(v))
            )
    return out


def score(args: argparse.Namespace) -> pd.DataFrame:
    model = joblib.load(args.model)
    df = _normalize_multivalue_columns(_read_input(Path(args.input)))

    if "label" in df.columns:
        df = df.drop(columns=["label"])

    proba = model.predict_proba(df)[:, 1]
    out = df.copy()
    out["ml_score"] = proba

    group_cols = [c for c in ["user_id", "context_id"] if c in out.columns]
    if group_cols:
        out = out.sort_values(group_cols + ["ml_score"], ascending=[True] * len(group_cols) + [False])
    else:
        out = out.sort_values("ml_score", ascending=False)

    out["ml_rank"] = (
        out.groupby(group_cols).cumcount() + 1 if group_cols else range(1, len(out) + 1)
    )
    return out


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Score outfit candidates with trained model")
    parser.add_argument("--model", required=True, help="Path to .joblib model")
    parser.add_argument("--input", required=True, help="Path to CSV or JSONL candidates")
    parser.add_argument(
        "--output",
        default="ml/artifacts/scored_candidates.csv",
        help="Output CSV path",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    out = score(args)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(output_path, index=False)

    preview = out.head(10)
    print(preview.to_string(index=False))
    print(f"\nSaved {len(out)} rows to {output_path}")


if __name__ == "__main__":
    main()
