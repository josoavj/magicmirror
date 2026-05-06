"""Shared ML schema constants for MagicMirror outfit pipeline.

Import from this module in both train_lightgbm_ranker.py and
score_lightgbm_ranker.py to guarantee identical feature definitions at
training and inference time.
"""

from __future__ import annotations

# ---------------------------------------------------------------------------
# Feature columns
# ---------------------------------------------------------------------------

# NOTE: user_id and outfit_id are intentionally excluded — including raw IDs
# as features causes data leakage and prevents generalisation to unseen users
# or outfits. If you need entity embeddings, handle them separately.
NUMERIC_CANDIDATES: list[str] = [
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
BOOLEAN_CANDIDATES: list[str] = [
    "strict_weather_mode",
    "is_weekend",
]

CATEGORICAL_CANDIDATES: list[str] = [
    "morphology",
    "planning_context",
    "weather_main",
    "hour_slot",
    "styles",
    "preferred_styles",
]

# Columns excluded from model features but kept in output for traceability
OUTPUT_KEEP_COLS: frozenset[str] = frozenset({"user_id", "outfit_id", "context_id"})

# Columns that must be dropped before inference (not seen during training)
INFERENCE_DROP_COLS: frozenset[str] = frozenset({"label"})

# ---------------------------------------------------------------------------
# Feedback event labels
# ---------------------------------------------------------------------------

POSITIVE_EVENTS: frozenset[str] = frozenset({"like", "favorite_add", "worn"})

NEGATIVE_EVENTS: frozenset[str] = frozenset(
    {
        "dislike",
        "favorite_remove",
        "not_adapted",
        "too_hot",
        "too_cold",
        "too_formal",
        "too_sporty",
    }
)

# ---------------------------------------------------------------------------
# Default fallback outfit catalog (used when Supabase outfits table is
# unavailable or --outfits-table is not provided).
# ---------------------------------------------------------------------------

FALLBACK_OUTFIT_STYLES: dict[str, list[str]] = {
    "casual_moderne": ["casual", "minimaliste"],
    "elegant": ["elegant", "business"],
    "sport": ["sport"],
    "street_dynamics": ["streetwear", "casual"],
    "business_smart": ["business", "elegant"],
    "minimal_monochrome": ["minimaliste", "casual"],
}
