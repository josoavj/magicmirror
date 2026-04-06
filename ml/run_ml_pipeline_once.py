#!/usr/bin/env python3
"""Run end-to-end ML pipeline once and publish scores to Supabase.

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
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str]) -> None:
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def _line_count(path: Path) -> int:
    if not path.exists():
        return 0
    with path.open("r", encoding="utf-8") as f:
        return sum(1 for _ in f)


def _write_neutral_scores(candidates_path: Path, output_path: Path) -> int:
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
    parser = argparse.ArgumentParser(description="Run ML pipeline once")
    parser.add_argument("--url", required=True, help="Supabase URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument("--days", type=int, default=90)
    parser.add_argument("--min-samples", type=int, default=200)
    parser.add_argument("--feedback-out", default="data/outfit_feedback_events.jsonl")
    parser.add_argument("--candidates-out", default="data/outfit_candidates.jsonl")
    parser.add_argument("--model-out", default="ml/artifacts/outfit_ranker.joblib")
    parser.add_argument("--metrics-out", default="ml/artifacts/metrics.json")
    parser.add_argument("--scored-out", default="ml/artifacts/scored_candidates.csv")
    return parser


def main() -> None:
    args = build_parser().parse_args()

    py = sys.executable
    feedback_path = Path(args.feedback_out)
    candidates_path = Path(args.candidates_out)
    model_path = Path(args.model_out)
    scored_path = Path(args.scored_out)

    _run(
        [
            py,
            "ml/export_feedback_dataset.py",
            "--url",
            args.url,
            "--key",
            args.key,
            "--output",
            str(feedback_path),
            "--days",
            str(args.days),
        ]
    )

    _run(
        [
            py,
            "ml/generate_outfit_candidates.py",
            "--url",
            args.url,
            "--key",
            args.key,
            "--output",
            str(candidates_path),
        ]
    )

    samples = _line_count(feedback_path)
    print(json.dumps({"feedback_samples": samples}, indent=2))

    if samples >= args.min_samples:
        _run(
            [
                py,
                "ml/train_lightgbm_ranker.py",
                "--input",
                str(feedback_path),
                "--model-out",
                str(model_path),
                "--metrics-out",
                str(args.metrics_out),
            ]
        )
        _run(
            [
                py,
                "ml/score_lightgbm_ranker.py",
                "--model",
                str(model_path),
                "--input",
                str(candidates_path),
                "--output",
                str(scored_path),
                "--output-format",
                "csv",
            ]
        )
    elif model_path.exists():
        print("Using existing trained model (insufficient new samples).")
        _run(
            [
                py,
                "ml/score_lightgbm_ranker.py",
                "--model",
                str(model_path),
                "--input",
                str(candidates_path),
                "--output",
                str(scored_path),
                "--output-format",
                "csv",
            ]
        )
    else:
        print("No model yet and insufficient samples: publishing neutral cold-start scores.")
        rows = _write_neutral_scores(candidates_path, scored_path)
        print(json.dumps({"neutral_scored_rows": rows}, indent=2))

    _run(
        [
            py,
            "ml/publish_ml_scores.py",
            "--url",
            args.url,
            "--key",
            args.key,
            "--input",
            str(scored_path),
        ]
    )

    print("Pipeline completed.")


if __name__ == "__main__":
    main()
