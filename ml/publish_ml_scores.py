#!/usr/bin/env python3
"""Publish scored outfit rows to Supabase table public.outfit_ml_scores.

Expected input columns:
- user_id
- outfit_id
- ml_score
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from supabase import create_client


REQUIRED_COLS = {"user_id", "outfit_id", "ml_score"}


def _read(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Input not found: {path}")

    suffix = path.suffix.lower()
    if suffix == ".csv":
        return pd.read_csv(path)
    if suffix in {".jsonl", ".ndjson"}:
        rows = []
        with path.open("r", encoding="utf-8") as f:
            for line in f:
                raw = line.strip()
                if not raw:
                    continue
                rows.append(json.loads(raw))
        return pd.DataFrame(rows)

    raise ValueError(f"Unsupported input format: {suffix}")


def publish(url: str, key: str, input_path: Path, batch_size: int = 500) -> dict[str, int]:
    df = _read(input_path)
    missing = REQUIRED_COLS - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    df = df[list(REQUIRED_COLS)].copy()
    df["ml_score"] = pd.to_numeric(df["ml_score"], errors="coerce").fillna(0.5).clip(0, 1)
    df["updated_at"] = datetime.now(timezone.utc).isoformat()

    rows = df.to_dict(orient="records")
    client = create_client(url, key)

    published = 0
    for start in range(0, len(rows), batch_size):
        chunk = rows[start : start + batch_size]
        (
            client.table("outfit_ml_scores")
            .upsert(chunk, on_conflict="user_id,outfit_id")
            .execute()
        )
        published += len(chunk)

    return {"published": published}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish ML scores to Supabase")
    parser.add_argument("--url", required=True, help="Supabase URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument("--input", required=True, help="Scored CSV/JSONL file")
    parser.add_argument("--batch-size", type=int, default=500)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    stats = publish(
        url=args.url,
        key=args.key,
        input_path=Path(args.input),
        batch_size=args.batch_size,
    )
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()
