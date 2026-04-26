# Configuration Supabase — MagicMirror

Ce document couvre la configuration complète et opérationnelle de Supabase pour MagicMirror : authentification, profil cloud, agenda, stockage des avatars, favoris et scoring ML/LLM.

> **Important :** Le script SQL fourni en section 2 est idempotent — il peut être exécuté plusieurs fois sans risque d'erreur ni de doublon.

---

## Sommaire

1. [Variables d'environnement](#1-variables-denvironnement)
2. [Script SQL complet](#2-script-sql-complet)
3. [Schéma des tables](#3-schéma-des-tables)
4. [Ce que Flutter fait avec ce schéma](#4-ce-que-flutter-fait-avec-ce-schéma)
5. [Fonctions upsert pour le modèle LLM](#5-fonctions-upsert-pour-le-modèle-llm)
6. [Vérification de bon fonctionnement](#6-vérification-de-bon-fonctionnement)
7. [Requêtes de debug](#7-requêtes-de-debug)
8. [Dépannage](#8-dépannage)
9. [Bonnes pratiques](#9-bonnes-pratiques)

---

## 1. Variables d'environnement

Créer ou compléter le fichier `assets/.env` à la racine du projet :

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
OPENWEATHERMAP_API_KEY=YOUR_OPENWEATHERMAP_API_KEY
```

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `SUPABASE_URL` | ✅ | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | ✅ | Clé publique anonyme (utilisée côté Flutter) |
| `OPENWEATHERMAP_API_KEY` | ✅ pour la météo | Clé API pour les données météo en temps réel |

> **Sécurité :** Ne jamais utiliser la `service_role` key dans le client Flutter. Elle est réservée aux jobs backend (scoring ML/LLM) qui doivent contourner le RLS.

---

## 2. Script SQL complet

Copier-coller l'intégralité du script suivant dans le **SQL Editor** de votre projet Supabase (`https://supabase.com/dashboard/project/YOUR_PROJECT_REF/sql`).

Le script est encapsulé dans une transaction (`begin` / `commit`) : en cas d'erreur, aucune modification n'est appliquée.

```sql
-- MagicMirror — Supabase full setup (idempotent)
-- Peut être exécuté plusieurs fois sans erreur.

begin;

-- Extension pour gen_random_uuid()
create extension if not exists pgcrypto;

-- --------------------------------------------------
-- TABLE : profiles
-- --------------------------------------------------
create table if not exists public.profiles (
  user_id           uuid        primary key references auth.users(id) on delete cascade,
  display_name      text        not null default 'Utilisateur',
  avatar_url        text        not null default '',
  gender            text        not null default 'Non precise',
  birth_date        date,
  age               int         not null default 25,
  height_cm         int         not null default 170,
  morphology        text        not null default 'Silhouette non definie',
  preferred_styles  text[]      not null default array['Casual']::text[],
  favorite_outfit_ids text[]    not null default '{}',
  updated_at        timestamptz not null default now()
);

-- Migrations défensives pour les projets existants
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists height_cm int;
alter table public.profiles add column if not exists favorite_outfit_ids text[] not null default '{}';
alter table public.profiles alter column morphology set default 'Silhouette non definie';

-- Backfill + contrainte sur height_cm
update public.profiles set height_cm = 170 where height_cm is null;
alter table public.profiles alter column height_cm set default 170;
alter table public.profiles alter column height_cm set not null;

alter table public.profiles drop constraint if exists profiles_height_cm_check;
alter table public.profiles add constraint profiles_height_cm_check
  check (height_cm between 120 and 230);

-- Index GIN pour les recherches sur le tableau de favoris
create index if not exists profiles_favorite_outfit_ids_gin
  on public.profiles using gin (favorite_outfit_ids);

-- Row Level Security
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_select_own" on public.profiles
  for select to authenticated using (user_id = auth.uid());

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check (user_id = auth.uid());

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- --------------------------------------------------
-- TABLE : agenda_events
-- --------------------------------------------------
create table if not exists public.agenda_events (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references auth.users(id) on delete cascade,
  title        text        not null,
  description  text,
  start_time   timestamptz not null,
  end_time     timestamptz not null,
  location     text,
  event_type   text        not null default 'Other',
  is_completed boolean     not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_agenda_events_user_start
  on public.agenda_events(user_id, start_time);

alter table public.agenda_events enable row level security;

drop policy if exists "agenda_select_own" on public.agenda_events;
drop policy if exists "agenda_insert_own" on public.agenda_events;
drop policy if exists "agenda_update_own" on public.agenda_events;
drop policy if exists "agenda_delete_own" on public.agenda_events;

create policy "agenda_select_own" on public.agenda_events
  for select to authenticated using (user_id = auth.uid());

create policy "agenda_insert_own" on public.agenda_events
  for insert to authenticated with check (user_id = auth.uid());

create policy "agenda_update_own" on public.agenda_events
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "agenda_delete_own" on public.agenda_events
  for delete to authenticated using (user_id = auth.uid());

-- --------------------------------------------------
-- TABLE : outfit_feedback_events
-- --------------------------------------------------
create table if not exists public.outfit_feedback_events (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        not null references auth.users(id) on delete cascade,
  event_type text        not null,
  outfit_id  text,
  payload    jsonb       not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_outfit_feedback_events_user_created
  on public.outfit_feedback_events(user_id, created_at desc);

alter table public.outfit_feedback_events enable row level security;

drop policy if exists "outfit_feedback_select_own" on public.outfit_feedback_events;
drop policy if exists "outfit_feedback_insert_own" on public.outfit_feedback_events;

create policy "outfit_feedback_select_own" on public.outfit_feedback_events
  for select to authenticated using (user_id = auth.uid());

create policy "outfit_feedback_insert_own" on public.outfit_feedback_events
  for insert to authenticated with check (user_id = auth.uid());

-- --------------------------------------------------
-- Trigger helper : mise à jour automatique de updated_at
-- --------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- --------------------------------------------------
-- TABLE : outfit_ml_scores (optionnel)
-- Scores calculés par le modèle ML local
-- --------------------------------------------------
create table if not exists public.outfit_ml_scores (
  id         uuid              primary key default gen_random_uuid(),
  user_id    uuid              not null references auth.users(id) on delete cascade,
  outfit_id  text              not null,
  score      double precision  not null check (score >= 0 and score <= 1),
  updated_at timestamptz       not null default now(),
  unique (user_id, outfit_id)
);

create index if not exists idx_outfit_ml_scores_user
  on public.outfit_ml_scores(user_id);

create index if not exists idx_outfit_ml_scores_updated_at
  on public.outfit_ml_scores(updated_at desc);

drop trigger if exists trg_outfit_ml_scores_updated_at on public.outfit_ml_scores;
create trigger trg_outfit_ml_scores_updated_at
  before update on public.outfit_ml_scores
  for each row execute function public.set_updated_at();

alter table public.outfit_ml_scores enable row level security;

drop policy if exists "outfit_ml_scores_select_own" on public.outfit_ml_scores;

create policy "outfit_ml_scores_select_own" on public.outfit_ml_scores
  for select to authenticated using (user_id = auth.uid());

-- --------------------------------------------------
-- TABLE : outfit_llm_scores (optionnel)
-- Scores calculés par le modèle LLM secondaire (Llama)
-- --------------------------------------------------
create table if not exists public.outfit_llm_scores (
  id                 uuid              primary key default gen_random_uuid(),
  user_id            uuid              not null references auth.users(id) on delete cascade,
  outfit_id          text              not null,
  score              double precision  not null check (score >= 0 and score <= 1),
  model_tag          text              not null default 'secondary',
  target_gender      text,
  target_styles      text[],
  target_morphology  text,
  profile_payload    jsonb             not null default '{}'::jsonb,
  updated_at         timestamptz       not null default now(),
  unique (user_id, outfit_id, model_tag)
);

create index if not exists idx_outfit_llm_scores_user_model
  on public.outfit_llm_scores(user_id, model_tag);

create index if not exists idx_outfit_llm_scores_updated_at
  on public.outfit_llm_scores(updated_at desc);

drop trigger if exists trg_outfit_llm_scores_updated_at on public.outfit_llm_scores;
create trigger trg_outfit_llm_scores_updated_at
  before update on public.outfit_llm_scores
  for each row execute function public.set_updated_at();

alter table public.outfit_llm_scores enable row level security;

drop policy if exists "outfit_llm_scores_select_own" on public.outfit_llm_scores;

create policy "outfit_llm_scores_select_own" on public.outfit_llm_scores
  for select to authenticated using (user_id = auth.uid());

-- --------------------------------------------------
-- TABLE : outfit_llm_details (optionnel)
-- Détails de composition générés par le LLM
-- --------------------------------------------------
create table if not exists public.outfit_llm_details (
  id                 uuid        primary key default gen_random_uuid(),
  user_id            uuid        not null references auth.users(id) on delete cascade,
  outfit_id          text        not null,
  model_tag          text        not null default 'secondary',
  type_label         text,
  summary            text,
  top_item           text,
  bottom_item        text,
  shoes_item         text,
  outerwear_item     text,
  accessories        text[]      not null default '{}'::text[],
  target_gender      text,
  target_styles      text[],
  target_morphology  text,
  profile_payload    jsonb       not null default '{}'::jsonb,
  updated_at         timestamptz not null default now(),
  unique (user_id, outfit_id, model_tag)
);

create index if not exists idx_outfit_llm_details_user_model
  on public.outfit_llm_details(user_id, model_tag);

create index if not exists idx_outfit_llm_details_updated_at
  on public.outfit_llm_details(updated_at desc);

drop trigger if exists trg_outfit_llm_details_updated_at on public.outfit_llm_details;
create trigger trg_outfit_llm_details_updated_at
  before update on public.outfit_llm_details
  for each row execute function public.set_updated_at();

alter table public.outfit_llm_details enable row level security;

drop policy if exists "outfit_llm_details_select_own" on public.outfit_llm_details;

create policy "outfit_llm_details_select_own" on public.outfit_llm_details
  for select to authenticated using (user_id = auth.uid());

-- --------------------------------------------------
-- FONCTIONS upsert pour les jobs LLM (service role)
-- --------------------------------------------------
create or replace function public.upsert_outfit_llm_scores(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  _count integer := 0;
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception 'p_rows must be a JSON array';
  end if;

  with parsed as (
    select
      r.user_id,
      r.outfit_id,
      r.score,
      coalesce(nullif(r.model_tag, ''), 'secondary') as model_tag,
      r.target_gender,
      r.target_styles,
      r.target_morphology,
      coalesce(r.profile_payload, '{}'::jsonb) as profile_payload
    from jsonb_to_recordset(p_rows) as r(
      user_id uuid, outfit_id text, score double precision,
      model_tag text, target_gender text, target_styles text[],
      target_morphology text, profile_payload jsonb
    )
    where r.user_id is not null
      and r.outfit_id is not null and r.outfit_id <> ''
      and r.score is not null and r.score between 0 and 1
  ), upserted as (
    insert into public.outfit_llm_scores (
      user_id, outfit_id, score, model_tag,
      target_gender, target_styles, target_morphology, profile_payload
    )
    select user_id, outfit_id, score, model_tag,
           target_gender, target_styles, target_morphology, profile_payload
    from parsed
    on conflict (user_id, outfit_id, model_tag)
    do update set
      score             = excluded.score,
      target_gender     = excluded.target_gender,
      target_styles     = excluded.target_styles,
      target_morphology = excluded.target_morphology,
      profile_payload   = excluded.profile_payload,
      updated_at        = now()
    returning 1
  )
  select count(*) into _count from upserted;
  return _count;
end;
$$;

create or replace function public.upsert_outfit_llm_details(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  _count integer := 0;
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception 'p_rows must be a JSON array';
  end if;

  with parsed as (
    select
      r.user_id,
      r.outfit_id,
      coalesce(nullif(r.model_tag, ''), 'secondary') as model_tag,
      r.type_label, r.summary, r.top_item, r.bottom_item,
      r.shoes_item, r.outerwear_item,
      coalesce(r.accessories, '{}'::text[]) as accessories,
      r.target_gender, r.target_styles, r.target_morphology,
      coalesce(r.profile_payload, '{}'::jsonb) as profile_payload
    from jsonb_to_recordset(p_rows) as r(
      user_id uuid, outfit_id text, model_tag text,
      type_label text, summary text, top_item text, bottom_item text,
      shoes_item text, outerwear_item text, accessories text[],
      target_gender text, target_styles text[],
      target_morphology text, profile_payload jsonb
    )
    where r.user_id is not null
      and r.outfit_id is not null and r.outfit_id <> ''
  ), upserted as (
    insert into public.outfit_llm_details (
      user_id, outfit_id, model_tag, type_label, summary,
      top_item, bottom_item, shoes_item, outerwear_item, accessories,
      target_gender, target_styles, target_morphology, profile_payload
    )
    select user_id, outfit_id, model_tag, type_label, summary,
           top_item, bottom_item, shoes_item, outerwear_item, accessories,
           target_gender, target_styles, target_morphology, profile_payload
    from parsed
    on conflict (user_id, outfit_id, model_tag)
    do update set
      type_label        = excluded.type_label,
      summary           = excluded.summary,
      top_item          = excluded.top_item,
      bottom_item       = excluded.bottom_item,
      shoes_item        = excluded.shoes_item,
      outerwear_item    = excluded.outerwear_item,
      accessories       = excluded.accessories,
      target_gender     = excluded.target_gender,
      target_styles     = excluded.target_styles,
      target_morphology = excluded.target_morphology,
      profile_payload   = excluded.profile_payload,
      updated_at        = now()
    returning 1
  )
  select count(*) into _count from upserted;
  return _count;
end;
$$;

-- Les fonctions upsert sont réservées au service role (jobs backend)
revoke all on function public.upsert_outfit_llm_scores(jsonb) from public;
revoke all on function public.upsert_outfit_llm_details(jsonb) from public;
grant execute on function public.upsert_outfit_llm_scores(jsonb) to service_role;
grant execute on function public.upsert_outfit_llm_details(jsonb) to service_role;

-- --------------------------------------------------
-- STORAGE : bucket avatars
-- --------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatar_read_public"  on storage.objects;
drop policy if exists "avatar_insert_own"   on storage.objects;
drop policy if exists "avatar_update_own"   on storage.objects;

-- Lecture publique (les avatars sont affichés sans authentification)
create policy "avatar_read_public" on storage.objects
  for select to public
  using (bucket_id = 'avatars');

-- Upload uniquement dans son propre dossier (format : {user_id}/filename)
create policy "avatar_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  );

create policy "avatar_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  );

commit;
```

---

## 3. Schéma des tables

### Vue d'ensemble

| Table | Rôle | Optionnelle |
|-------|------|-------------|
| `profiles` | Profil utilisateur (morphologie, favoris, styles) | Non |
| `agenda_events` | Événements agenda cloud | Non |
| `outfit_feedback_events` | Instrumentation locale des interactions tenues | Non |
| `outfit_ml_scores` | Scores calculés par le modèle ML local | Oui |
| `outfit_llm_scores` | Scores calculés par le modèle LLM secondaire (Llama) | Oui |
| `outfit_llm_details` | Détails de composition générés par le LLM | Oui |

### Sécurité — Row Level Security (RLS)

Le RLS est activé sur toutes les tables. Chaque utilisateur authentifié n'accède qu'à ses propres données, via la condition `user_id = auth.uid()`. Les politiques appliquées sont :

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | ✅ | ✅ | ✅ | — |
| `agenda_events` | ✅ | ✅ | ✅ | ✅ |
| `outfit_feedback_events` | ✅ | ✅ | — | — |
| `outfit_ml_scores` | ✅ | — | — | — |
| `outfit_llm_scores` | ✅ | — | — | — |
| `outfit_llm_details` | ✅ | — | — | — |

Les tables de scores (ML et LLM) sont en lecture seule côté client Flutter. Les insertions et mises à jour sont effectuées par les jobs backend via la `service_role` key, qui contourne le RLS.

### Trigger `set_updated_at`

Un trigger `BEFORE UPDATE` est appliqué sur les tables `outfit_ml_scores`, `outfit_llm_scores` et `outfit_llm_details`. Il met automatiquement à jour le champ `updated_at` à chaque modification, sans que le client ait besoin de le gérer.

### Stockage avatars

Le bucket `avatars` est public en lecture. Chaque utilisateur ne peut écrire que dans un sous-dossier portant son propre `user_id` (format `{user_id}/filename`), ce qui est vérifié par la politique RLS via `split_part(name, '/', 1) = auth.uid()::text`.

---

## 4. Ce que Flutter fait avec ce schéma

| Fonctionnalité | Table / Service | Détails |
|----------------|-----------------|---------|
| Authentification | Supabase Auth | Email + mot de passe |
| Profil cloud | `profiles` | Upsert/select sur `user_id = auth.uid()` |
| Agenda cloud | `agenda_events` | CRUD complet, scopé au compte actif |
| Upload avatar | `storage.objects` (bucket `avatars`) | Dossier par `user_id` |
| Favoris tenues | `profiles.favorite_outfit_ids` | Array PostgreSQL + fallback local SharedPreferences |
| Feedback tenues | `outfit_feedback_events` | Instrumentation locale exportée vers le cloud |
| Scores ML | `outfit_ml_scores` | Lecture seule côté Flutter, pour le ranking hybride |
| Scores LLM | `outfit_llm_scores` + `outfit_llm_details` | Lecture seule côté Flutter, profil/genre/styles/morphologie |

---

## 5. Fonctions upsert pour le modèle LLM

Les fonctions `upsert_outfit_llm_scores` et `upsert_outfit_llm_details` sont exécutées par les jobs backend (service role). Elles acceptent un tableau JSON et effectuent un `INSERT ... ON CONFLICT ... DO UPDATE` atomique.

### Exemple — upsert de scores

```sql
select public.upsert_outfit_llm_scores(
  '[
    {
      "user_id":          "00000000-0000-0000-0000-000000000000",
      "outfit_id":        "elegant",
      "score":            0.84,
      "model_tag":        "secondary",
      "target_gender":    "female",
      "target_styles":    ["elegant", "business"],
      "target_morphology":"Hanches et epaules equilibrees",
      "profile_payload":  {"gender":"Femme","morphology":"Sablier (X)","preferredStyles":["elegant","business"]}
    }
  ]'::jsonb
);
```

### Exemple — upsert de détails

```sql
select public.upsert_outfit_llm_details(
  '[
    {
      "user_id":          "00000000-0000-0000-0000-000000000000",
      "outfit_id":        "elegant",
      "model_tag":        "secondary",
      "type_label":       "Smart élégant",
      "summary":          "Chemise structurée + chino fuselé",
      "top_item":         "Chemise structurée",
      "bottom_item":      "Pantalon chino fuselé",
      "shoes_item":       "Derbies en cuir",
      "outerwear_item":   "Blazer léger",
      "accessories":      ["Ceinture cuir"],
      "target_gender":    "female",
      "target_styles":    ["elegant", "business"],
      "target_morphology":"Hanches et epaules equilibrees",
      "profile_payload":  {"gender":"Femme","morphology":"Sablier (X)","preferredStyles":["elegant","business"]}
    }
  ]'::jsonb
);
```

Les deux fonctions retournent le nombre de lignes insérées ou mises à jour. Les lignes invalides (score hors de `[0, 1]`, `outfit_id` vide, `user_id` null) sont silencieusement ignorées.

---

## 6. Vérification de bon fonctionnement

Effectuer ces vérifications dans l'ordre après le premier déploiement :

1. Se connecter avec un **compte A**
2. Modifier le profil (nom, morphologie, styles) → relancer l'app → vérifier la persistance
3. Ajouter un événement agenda → relancer l'app → vérifier la récupération
4. Ajouter une tenue en favori → déconnecter et reconnecter le compte A → vérifier que les favoris sont restaurés
5. Se connecter avec un **compte B** → vérifier que profil, agenda et favoris sont distincts de ceux du compte A

---

## 7. Requêtes de debug

### Voir les profils récents

```sql
select user_id, display_name, favorite_outfit_ids, updated_at
from public.profiles
order by updated_at desc
limit 20;
```

### Voir l'agenda d'un utilisateur

Remplacer `YOUR_USER_UUID` par l'UUID de l'utilisateur :

```sql
select user_id, title, start_time, end_time, event_type, is_completed
from public.agenda_events
where user_id = 'YOUR_USER_UUID'
order by start_time asc;
```

### Vérifier l'existence d'une colonne

```sql
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name   = 'profiles'
  and column_name  = 'favorite_outfit_ids';
```

---

## 8. Dépannage

### Erreur `42703` — colonne inexistante

**Cause :** Une colonne référencée par le client Flutter n'existe pas encore en base. Cela survient si la table a été créée avant l'ajout de certaines colonnes.

**Solution — migration minimale pour les favoris :**

```sql
alter table public.profiles
  add column if not exists favorite_outfit_ids text[] not null default '{}';
```

Vérifier ensuite avec la requête de la section [Requêtes de debug](#7-requêtes-de-debug), puis relancer l'app et se reconnecter pour déclencher la synchronisation cloud.

### RLS bloquant les lectures

**Cause :** Une politique RLS manquante ou mal configurée empêche l'utilisateur d'accéder à ses données.

**Vérification :**

```sql
select * from pg_policies
where tablename = 'profiles';
```

S'assurer que les politiques `profiles_select_own`, `profiles_insert_own` et `profiles_update_own` sont présentes.

### Les scores ML/LLM ne se mettent pas à jour

**Cause :** Les fonctions upsert sont réservées au `service_role`. Si le job backend utilise la clé `anon`, l'exécution sera refusée.

**Vérification :** Confirmer que la variable d'environnement côté backend est bien `SUPABASE_SERVICE_ROLE_KEY` et non `SUPABASE_ANON_KEY`.

---

## 9. Bonnes pratiques

| Règle | Raison |
|-------|--------|
| Garder le RLS actif sur toutes les tables | Garantit l'isolation des données entre utilisateurs |
| Ne jamais utiliser la `service_role` key dans Flutter | Elle contourne le RLS et expose toutes les données |
| Versionner les évolutions SQL | Permet de rejouer les migrations proprement sur un nouveau projet |
| Toujours utiliser `add column if not exists` | Rend les migrations idempotentes et sans risque |
| Encapsuler les migrations dans une transaction | En cas d'erreur partielle, aucune modification n'est appliquée |