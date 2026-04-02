# Supabase Setup Complet (MagicMirror)

Ce document est un setup unique, complet et operable pour:
- auth utilisateur,
- profil cloud,
- agenda cloud,
- avatars storage,
- favoris tenues cloud,
- verification rapide de bon fonctionnement.

## 1) Variables d'environnement

Dans `assets/.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
OPENWEATHERMAP_API_KEY=YOUR_OPENWEATHERMAP_API_KEY
```

Notes:
- `SUPABASE_URL` et `SUPABASE_ANON_KEY` sont obligatoires.
- `OPENWEATHERMAP_API_KEY` est requis pour la météo réelle.

## 2) SQL unique a executer (copier/coller dans SQL Editor)

```sql
-- Extension utile pour gen_random_uuid()
create extension if not exists pgcrypto;

-- =========================
-- TABLE PROFILES
-- =========================
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Utilisateur',
  avatar_url text not null default '',
  gender text not null default 'Non precise',
  birth_date date,
  age int not null default 25,
  morphology text not null default 'Silhouette non definie',
  preferred_styles text[] not null default array['Casual']::text[],
  favorite_outfit_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- Migration défensive si la table existait déjà
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists favorite_outfit_ids text[] not null default '{}';
alter table public.profiles alter column morphology set default 'Silhouette non definie';

create index if not exists profiles_favorite_outfit_ids_gin
on public.profiles using gin (favorite_outfit_ids);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (user_id = auth.uid());

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (user_id = auth.uid());

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- =========================
-- TABLE AGENDA EVENTS
-- =========================
create table if not exists public.agenda_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  location text,
  event_type text not null default 'Other',
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.agenda_events enable row level security;

drop policy if exists "agenda_select_own" on public.agenda_events;
drop policy if exists "agenda_insert_own" on public.agenda_events;
drop policy if exists "agenda_update_own" on public.agenda_events;
drop policy if exists "agenda_delete_own" on public.agenda_events;

create policy "agenda_select_own"
on public.agenda_events
for select
to authenticated
using (user_id = auth.uid());

create policy "agenda_insert_own"
on public.agenda_events
for insert
to authenticated
with check (user_id = auth.uid());

create policy "agenda_update_own"
on public.agenda_events
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "agenda_delete_own"
on public.agenda_events
for delete
to authenticated
using (user_id = auth.uid());

create index if not exists idx_agenda_events_user_start
  on public.agenda_events(user_id, start_time);

-- =========================
-- STORAGE AVATARS
-- =========================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatar_read_public" on storage.objects;
drop policy if exists "avatar_insert_own" on storage.objects;
drop policy if exists "avatar_update_own" on storage.objects;

create policy "avatar_read_public"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

create policy "avatar_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

create policy "avatar_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);
```

## 3) Ce que Flutter fait avec ce schema

1. Auth email/password via Supabase Auth.
2. Profil cloud dans `public.profiles` (upsert/select sur `user_id = auth.uid()`).
3. Agenda cloud dans `public.agenda_events` (CRUD scope compte actif).
4. Upload avatar dans `storage.objects` bucket `avatars`, dossier par user id.
5. Favoris tenues cloud dans `profiles.favorite_outfit_ids` + fallback local SharedPreferences.

## 4) Vérification rapide (checklist)

1. Connexion avec un compte A.
2. Modifier profil et vérifier la persistance après relance.
3. Ajouter un événement agenda, relancer app, vérifier récupération.
4. Ajouter une tenue en favori, déconnecter/reconnecter compte A, vérifier favoris.
5. Changer de compte B, vérifier que favoris/profil/agenda sont différents.

## 5) Requêtes de debug utiles

```sql
-- Voir profils
select user_id, display_name, favorite_outfit_ids, updated_at
from public.profiles
order by updated_at desc
limit 20;

-- Voir agenda du compte connecte (dans SQL Editor avec role SQL, remplacer UUID)
select user_id, title, start_time, end_time, event_type, is_completed
from public.agenda_events
where user_id = 'YOUR_USER_UUID'
order by start_time asc;
```

## 6) Dépannage erreur 42703

Si l'app affiche une erreur `42703`, cela signifie qu'une colonne référencée par le client n'existe pas encore en base.

Pour le module favoris, executez cette migration minimale:

```sql
alter table public.profiles
  add column if not exists favorite_outfit_ids text[] not null default '{}';
```

Vérification immédiate:

```sql
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name = 'favorite_outfit_ids';
```

Puis relancez l'app et reconnectez-vous au compte pour relancer la synchronisation cloud.

## 7) Bonnes pratiques

- Garder RLS active sur `profiles` et `agenda_events`.
- Ne jamais utiliser la service key dans le client Flutter.
- Versionner les evolutions SQL (fichier migration).
- Si un champ est ajoute en base, garder une migration `add column if not exists`.
