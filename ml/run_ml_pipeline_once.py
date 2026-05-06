#!/usr/bin/env python3
"""Run end-to-end ML pipeline once and publish scores to Supabase.

Fix #5 : remplace l'orchestration par subprocess (fragile, reconnexion Supabase
répétée, pas de partage de contexte) par des appels directs aux fonctions
internes de chaque module — plus testable, plus rapide, erreurs propagées
correctement entre les étapes.

Flow:
  1) export feedback dataset
  2) generate candidates
  3) train model if enough samples (or reuse existing model)
  4) score candidates
  5) publish scores to public.outfit_ml_scores
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Ensure the ml/ directory is importable when invoked from the project root.
_ML_DIR = Path(__file__).parent
if str(_ML_DIR) not in sys.path:
    sys.path.insert(0, str(_ML_DIR))

from export_feedback_dataset import export_dataset          # noqa: E402
from generate_outfit_candidates import generate_candidates  # noqa: E402
from publish_ml_scores import publish                       # noqa: E402
from score_lightgbm_ranker import score                    # noqa: E402
from train_lightgbm_ranker import train                    # noqa: E402


def _line_count(path: Path) -> int:
    if not path.exists():
        return 0
    with path.open("r", encoding="utf-8") as f:
        return sum(1 for _ in f)


def _write_neutral_scores(candidates_path: Path, output_path: Path) -> int:
    """Publish neutral scores (0.5) when no trained model is available yet."""
    import pandas as pd

    if candidates_path.suffix.lower() in {".jsonl", ".ndjson"}:
        rows = []
        with candidates_path.open("r", encoding="utf-8") as f:
            for line in f:
                raw = line.strip()
                if raw:
                    rows.append(json.loads(raw))
        df = pd.DataFrame(rows)
    else:
        df = pd.read_csv(candidates_path)

    for col in ["user_id", "outfit_id"]:
        if col not in df.columns:
            raise ValueError(f"Missing required candidate column: {col}")

    scored = df[["user_id", "outfit_id"]].copy()
    scored["ml_score"] = 0.5
    scored["ml_label"] = 1
    scored["ml_rank"] = scored.groupby("user_id").cumcount() + 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    scored.to_csv(output_path, index=False)
    return int(len(scored))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run ML pipeline once",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--url", required=True, help="Supabase URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument("--days", type=int, default=90)
    parser.add_argument("--min-samples", type=int, default=200)
    parser.add_argument("--feedback-out", default="data/outfit_feedback_events.jsonl")
    parser.add_argument("--candidates-out", default="data/outfit_candidates.jsonl")
    parser.add_argument("--model-out", default="ml/artifacts/outfit_ranker.joblib")
    parser.add_argument("--metrics-out", default="ml/artifacts/metrics.json")
    parser.add_argument("--scored-out", default="ml/artifacts/scored_candidates.csv")
    parser.add_argument(
        "--outfits-table",
        default=None,
        help="Supabase table name for outfit catalog (optional; uses fallback if omitted)",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()

    feedback_path = Path(args.feedback_out)
    candidates_path = Path(args.candidates_out)
    model_path = Path(args.model_out)
    scored_path = Path(args.scored_out)

    # ------------------------------------------------------------------
    # Step 1 — Export feedback dataset
    # ------------------------------------------------------------------
    print("\n▶ Step 1/5 — Exporting feedback dataset …")
    export_args = argparse.Namespace(
        url=args.url,
        key=args.key,
        output=str(feedback_path),
        days=args.days,
    )
    try:
        stats = export_dataset(export_args)
        print(json.dumps({"step": "export", **stats}, indent=2))
    except Exception as exc:
        print(f"[ERROR] Step 1 failed: {exc}", file=sys.stderr)
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 2 — Generate candidates
    # ------------------------------------------------------------------
    print("\n▶ Step 2/5 — Generating outfit candidates …")
    try:
        import pandas as pd
        df_candidates = generate_candidates(
            args.url,
            args.key,
            outfits_table=getattr(args, "outfits_table", None),
        )
        candidates_path.parent.mkdir(parents=True, exist_ok=True)
        with candidates_path.open("w", encoding="utf-8") as f:
            for record in df_candidates.to_dict(orient="records"):
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
        print(json.dumps({"step": "candidates", "rows": len(df_candidates)}, indent=2))
    except Exception as exc:
        print(f"[ERROR] Step 2 failed: {exc}", file=sys.stderr)
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 3 — Train (or reuse) model
    # ------------------------------------------------------------------
    samples = _line_count(feedback_path)
    print(f"\n▶ Step 3/5 — Training check ({samples} feedback samples) …")
    print(json.dumps({"feedback_samples": samples}, indent=2))

    if samples >= args.min_samples:
        print("  Sufficient data — training new model.")
        train_args = argparse.Namespace(
            input=str(feedback_path),
            model_out=str(model_path),
            metrics_out=str(args.metrics_out),
            min_samples=args.min_samples,
            valid_size=0.2,
            seed=42,
            n_estimators=300,
            learning_rate=0.05,
            num_leaves=31,
            early_stopping_rounds=30,
            cv_folds=0,
        )
        try:
            metrics = train(train_args)
            print(json.dumps({"step": "train", "auc_roc": metrics.get("auc_roc")}, indent=2))
        except Exception as exc:
            print(f"[ERROR] Step 3 (train) failed: {exc}", file=sys.stderr)
            sys.exit(1)
    elif model_path.exists():
        print("  Insufficient new samples — reusing existing trained model.")
    else:
        print("  No model and insufficient samples — publishing neutral cold-start scores.")
        rows = _write_neutral_scores(candidates_path, scored_path)
        print(json.dumps({"step": "cold_start", "neutral_rows": rows}, indent=2))

        # Skip scoring step, go straight to publish
        print("\n▶ Step 5/5 — Publishing cold-start scores …")
        try:
            publish_stats = publish(args.url, args.key, scored_path)
            print(json.dumps({"step": "publish", **publish_stats}, indent=2))
        except Exception as exc:
            print(f"[ERROR] Step 5 failed: {exc}", file=sys.stderr)
            sys.exit(1)
        print("\n✓ Pipeline completed (cold-start mode).")
        return

    # ------------------------------------------------------------------
    # Step 4 — Score candidates
    # ------------------------------------------------------------------
    print("\n▶ Step 4/5 — Scoring candidates …")
    score_args = argparse.Namespace(
        model=str(model_path),
        input=str(candidates_path),
        output=str(scored_path),
        threshold=None,
        top_k=None,
        output_format="csv",
    )
    try:
        df_scored = score(score_args)
        df_scored.to_csv(scored_path, index=False)
        print(json.dumps({"step": "score", "rows": len(df_scored)}, indent=2))
    except Exception as exc:
        print(f"[ERROR] Step 4 failed: {exc}", file=sys.stderr)
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 5 — Publish to Supabase
    # ------------------------------------------------------------------
    print("\n▶ Step 5/5 — Publishing ML scores …")
    try:
        publish_stats = publish(args.url, args.key, scored_path)
        print(json.dumps({"step": "publish", **publish_stats}, indent=2))
    except Exception as exc:
        print(f"[ERROR] Step 5 failed: {exc}", file=sys.stderr)
        sys.exit(1)

    print("\n✓ Pipeline completed successfully.")


if __name__ == "__main__":
    main()
