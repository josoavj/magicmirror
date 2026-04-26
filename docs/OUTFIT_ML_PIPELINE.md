# Pipeline ML — Ranking de tenues (LightGBM)

Ce document décrit le pipeline de Machine Learning utilisé pour scorer et classer les tenues dans MagicMirror. Il s'appuie sur LightGBM (compatible XGBoost) et remplace progressivement le scoring heuristique pour des recommandations plus personnalisées et adaptatives.

**Public visé :** développeurs, data scientists, ops, contributeurs.

---

## Sommaire

1. [Objectif](#1-objectif)
2. [Scripts du pipeline](#2-scripts-du-pipeline)
3. [Installation](#3-installation)
4. [Initialisation Supabase](#4-initialisation-supabase)
5. [Format des données d'entraînement](#5-format-des-données-dentraînement)
6. [Entraînement du modèle](#6-entraînement-du-modèle)
7. [Inférence et scoring batch](#7-inférence-et-scoring-batch)
8. [Intégration Flutter — ranking hybride](#8-intégration-flutter--ranking-hybride)
9. [Gestion du cold-start](#9-gestion-du-cold-start)
10. [Pipeline continu et automatisation](#10-pipeline-continu-et-automatisation)
11. [Suivi et monitoring](#11-suivi-et-monitoring)
12. [Bonnes pratiques](#12-bonnes-pratiques)
13. [Dépannage](#13-dépannage)
14. [Références](#14-références)

---

## 1. Objectif

Le modèle effectue une **classification binaire** sur les tenues candidates :

| Label | Signification | Exemples d'événements |
|-------|---------------|----------------------|
| `1` | Tenue pertinente | like, favorite_add, worn |
| `0` | Tenue non pertinente | dislike, not_adapted, too_hot, too_cold |

Le modèle prédit un `ml_score` (probabilité de pertinence) pour chaque tenue candidate, utilisé pour construire un **ranking personnalisé**.

### Pourquoi LightGBM ?

- Entraînement rapide, même sur de petits jeux de données
- Gestion native des features mixtes (numériques et catégorielles)
- Export simple via `joblib`, facile à intégrer côté backend ou app

---

## 2. Scripts du pipeline

| Script | Rôle |
|--------|------|
| `ml/train_lightgbm_ranker.py` | Entraînement et export du modèle (`joblib`) |
| `ml/score_lightgbm_ranker.py` | Inférence batch sur les candidats |
| `ml/export_feedback_dataset.py` | Extraction du dataset depuis Supabase |
| `ml/generate_outfit_candidates.py` | Génération des couples `(user, tenue)` |
| `ml/publish_ml_scores.py` | Publication des scores dans Supabase |
| `ml/run_ml_pipeline_once.py` | Pipeline complet : export → train/score → publish |
| `ml/requirements.txt` | Dépendances Python |

---

## 3. Installation

**Prérequis :**

- Python 3.10 ou supérieur
- Accès Supabase (URL + service role key)

```bash
# Créer et activer l'environnement virtuel
python -m venv .venv
source .venv/bin/activate        # macOS / Linux
# .venv\Scripts\activate         # Windows

# Installer les dépendances
pip install -r ml/requirements.txt

# Vérifier l'installation
python -c "import lightgbm, pandas, supabase; print('OK')"
```

**Dépendances principales :**

| Package | Rôle |
|---------|------|
| `lightgbm` | Modèle de gradient boosting |
| `pandas` | Manipulation des données |
| `scikit-learn` | Métriques, prétraitement, cross-validation |
| `joblib` | Sérialisation du modèle |
| `numpy` | Calcul numérique |
| `supabase` | Client Python pour Supabase |

---

## 4. Initialisation Supabase

Avant d'exécuter le pipeline, le schéma Supabase doit être en place. Exécuter le script SQL :

```
docs/sql/supabase_full_setup.sql
```

Ce script crée les tables suivantes (idempotent, sans risque de doublon) :

| Table | Rôle |
|-------|------|
| `public.outfit_feedback_events` | Stockage des feedbacks utilisateurs |
| `public.outfit_ml_scores` | Scores ML publiés par le pipeline |
| `public.profiles` | Profils utilisateurs (morphologie, styles, etc.) |

Il configure également les politiques RLS, les index et les contraintes nécessaires.

### Taxonomie des feedbacks (`event_type`)

Les feedbacks sont classés en deux catégories, qui servent de signal d'entraînement :

| Catégorie | Valeurs acceptées |
|-----------|-------------------|
| Positifs (`label = 1`) | `like`, `favorite_add`, `worn` |
| Négatifs (`label = 0`) | `dislike`, `not_adapted`, `too_hot`, `too_cold`, `too_formal`, `too_sporty`, `favorite_remove` |

---

## 5. Format des données d'entraînement

Le pipeline accepte deux formats en entrée : **CSV** ou **JSONL** (une ligne JSON par exemple).

### Champ obligatoire

- `label` : `1` (pertinent) ou `0` (non pertinent)

### Features supportées

| Catégorie | Colonnes |
|-----------|----------|
| Numériques | `age`, `height_cm`, `weather_temp`, `weather_humidity`, `weather_wind`, `seen_7d_count`, `feedback_style_bias`, `feedback_outfit_bias` |
| Catégorielles | `morphology`, `planning_context`, `weather_main`, `hour_slot`, `strict_weather_mode`, `is_weekend`, `styles`, `preferred_styles` |
| Identifiants (non utilisés comme features) | `user_id`, `outfit_id` |

> **Note :** `user_id` et `outfit_id` sont présents pour le suivi et la publication, mais **exclus des features** pour éviter le data leakage.

### Exemple JSONL

```jsonl
{"label":1,"user_id":"u1","outfit_id":"business_smart","age":29,"height_cm":172,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"business|elegant","preferred_styles":"business|minimaliste","seen_7d_count":0,"feedback_style_bias":8,"feedback_outfit_bias":10}
{"label":0,"user_id":"u1","outfit_id":"sport","age":29,"height_cm":172,"morphology":"Sablier (X)","planning_context":"work","weather_temp":24.5,"weather_humidity":68,"weather_wind":4.2,"weather_main":"Clear","strict_weather_mode":true,"is_weekend":false,"styles":"sport","preferred_styles":"business|minimaliste","seen_7d_count":2,"feedback_style_bias":-4,"feedback_outfit_bias":-8}
```

### Conventions d'encodage

- Les colonnes booléennes (`strict_weather_mode`, `is_weekend`) sont automatiquement converties en `0`/`1`
- Les listes (`styles`, `preferred_styles`) sont encodées en chaînes séparées par `|` (ex : `"business|elegant"`)

---

## 6. Entraînement du modèle

Le processus d'entraînement se déroule en deux étapes : export des feedbacks, puis entraînement.

### Étape 1 — Exporter les feedbacks depuis Supabase

```bash
python ml/export_feedback_dataset.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --output data/outfit_feedback_events.jsonl \
  --days 90
```

Ce script extrait les `outfit_feedback_events` des 90 derniers jours et les formate en JSONL prêt pour l'entraînement. Ajuster `--days` selon le volume de données disponible.

### Étape 2 — Entraîner le modèle LightGBM

```bash
python ml/train_lightgbm_ranker.py \
  --input data/outfit_feedback_events.jsonl \
  --model-out ml/artifacts/outfit_ranker.joblib \
  --metrics-out ml/artifacts/metrics.json
```

**Fichiers produits :**

| Fichier | Contenu |
|---------|---------|
| `ml/artifacts/outfit_ranker.joblib` | Modèle sérialisé, prêt pour l'inférence |
| `ml/artifacts/metrics.json` | Métriques d'évaluation : `accuracy`, `log_loss`, `auc`, etc. |

**Hyperparamètres ajustables :**

| Paramètre | Description |
|-----------|-------------|
| `--n-estimators` | Nombre d'arbres |
| `--learning-rate` | Taux d'apprentissage |
| `--num-leaves` | Nombre de feuilles par arbre |
| `--early-stopping-rounds` | Arrêt anticipé si pas d'amélioration |
| `--cv-folds` | Nombre de folds pour la cross-validation |
| `--seed` | Graine aléatoire pour la reproductibilité |

**Recommandations avant d'entraîner :**

- Vérifier la distribution des labels : un dataset trop déséquilibré (ex : 95% de `0`) dégrade les performances
- Utiliser la cross-validation (`--cv-folds`) pour évaluer la robustesse sur des données non vues
- Consulter les logs : ils affichent les features retenues, le temps d'entraînement et les scores par fold

---

## 7. Inférence et scoring batch

### Étape 1 — Générer les candidats

```bash
python ml/generate_outfit_candidates.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --output data/outfit_candidates.jsonl
```

Ce script génère tous les couples `(user_id, outfit_id)` à scorer pour chaque utilisateur actif.

### Étape 2 — Scorer les candidats

```bash
python ml/score_lightgbm_ranker.py \
  --model ml/artifacts/outfit_ranker.joblib \
  --input data/outfit_candidates.jsonl \
  --output ml/artifacts/scored_candidates.csv
```

**Colonnes produites dans le CSV de sortie :**

| Colonne | Description |
|---------|-------------|
| `ml_score` | Score de pertinence prédit (probabilité entre 0 et 1) |
| `ml_label` | Prédiction binaire selon le seuil optimal (`0` ou `1`) |
| `ml_rank` | Rang de recommandation (`1` = meilleur score) |

### Étape 3 — Publier les scores dans Supabase

```bash
python ml/publish_ml_scores.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --input ml/artifacts/scored_candidates.csv
```

Les scores sont écrits dans `public.outfit_ml_scores` via un upsert (insert ou mise à jour si le couple `(user_id, outfit_id)` existe déjà).

---

## 8. Intégration Flutter — ranking hybride

Le score final affiché dans l'app combine le score heuristique (règles métier) et le score ML :

$$score_{final} = (1 - w) \times score_{heuristique} + w \times score_{ML}$$

où `w` est contrôlé par `AppConfig.hybridMlWeight` (valeur conseillée : `0.4` en début de déploiement).

### Configuration dans `AppConfig`

| Paramètre | Rôle |
|-----------|------|
| `enableHybridMlRanking` | Active le blend heuristique + ML |
| `hybridMlWeight` | Poids du score ML dans le score final (`0.0` à `1.0`) |
| `enableCloudFeedbackExport` | Exporte les interactions vers `outfit_feedback_events` |

### Lecture des scores

Le provider Flutter lit la table `public.outfit_ml_scores` (colonnes `user_id`, `outfit_id`, `score`) via la clé `anon` avec le RLS actif. Chaque utilisateur ne voit que ses propres scores.

---

## 9. Gestion du cold-start

Le cold-start survient lorsqu'un utilisateur ne dispose d'aucun feedback enregistré et qu'aucun score ML n'a encore été calculé pour lui.

### Comportement par palier

| Situation | Comportement |
|-----------|--------------|
| Aucun feedback, aucun score ML | Ranking heuristique seul + scores neutres (0.5) publiés par le backend |
| Feedbacks collectés, modèle disponible | Pipeline publie des scores personnalisés qui écrasent les neutres |
| Feedbacks insuffisants (< `min-samples`) | Scoring avec le modèle existant si disponible, sinon scores neutres |

Ce mécanisme garantit qu'aucun utilisateur ne se retrouve sans recommandation au premier lancement. L'expérience est fluide dès le départ, puis s'améliore à mesure que les feedbacks sont collectés.

---

## 10. Pipeline continu et automatisation

### Exécution manuelle (one-shot)

```bash
python ml/run_ml_pipeline_once.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --days 90 \
  --min-samples 200
```

Ce script enchaîne automatiquement : export des feedbacks → entraînement (si assez de données) → scoring → publication.

### Logique de décision selon le volume de données

```
données >= min-samples  →  train + score + publish
données < min-samples et modèle existant  →  score + publish (modèle existant)
données < min-samples et aucun modèle  →  publish scores neutres (0.5)
```

### Automatisation par cron (toutes les 30 minutes)

```bash
*/30 * * * * cd /path/to/magicmirror && \
  /path/to/.venv/bin/python ml/run_ml_pipeline_once.py \
  --url "$SUPABASE_URL" \
  --key "$SUPABASE_SERVICE_ROLE_KEY" \
  --days 90 \
  --min-samples 200 \
  >> /var/log/magicmirror-ml.log 2>&1
```

### Déploiement PaaS

Le déploiement recommandé est **Railway + Supabase**. Voir `docs/RAILWAY_ML_SETUP.md` pour le runbook complet (variables d'environnement, Dockerfile, scheduling).

---

## 11. Suivi et monitoring

### KPI à surveiller

| Indicateur | Description | Signal d'alerte |
|------------|-------------|-----------------|
| Taux d'acceptation | Part des feedbacks positifs | < 40% → modèle sous-optimal |
| Taux de rejet | Part des feedbacks négatifs | > 50% → features ou data à revoir |
| Diversité du top 4 | Nombre de styles distincts dans les 4 premières tenues | < 2 → ranking trop monotone |
| Répétition à 7 jours | Taux de répétition des mêmes tenues sur 7 jours | > 60% → diversification nécessaire |
| AUC / log_loss | Métriques dans `ml/artifacts/metrics.json` | Comparer entre runs |

### Consulter les logs

```bash
# Logs locaux
tail -f /var/log/magicmirror-ml.log

# Logs Railway
railway logs --tail
```

---

## 12. Bonnes pratiques

| Règle | Raison |
|-------|--------|
| Ne jamais exposer la `service_role` key côté Flutter | Elle contourne le RLS et donne accès à toutes les données |
| Fixer le seed (`--seed`) à chaque run | Reproductibilité des résultats entre exécutions |
| Versionner les artefacts (`outfit_ranker.joblib`) | Permet de revenir à une version précédente en cas de régression |
| Surveiller la distribution des labels avant entraînement | Un dataset déséquilibré produit un modèle biaisé |
| Utiliser la cross-validation systématiquement | Détecte l'overfitting avant la mise en production |
| Mettre à jour ce document à chaque modification des scripts | Évite la dette documentaire |

---

## 13. Dépannage

### "Missing required columns"

**Cause :** Le schéma des candidats générés ne correspond pas aux colonnes attendues par le modèle.

**Solution :**

1. Vérifier que le schéma Supabase est à jour (re-exécuter `supabase_full_setup.sql`)
2. Vérifier la sortie de `generate_outfit_candidates.py` : toutes les colonnes listées en section 5 doivent être présentes
3. S'assurer que les colonnes booléennes ne contiennent pas de valeurs `null`

### "Permission denied"

**Cause :** La clé Supabase utilisée est la clé `anon` au lieu de la `service_role` key, ou la clé est incorrecte.

**Solution :**

1. Vérifier que `SUPABASE_SERVICE_ROLE_KEY` est bien définie dans les variables d'environnement
2. Ne pas confondre avec `SUPABASE_ANON_KEY` : les scripts ML requièrent obligatoirement la `service_role` key pour bypasser le RLS

### Table `outfit_ml_scores` vide après exécution

**Cause :** Le pipeline ne s'est pas exécuté, ou s'est terminé avec une erreur silencieuse.

**Solution :**

1. Vérifier les logs du cron ou de Railway
2. Exécuter manuellement `run_ml_pipeline_once.py` et observer la sortie console
3. Vérifier que `--min-samples` n'est pas trop élevé par rapport au volume de feedbacks disponibles

### Problème de cold-start persistant côté app

**Cause :** Le fallback heuristique n'est pas activé, ou les scores neutres n'ont pas été publiés.

**Solution :**

1. Vérifier que `AppConfig.enableHybridMlRanking` est `true`
2. Vérifier que `publish_ml_scores.py` a bien été exécuté et que des lignes sont présentes dans `outfit_ml_scores`
3. En cas de doute, exécuter le pipeline manuellement pour forcer la publication des scores neutres

---

## 14. Références

| Ressource | Lien |
|-----------|------|
| LightGBM | [lightgbm.readthedocs.io](https://lightgbm.readthedocs.io/) |
| Supabase | [supabase.com/docs](https://supabase.com/docs) |
| Railway | [docs.railway.app](https://docs.railway.app/) |
| Flutter | [docs.flutter.dev](https://docs.flutter.dev/) |
| Runbook Railway + ML | `docs/RAILWAY_ML_SETUP.md` |

---

*Pour toute question ou suggestion : @josoavj ou contributeurs MagicMirror.*