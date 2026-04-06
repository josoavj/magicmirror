# Railway ML Batch + Supabase

Ce guide deploie le pipeline ML batch sur Railway avec ecriture des scores dans Supabase.

## 1) Prerequis

- Repo GitHub connecte a Railway
- Tables Supabase deja creees:
  - `public.outfit_feedback_events`
  - `public.outfit_ml_scores`
  - `public.profiles`
- Cle service role Supabase (server-side uniquement)

## 2) Fichiers utilises

- `ml/Dockerfile`
- `railway.toml`
- `ml/run_ml_pipeline_once.py`

## 3) Variables Railway (service)

Ajoute ces variables dans le service Railway:

- `SUPABASE_URL` = URL du projet Supabase
- `SUPABASE_SERVICE_ROLE_KEY` = service role key Supabase
- `ML_LOOKBACK_DAYS` = `90` (optionnel)
- `ML_MIN_SAMPLES` = `200` (optionnel)

Important:
- Ne jamais exposer `SUPABASE_SERVICE_ROLE_KEY` cote client/mobile/web.
- Cette cle reste uniquement cote Railway.

## 4) Deploy

1. Cree un nouveau service Railway depuis ce repo.
2. Railway detecte `railway.toml` et build via `ml/Dockerfile`.
3. Verifie dans les logs que la commande lancee est:

```bash
python ml/run_ml_pipeline_once.py --url $SUPABASE_URL --key $SUPABASE_SERVICE_ROLE_KEY --days ... --min-samples ...
```

## 5) Planification (Cron)

Dans Railway:
- Active le Cron du service
- Exemple: toutes les 30 minutes

Expression cron conseillee:

```txt
*/30 * * * *
```

## 6) Verification Supabase

Apres execution, verifier dans SQL Editor:

```sql
select user_id, outfit_id, score, updated_at
from public.outfit_ml_scores
order by updated_at desc
limit 50;
```

Et verifier l'arrivee de feedback:

```sql
select user_id, event_type, created_at
from public.outfit_feedback_events
order by created_at desc
limit 50;
```

## 7) Comportement en cold-start

Le pipeline publie quand meme des scores (neutres) si:
- pas assez d'echantillons pour entrainer
- aucun modele existant

Cote app Flutter, un fallback de priors ML reste actif si la table est vide.

## 8) Incident checklist

- Logs Railway en erreur `Missing required columns`:
  - verifier le schema `profiles` et la generation des candidats
- Logs Railway `permission denied` sur Supabase:
  - verifier `SUPABASE_SERVICE_ROLE_KEY`
- Table `outfit_ml_scores` vide:
  - verifier cron actif
  - verifier que le service a bien termine sans erreur
