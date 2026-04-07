#!/usr/bin/env python3
"""Generate outfit candidates per user from Supabase profiles.

This bridges the app catalog with the ML batch pipeline by creating one
candidate row per (user, outfit) pair.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path
from typing import Any

import pandas as pd
from supabase import create_client

_OUTFIT_STYLES: dict[str, list[str]] = {
    "casual_moderne": ["casual", "minimaliste"],
    "elegant": ["elegant", "business"],
    "sport": ["sport"],
    "street_dynamics": ["streetwear", "casual"],
    "business_smart": ["business", "elegant"],
    "minimal_monochrome": ["minimaliste", "casual"],
}


def _normalize_styles(value: Any) -> str:
    if isinstance(value, list):
        return "|".join(sorted(str(v) for v in value if str(v).strip()))
    if isinstance(value, str):
        raw = value.strip()
        if not raw:
            return ""
        if raw.startswith("["):
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, list):
                    return "|".join(sorted(str(v) for v in parsed if str(v).strip()))
            except json.JSONDecodeError:
                pass
        return raw
    return ""


def _default_context() -> dict[str, Any]:
    now = datetime.now()
    hour = now.hour
    if hour < 12:
        slot = "morning"
    elif hour < 18:
        slot = "afternoon"
    else:
        slot = "evening"

    return {
        "planning_context": "none",
        "weather_temp": 24.0,
        "weather_humidity": 65,
        "weather_wind": 4.0,
        "weather_main": "Clear",
        "strict_weather_mode": True,
        "is_weekend": now.weekday() >= 5,
        "hour_slot": slot,
        "seen_7d_count": 0,
        "feedback_style_bias": 0,
        "feedback_outfit_bias": 0,
        "context_id": "daily_default",
    }


def generate_candidates(url: str, key: str) -> pd.DataFrame:
    client = create_client(url, key)
    rows = (
        client.table("profiles")
        .select("user_id,age,height_cm,morphology,preferred_styles,gender")
        .execute()
        .data
        or []
    )

    payload = []
    common = _default_context()

    for row in rows:
        user_id = row.get("user_id")
        if not user_id:
            continue

        preferred_styles = _normalize_styles(row.get("preferred_styles"))
        age = row.get("age")
        if not isinstance(age, int):
            try:
                age = int(str(age))
            except Exception:
                age = 25

        height_cm = row.get("height_cm")
        if not isinstance(height_cm, int):
            try:
                height_cm = int(str(height_cm))
            except Exception:
                height_cm = 170

        morphology = str(row.get("morphology") or "Silhouette non definie")

        for outfit_id, styles in _OUTFIT_STYLES.items():
            payload.append(
                {
                    "user_id": str(user_id),
                    "outfit_id": outfit_id,
                    "styles": "|".join(sorted(styles)),
                    "preferred_styles": preferred_styles,
                    "morphology": morphology,
                    "age": age,
                    "height_cm": height_cm,
                    **common,
                }
            )

    return pd.DataFrame(payload)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate outfit candidates per user")
    parser.add_argument("--url", required=True, help="Supabase URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument(
        "--output",
        default="data/outfit_candidates.jsonl",
        help="Output path (.jsonl or .csv)",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    df = generate_candidates(args.url, args.key)

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    if out.suffix.lower() == ".csv":
        df.to_csv(out, index=False)
    else:
        with out.open("w", encoding="utf-8") as f:
            for record in df.to_dict(orient="records"):
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

    print(json.dumps({"candidates": int(len(df)), "output": str(out)}, indent=2))


if __name__ == "__main__":
    main()
