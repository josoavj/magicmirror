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
- `ml/export_feedback_dataset.py`: extraction dataset depuis Supabase
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

### 0) Exporter les evenements feedback depuis Supabase

```bash
python ml/export_feedback_dataset.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --output data/outfit_feedback_events.jsonl \
  --days 90
```

Puis utiliser ce fichier en entree d'entrainement:

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

Dans l'app Flutter:
- `AppConfig.enableHybridMlRanking` active le blend heuristique+ML.
- `AppConfig.hybridMlWeight` controle le poids du score ML.
- Le provider lit `public.outfit_ml_scores` (`user_id`, `outfit_id`, `score`).

Feedback cloud:
- `AppConfig.enableCloudFeedbackExport` exporte les interactions vers `public.outfit_feedback_events`.

## Cold-start (aucun feedback utilisateur)

Ce n'est **pas** un bug si aucun score utilisateur n'existe au debut.

Strategie recommandee:
- l'app garde le ranking heuristique (toujours disponible)
- des `priors` ML par tenue sont utilises tant que `outfit_ml_scores` est vide
- des que des scores cloud existent, ils ecrasent les priors pour ce user

Resultat: pas de "trou" de recommandation au premier lancement.

## Pipeline continu (liaison dossier ml -> app)

Nouveaux scripts:
- `ml/generate_outfit_candidates.py`: genere les candidats `(user_id, outfit_id)` depuis `profiles`
- `ml/publish_ml_scores.py`: publie les scores vers `public.outfit_ml_scores`
- `ml/run_ml_pipeline_once.py`: enchaine export -> train/score -> publication

Execution one-shot:

```bash
python ml/run_ml_pipeline_once.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --days 90 \
  --min-samples 200
```

Comportement si peu de donnees:
- si `samples >= min-samples`: train + score + publish
- sinon si un modele existe deja: score + publish avec ce modele
- sinon: publication de scores neutres `0.5` (cold-start backend)

Boucle continue (cron toutes les 30 min):

```bash
*/30 * * * * cd /path/to/magicmirror && /path/to/.venv/bin/python ml/run_ml_pipeline_once.py --url "$SUPABASE_URL" --key "$SUPABASE_SERVICE_ROLE_KEY" --days 90 --min-samples 200 >> /var/log/magicmirror-ml.log 2>&1
```

Version systemd timer possible aussi si tu preferes une supervision native Linux.

Option PaaS recommandee:
- Railway + Supabase (runbook complet): voir `docs/RAILWAY_ML_SETUP.md`

## KPI de suivi

- taux d'acceptation
- taux de rejet
- diversite top 4
- repetition a 7 jours

## Etat d'avancement

- Point 1 (instrumentation feedback + metriques): termine
- Point 2 (pipeline LightGBM/XGBoost): scripts batch + publication Supabase en place
