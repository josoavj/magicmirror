
# Pipeline ML pour le Ranking de Tenues (LightGBM)

Ce document décrit le pipeline de Machine Learning utilisé pour scorer et classer les tenues dans MagicMirror, en s’appuyant sur LightGBM (et compatible XGBoost). Il remplace ou complète progressivement le scoring heuristique, pour des recommandations plus personnalisées et adaptatives.

**Public visé** : développeurs, data scientists, ops, contributeurs.

**Points clés** :
- Pipeline batch, automatisable (cron, Railway, etc.)
- Intégration cloud (Supabase) et app Flutter (hybride ML/heuristique)
- Sécurité et reproductibilité

## Objectif

Entraîner un modèle de **classification binaire** :

- `label = 1` : tenue pertinente (like, choisie, portée)
- `label = 0` : tenue non pertinente (dislike, non adaptée)

Le modèle prédit un score de pertinence (`ml_score`) pour chaque tenue candidate, permettant un **ranking personnalisé**.

**Pourquoi LightGBM ?**
- Rapide, efficace sur petits jeux de données
- Gère bien les features mixtes (numériques, catégorielles)
- Facile à exporter et intégrer côté backend/app

## Scripts principaux

- `ml/train_lightgbm_ranker.py` : entraînement + export du modèle (joblib)
- `ml/score_lightgbm_ranker.py` : inférence batch sur des candidats
- `ml/export_feedback_dataset.py` : extraction du dataset depuis Supabase
- `ml/generate_outfit_candidates.py` : génération des couples (user, tenue)
- `ml/publish_ml_scores.py` : publication des scores dans Supabase
- `ml/run_ml_pipeline_once.py` : pipeline complet (export → train/score → publish)
- `ml/requirements.txt` : dépendances Python

## Installation & Pré-requis

**Prérequis** :
- Python 3.10+ recommandé
- Accès à Supabase (URL + service role key)

**Installation rapide** :
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r ml/requirements.txt
# Vérifier l’installation
python -c "import lightgbm, pandas, supabase"
```

**Dépendances principales** :
- lightgbm, pandas, scikit-learn, joblib, numpy, supabase

## Initialisation Supabase (obligatoire)

Avant tout, exécute le script SQL :
- `docs/sql/supabase_full_setup.sql`

Cela crée :
- Table `public.outfit_feedback_events` (feedback)
- Table `public.outfit_ml_scores` (scores ML)
- Table `public.profiles` (profils utilisateurs)
- Politiques RLS, index, contraintes, etc.

**Taxonomie feedback recommandée (`event_type`)** :
- **positifs** : `like`, `favorite_add`, `worn`
- **négatifs** : `dislike`, `not_adapted`, `too_hot`, `too_cold`, `too_formal`, `too_sporty`, `favorite_remove`

## Format des données d’entraînement

Le script accepte : **CSV** ou **JSONL**

**Champ obligatoire** :
- `label` (0/1)

**Features supportées (optionnelles mais recommandées)** :
- **Numériques** : `age`, `height_cm`, `weather_temp`, `weather_humidity`, `weather_wind`, `seen_7d_count`, `feedback_style_bias`, `feedback_outfit_bias`
- **Catégorielles** : `morphology`, `planning_context`, `weather_main`, `hour_slot`, `strict_weather_mode`, `is_weekend`, `styles`, `preferred_styles`
- **Identifiants** : `user_id`, `outfit_id` (utilisés pour le suivi, pas comme features)

**Exemple JSONL** :
```json
{"label":1,"user_id":"u1","outfit_id":"business_smart","age":29,"height_cm":172,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"business|elegant","preferred_styles":"business|minimaliste","seen_7d_count":0,"feedback_style_bias":8,"feedback_outfit_bias":10}
{"label":0,"user_id":"u1","outfit_id":"sport","age":29,"height_cm":172,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"sport","preferred_styles":"business|minimaliste","seen_7d_count":2,"feedback_style_bias":-4,"feedback_outfit_bias":-8}
```

**Conseils** :
- Les colonnes booléennes sont converties en 0/1 automatiquement.
- Les listes (`styles`, `preferred_styles`) sont encodées en chaînes séparées par `|`.
- Les IDs (`user_id`, `outfit_id`) ne sont **pas** utilisés comme features pour éviter le data leakage.

## Entraînement du modèle

### 1) Exporter les feedbacks depuis Supabase
```bash
python ml/export_feedback_dataset.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --output data/outfit_feedback_events.jsonl \
  --days 90
```

### 2) Entraîner le modèle LightGBM
```bash
python ml/train_lightgbm_ranker.py \
  --input data/outfit_feedback_events.jsonl \
  --model-out ml/artifacts/outfit_ranker.joblib \
  --metrics-out ml/artifacts/metrics.json
```

**Sorties** :
- Modèle : `ml/artifacts/outfit_ranker.joblib`
- Métriques : `ml/artifacts/metrics.json` (`accuracy`, `log_loss`, `auc`, etc.)

**Hyperparamètres ajustables** :
- `--n-estimators`, `--learning-rate`, `--num-leaves`, `--early-stopping-rounds`, `--cv-folds`, etc.

**Conseils** :
- Vérifier la distribution des labels (éviter les datasets trop déséquilibrés)
- Utiliser la cross-validation pour évaluer la robustesse
- Les logs affichent les features utilisées, le temps d’entraînement, et les scores

## Inférence / Scoring batch

### 1) Générer les candidats (user, tenue)
```bash
python ml/generate_outfit_candidates.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --output data/outfit_candidates.jsonl
```

### 2) Scorer les candidats
```bash
python ml/score_lightgbm_ranker.py \
  --model ml/artifacts/outfit_ranker.joblib \
  --input data/outfit_candidates.jsonl \
  --output ml/artifacts/scored_candidates.csv
```

**Sorties** :
- `ml_score` : score de pertinence prédit (proba)
- `ml_label` : prédiction binaire (selon le threshold optimal)
- `ml_rank` : rang de recommandation (1 = meilleur)

## Intégration app Flutter (ranking hybride)

**Principe** : le score final combine heuristique et ML :
$$
score_{final} = (1-w) \cdot score_{heuristique} + w \cdot score_{ml}
$$
avec $w$ contrôlé par `AppConfig.hybridMlWeight` (ex : 0.4 au début).

**Activation côté app** :
- `AppConfig.enableHybridMlRanking` : active le blend heuristique+ML
- `AppConfig.hybridMlWeight` : poids du score ML
- Le provider lit `public.outfit_ml_scores` (`user_id`, `outfit_id`, `score`)

**Feedback cloud** :
- `AppConfig.enableCloudFeedbackExport` : exporte les interactions vers `public.outfit_feedback_events`

## Cold-start (aucun feedback utilisateur)

**Comportement attendu** :
- Si aucun score ML n’existe pour un utilisateur, l’app utilise :
  - le ranking heuristique (toujours disponible)
  - des scores “priors” ML par tenue (backend : score neutre 0.5)
- Dès que des feedbacks sont collectés, le pipeline ML publie des scores personnalisés qui écrasent les priors.

**Résultat** : pas de “trou” de recommandation au premier lancement, expérience fluide dès le début.

## Pipeline continu (batch automatisé)

**Scripts clés** :
- `ml/run_ml_pipeline_once.py` : exécute tout le pipeline (export → train/score → publish)
- Peut être appelé en cron, Railway, ou manuellement

**Exécution one-shot** :
```bash
python ml/run_ml_pipeline_once.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --days 90 \
  --min-samples 200
```

**Comportement si peu de données** :
- Si `samples >= min-samples` : train + score + publish
- Sinon, si un modèle existe déjà : score + publish avec ce modèle
- Sinon : publication de scores neutres (0.5, cold-start backend)

**Automatisation (cron toutes les 30 min)** :
```bash
*/30 * * * * cd /path/to/magicmirror && /path/to/.venv/bin/python ml/run_ml_pipeline_once.py --url "$SUPABASE_URL" --key "$SUPABASE_SERVICE_ROLE_KEY" --days 90 --min-samples 200 >> /var/log/magicmirror-ml.log 2>&1
```

**Déploiement PaaS recommandé** :
- Railway + Supabase (voir `docs/RAILWAY_ML_SETUP.md` pour le runbook complet)

## Suivi & Monitoring (KPI)

**Indicateurs à suivre** :
- Taux d’acceptation (feedbacks positifs)
- Taux de rejet (feedbacks négatifs)
- Diversité du top 4 (nombre de styles différents)
- Répétition à 7 jours (éviter la monotonie)

## Bonnes pratiques & conseils

- **Sécurité** : ne jamais exposer la clé service role côté client/app
- **Reproductibilité** : fixer le seed (`--seed`), versionner les artefacts
- **Qualité data** : surveiller les valeurs manquantes, la distribution des labels, la cohérence des features
- **Logs** : toujours vérifier les logs en cas d’erreur (voir logs Railway, ou console locale)
- **Tuning** : ajuster les hyperparamètres selon les métriques, utiliser la cross-validation
- **Documentation** : garder ce document à jour, commenter les scripts si modifiés

## FAQ & Troubleshooting

- **Erreur “Missing required columns”** : vérifier le schéma Supabase et la génération des candidats
- **Erreur “permission denied”** : vérifier la clé Supabase et les droits
- **Table `outfit_ml_scores` vide** : vérifier que le cron ou le service Railway tourne bien, et qu’il n’y a pas d’erreur dans les logs
- **Problème de cold-start** : vérifier que le fallback heuristique fonctionne côté app, et que le backend publie bien des scores neutres

## Liens utiles

- [LightGBM documentation](https://lightgbm.readthedocs.io/)
- [Supabase documentation](https://supabase.com/docs)
- [Railway documentation](https://docs.railway.app/)
- [Flutter documentation](https://docs.flutter.dev/)

---

**Contact** : @josoavj ou contributeurs MagicMirror pour toute question ou suggestion d’amélioration.
