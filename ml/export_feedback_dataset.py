#!/usr/bin/env python3
"""Export Supabase feedback events into a trainable JSONL dataset.

Requires table `outfit_feedback_events` with at least:
- user_id (text/uuid)
- event_type (text)
- outfit_id (text)
- payload (jsonb, optional)
- created_at (timestamptz)

Example:
    python ml/export_feedback_dataset.py \
      --url "$SUPABASE_URL" \
      --key "$SUPABASE_SERVICE_ROLE_KEY" \
      --output data/outfit_feedback_events.jsonl
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from supabase import create_client


POSITIVE_EVENTS = {"like", "favorite_add", "worn"}
NEGATIVE_EVENTS = {
    "dislike",
    "favorite_remove",
    "not_adapted",
    "too_hot",
    "too_cold",
    "too_formal",
    "too_sporty",
}


def _parse_iso(ts: str | None) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError:
        return None


def _label_for_event(event_type: str) -> int | None:
    normalized = event_type.strip().lower()
    if normalized in POSITIVE_EVENTS:
        return 1
    if normalized in NEGATIVE_EVENTS:
        return 0
    return None


def _row_to_sample(row: dict[str, Any]) -> dict[str, Any] | None:
    event_type = str(row.get("event_type") or "").strip().lower()
    label = _label_for_event(event_type)
    if label is None:
        return None

    payload = row.get("payload") if isinstance(row.get("payload"), dict) else {}
    created_at = _parse_iso(str(row.get("created_at") or ""))

    styles = payload.get("styles")
    if isinstance(styles, list):
        styles = "|".join(str(s) for s in styles)
    elif styles is None:
        styles = str(payload.get("styles", ""))

    sample = {
        "label": label,
        "user_id": row.get("user_id"),
        "outfit_id": row.get("outfit_id"),
        "styles": styles,
        "preferred_styles": payload.get("preferred_styles", ""),
        "morphology": payload.get("morphology", ""),
        "planning_context": payload.get("planning_context", ""),
        "weather_temp": payload.get("weather_temp"),
        "weather_humidity": payload.get("weather_humidity"),
        "weather_wind": payload.get("weather_wind"),
        "weather_main": payload.get("weather_main", ""),
        "strict_weather_mode": payload.get("strict_weather_mode", False),
        "is_weekend": payload.get("is_weekend", False),
        "hour_slot": payload.get("hour_slot", ""),
        "age": payload.get("age"),
        "height_cm": payload.get("height_cm"),
        "seen_7d_count": payload.get("seen_7d_count", 0),
        "feedback_style_bias": payload.get("feedback_style_bias", 0),
        "feedback_outfit_bias": payload.get("feedback_outfit_bias", 0),
        "event_type": event_type,
        "event_time": created_at.isoformat() if created_at else row.get("created_at"),
    }

    # Drop None values to keep files compact.
    return {k: v for k, v in sample.items() if v is not None}


def _fetch_rows(url: str, key: str, days: int | None) -> list[dict[str, Any]]:
    client = create_client(url, key)

    page_size = 1000
    offset = 0
    rows: list[dict[str, Any]] = []

    since_iso = None
    if days is not None and days > 0:
        since = datetime.now(tz=timezone.utc)
        since = since.replace(microsecond=0) - timedelta(days=days)
        since_iso = since.isoformat()

    while True:
        query = client.table("outfit_feedback_events").select(
            "user_id,event_type,outfit_id,payload,created_at"
        )
        if since_iso is not None:
            query = query.gte("created_at", since_iso)
        response = query.range(offset, offset + page_size - 1).execute()
        batch = response.data or []
        if not batch:
            break
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size

    return rows


def export_dataset(args: argparse.Namespace) -> dict[str, int]:
    rows = _fetch_rows(args.url, args.key, args.days)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    total = 0
    kept = 0
    with output.open("w", encoding="utf-8") as f:
        for row in rows:
            total += 1
            sample = _row_to_sample(row)
            if sample is None:
                continue
            f.write(json.dumps(sample, ensure_ascii=False) + "\n")
            kept += 1

    return {"events_read": total, "samples_exported": kept}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export feedback events to JSONL dataset")
    parser.add_argument("--url", required=True, help="Supabase project URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument(
        "--output",
        default="data/outfit_feedback_events.jsonl",
        help="Output JSONL dataset path",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=None,
        help="Optional lookback window in days",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    stats = export_dataset(args)
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()
