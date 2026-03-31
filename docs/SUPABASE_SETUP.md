# Supabase Setup (Profil utilisateur)

Ce guide connecte le profil utilisateur de MagicMirror a Supabase pour Android, iOS, Web, Linux, macOS et Windows.

## 1) Variables d'environnement

Dans votre fichier `.env` (non versionne):

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 2) Table SQL

Executer ce script dans Supabase SQL Editor:

```sql
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Utilisateur',
  avatar_url text not null default '',
  gender text not null default 'Non precise',
  birth_date date,
  age int not null default 25,
  morphology text not null default 'Silhouette non definie',
  preferred_styles text[] not null default array['Casual']::text[],
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
on public.profiles
for select
using (auth.uid() = user_id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = user_id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

Si la table existe deja, executez aussi cette migration:

```sql
alter table public.profiles
  add column if not exists birth_date date;

alter table public.profiles
  alter column morphology set default 'Silhouette non definie';
```

## 2.b) Storage pour photo utilisateur

Executer ensuite ce SQL pour creer le bucket d'avatars et ses politiques:

```sql
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Avatar read public"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

create policy "Avatar upload own folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

create policy "Avatar update own folder"
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

## 2.c) Table agenda (calendrier local applicatif)

Executer ce SQL pour activer un agenda complet lie au compte actif:

```sql
create table if not exists public.agenda_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  location text,
  event_type text not null default 'Autre',
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.agenda_events enable row level security;

create policy "Agenda read own"
on public.agenda_events
for select
using (auth.uid() = user_id);

create policy "Agenda insert own"
on public.agenda_events
for insert
with check (auth.uid() = user_id);

create policy "Agenda update own"
on public.agenda_events
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Agenda delete own"
on public.agenda_events
for delete
using (auth.uid() = user_id);

create index if not exists idx_agenda_events_user_start
  on public.agenda_events(user_id, start_time);
```

## 3) Auth

Le client Flutter propose une page d'inscription/connexion (email + mot de passe).
La session est persistante automatiquement (mobile + web) tant que l'utilisateur ne se deconnecte pas.

## 4) Flux applicatif

- Donnees profil stockees localement (SharedPreferences)
- Bouton "Envoyer": `upsert` sur `public.profiles`
- Bouton "Recuperer": `select` du profil associe au `user_id`
- Bouton "Se deconnecter": fermeture explicite de session Supabase

## 5) Conseils de maintenance

- Conserver `user_id` comme cle primaire unique.
- Garder les politiques RLS actives.
- Ajouter des migrations SQL versionnees pour chaque evolution schema.
