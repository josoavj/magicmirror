# Outfit ML Pipeline (LightGBM)

Ce document couvre le **point 2**: pipeline ML leger pour remplacer/augmenter progressivement le scoring heuristique.

## Objectif

Entrainer un modele de classification binaire:
- `label = 1` tenue pertinente (like/choisie/portee)
- `label = 0` tenue non pertinente (dislike/non adaptee)

Puis scorer des candidates avec `ml_score` pour faire un ranking.

## Fichiers

- `ml/train_lightgbm_ranker.py`: entrainement + export modele
- `ml/score_lightgbm_ranker.py`: inference batch
- `ml/requirements.txt`: dependances Python

## Installation

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r ml/requirements.txt
```

## Format des donnees d'entrainement

Le script accepte `CSV` ou `JSONL`.

Champ obligatoire:
- `label` (0/1)

Features supportees (optionnelles mais recommandees):
- numeriques: `age`, `weather_temp`, `weather_humidity`, `weather_wind`, `seen_7d_count`, `feedback_style_bias`, `feedback_outfit_bias`
- categorielles: `user_id`, `outfit_id`, `morphology`, `planning_context`, `weather_main`, `hour_slot`, `strict_weather_mode`, `is_weekend`, `styles`, `preferred_styles`

Exemple JSONL:

```json
{"label":1,"user_id":"u1","outfit_id":"business_smart","age":29,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"business|elegant","preferred_styles":"business|minimaliste","seen_7d_count":0,"feedback_style_bias":8,"feedback_outfit_bias":10}
{"label":0,"user_id":"u1","outfit_id":"sport","age":29,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"sport","preferred_styles":"business|minimaliste","seen_7d_count":2,"feedback_style_bias":-4,"feedback_outfit_bias":-8}
```

## Entrainement

```bash
python ml/train_lightgbm_ranker.py \
  --input data/outfit_feedback_events.jsonl \
  --model-out ml/artifacts/outfit_ranker.joblib \
  --metrics-out ml/artifacts/metrics.json
```

Sorties:
- modele: `ml/artifacts/outfit_ranker.joblib`
- metriques: `ml/artifacts/metrics.json` (`accuracy`, `log_loss`, `auc`)

## Inference / scoring

```bash
python ml/score_lightgbm_ranker.py \
  --model ml/artifacts/outfit_ranker.joblib \
  --input data/outfit_candidates.jsonl \
  --output ml/artifacts/scored_candidates.csv
```

Sorties:
- `ml_score`: score de pertinence predit
- `ml_rank`: rang de recommendation

## Integration app (hybride)

Recommande au debut:

$$
score_{final} = 0.6 \cdot score_{heuristique} + 0.4 \cdot score_{ml}
$$

Puis ajuster selon KPI reel.

## KPI de suivi

- taux d'acceptation
- taux de rejet
- diversite top 4
- repetition a 7 jours

## Etat d'avancement

- Point 1 (instrumentation feedback + metriques): termine
- Point 2 (pipeline LightGBM/XGBoost): **scripts et doc en place, integration runtime a brancher**
