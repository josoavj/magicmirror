#!/usr/bin/env python3
"""Generate outfit candidates per user from Supabase profiles.

Fix #4 : le catalog d'outfits est maintenant chargé depuis Supabase si
--outfits-table est fourni, avec fallback sur FALLBACK_OUTFIT_STYLES
(défini dans schema.py) pour la rétrocompatibilité.

This bridges the app catalog with the ML batch pipeline by creating one
candidate row per (user, outfit) pair.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

import pandas as pd
from supabase import create_client

# shared constants (fallback catalog + style normalization helpers)
_ML_DIR = Path(__file__).parent
if str(_ML_DIR) not in sys.path:
    sys.path.insert(0, str(_ML_DIR))

from schema import FALLBACK_OUTFIT_STYLES  # noqa: E402


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


def _load_outfit_catalog(
    client: Any, outfits_table: str | None
) -> dict[str, list[str]]:
    """Load the outfit catalog from Supabase or fall back to the hardcoded map.

    Fix #4 : si `outfits_table` est fourni, charge les outfits depuis Supabase
    (colonnes attendues : outfit_id, styles). Si la table est vide ou si la
    colonne 'styles' est absente, on retombe sur le catalog par défaut.

    Args:
        client: Supabase client instance.
        outfits_table: Name of the Supabase table, or None to use the fallback.

    Returns:
        dict mapping outfit_id -> list[str] of style tags.
    """
    if not outfits_table:
        return dict(FALLBACK_OUTFIT_STYLES)

    try:
        rows = (
            client.table(outfits_table)
            .select("outfit_id,styles")
            .execute()
            .data
            or []
        )
        if not rows:
            print(
                f"[WARNING] Table '{outfits_table}' returned 0 rows — using fallback catalog.",
                file=sys.stderr,
            )
            return dict(FALLBACK_OUTFIT_STYLES)

        catalog: dict[str, list[str]] = {}
        for row in rows:
            oid = row.get("outfit_id")
            if not oid:
                continue
            raw_styles = row.get("styles", [])
            if isinstance(raw_styles, str):
                try:
                    raw_styles = json.loads(raw_styles)
                except json.JSONDecodeError:
                    raw_styles = [s.strip() for s in raw_styles.split("|") if s.strip()]
            catalog[str(oid)] = list(raw_styles) if isinstance(raw_styles, list) else []

        print(f"Loaded {len(catalog)} outfits from '{outfits_table}'.")
        return catalog

    except Exception as exc:  # noqa: BLE001
        print(
            f"[WARNING] Could not load outfits from '{outfits_table}': {exc}. "
            "Using fallback catalog.",
            file=sys.stderr,
        )
        return dict(FALLBACK_OUTFIT_STYLES)


def generate_candidates(
    url: str,
    key: str,
    outfits_table: str | None = None,
) -> pd.DataFrame:
    client = create_client(url, key)

    rows = (
        client.table("profiles")
        .select("user_id,age,height_cm,morphology,preferred_styles,gender")
        .execute()
        .data
        or []
    )

    # Fix #4 : catalog chargé dynamiquement depuis Supabase si demandé
    outfit_catalog = _load_outfit_catalog(client, outfits_table)

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

        for outfit_id, styles in outfit_catalog.items():
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
    parser = argparse.ArgumentParser(
        description="Generate outfit candidates per user",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--url", required=True, help="Supabase URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument(
        "--output",
        default="data/outfit_candidates.jsonl",
        help="Output path (.jsonl or .csv)",
    )
    parser.add_argument(
        "--outfits-table",
        default=None,
        help=(
            "Supabase table name for outfit catalog "
            "(columns: outfit_id, styles). "
            "If omitted, uses the hardcoded fallback catalog from schema.py."
        ),
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    df = generate_candidates(args.url, args.key, outfits_table=args.outfits_table)

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
