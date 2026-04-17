-- MagicMirror - Supabase full setup (idempotent)
-- Safe to execute multiple times in Supabase SQL Editor.

begin;

-- Extension for gen_random_uuid()
create extension if not exists pgcrypto;

-- --------------------------------------------------
-- Profiles
-- --------------------------------------------------
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Utilisateur',
  avatar_url text not null default '',
  gender text not null default 'Non precise',
  birth_date date,
  age int not null default 25,
  height_cm int not null default 170,
  morphology text not null default 'Silhouette non definie',
  preferred_styles text[] not null default array['Casual']::text[],
  favorite_outfit_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- Defensive migrations for existing projects
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists height_cm int;
alter table public.profiles add column if not exists favorite_outfit_ids text[] not null default '{}';
alter table public.profiles alter column morphology set default 'Silhouette non definie';

-- Backfill + constraints for height_cm
update public.profiles
set height_cm = 170
where height_cm is null;

alter table public.profiles alter column height_cm set default 170;
alter table public.profiles alter column height_cm set not null;

alter table public.profiles
drop constraint if exists profiles_height_cm_check;

alter table public.profiles
add constraint profiles_height_cm_check
check (height_cm between 120 and 230);

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

-- --------------------------------------------------
-- Agenda events
-- --------------------------------------------------
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

create index if not exists idx_agenda_events_user_start
  on public.agenda_events(user_id, start_time);

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

-- --------------------------------------------------
-- Outfit feedback events
-- --------------------------------------------------
create table if not exists public.outfit_feedback_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  outfit_id text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_outfit_feedback_events_user_created
  on public.outfit_feedback_events(user_id, created_at desc);

alter table public.outfit_feedback_events enable row level security;

drop policy if exists "outfit_feedback_select_own" on public.outfit_feedback_events;
drop policy if exists "outfit_feedback_insert_own" on public.outfit_feedback_events;

create policy "outfit_feedback_select_own"
on public.outfit_feedback_events
for select
to authenticated
using (user_id = auth.uid());

create policy "outfit_feedback_insert_own"
on public.outfit_feedback_events
for insert
to authenticated
with check (user_id = auth.uid());

-- --------------------------------------------------
-- Outfit ML scores (optional)
-- --------------------------------------------------
create table if not exists public.outfit_ml_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  outfit_id text not null,
  score double precision not null check (score >= 0 and score <= 1),
  updated_at timestamptz not null default now(),
  unique (user_id, outfit_id)
);

create index if not exists idx_outfit_ml_scores_user
  on public.outfit_ml_scores(user_id);

create index if not exists idx_outfit_ml_scores_updated_at
  on public.outfit_ml_scores(updated_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_outfit_ml_scores_updated_at on public.outfit_ml_scores;
create trigger trg_outfit_ml_scores_updated_at
before update on public.outfit_ml_scores
for each row
execute function public.set_updated_at();

alter table public.outfit_ml_scores enable row level security;

drop policy if exists "outfit_ml_scores_select_own" on public.outfit_ml_scores;

create policy "outfit_ml_scores_select_own"
on public.outfit_ml_scores
for select
to authenticated
using (user_id = auth.uid());

-- --------------------------------------------------
-- Outfit LLM scores (optional, secondary model / Llama)
-- --------------------------------------------------
create table if not exists public.outfit_llm_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  outfit_id text not null,
  score double precision not null check (score >= 0 and score <= 1),
  model_tag text not null default 'secondary',
  target_gender text,
  target_styles text[],
  target_morphology text,
  profile_payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, outfit_id, model_tag)
);

create index if not exists idx_outfit_llm_scores_user_model
  on public.outfit_llm_scores(user_id, model_tag);

create index if not exists idx_outfit_llm_scores_updated_at
  on public.outfit_llm_scores(updated_at desc);

drop trigger if exists trg_outfit_llm_scores_updated_at on public.outfit_llm_scores;
create trigger trg_outfit_llm_scores_updated_at
before update on public.outfit_llm_scores
for each row
execute function public.set_updated_at();

alter table public.outfit_llm_scores enable row level security;

drop policy if exists "outfit_llm_scores_select_own" on public.outfit_llm_scores;

create policy "outfit_llm_scores_select_own"
on public.outfit_llm_scores
for select
to authenticated
using (user_id = auth.uid());

-- --------------------------------------------------
-- Outfit LLM details (optional, detailed composition)
-- --------------------------------------------------
create table if not exists public.outfit_llm_details (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  outfit_id text not null,
  model_tag text not null default 'secondary',
  type_label text,
  summary text,
  top_item text,
  bottom_item text,
  shoes_item text,
  outerwear_item text,
  accessories text[] not null default '{}'::text[],
  target_gender text,
  target_styles text[],
  target_morphology text,
  profile_payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, outfit_id, model_tag)
);

create index if not exists idx_outfit_llm_details_user_model
  on public.outfit_llm_details(user_id, model_tag);

create index if not exists idx_outfit_llm_details_updated_at
  on public.outfit_llm_details(updated_at desc);

drop trigger if exists trg_outfit_llm_details_updated_at on public.outfit_llm_details;
create trigger trg_outfit_llm_details_updated_at
before update on public.outfit_llm_details
for each row
execute function public.set_updated_at();

alter table public.outfit_llm_details enable row level security;

drop policy if exists "outfit_llm_details_select_own" on public.outfit_llm_details;

create policy "outfit_llm_details_select_own"
on public.outfit_llm_details
for select
to authenticated
using (user_id = auth.uid());

-- --------------------------------------------------
-- Helper functions for Llama output upserts (service role)
-- --------------------------------------------------
create or replace function public.upsert_outfit_llm_scores(
  p_rows jsonb
)
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
      user_id uuid,
      outfit_id text,
      score double precision,
      model_tag text,
      target_gender text,
      target_styles text[],
      target_morphology text,
      profile_payload jsonb
    )
    where r.user_id is not null
      and r.outfit_id is not null
      and r.outfit_id <> ''
      and r.score is not null
      and r.score between 0 and 1
  ), upserted as (
    insert into public.outfit_llm_scores (
      user_id,
      outfit_id,
      score,
      model_tag,
      target_gender,
      target_styles,
      target_morphology,
      profile_payload
    )
    select
      user_id,
      outfit_id,
      score,
      model_tag,
      target_gender,
      target_styles,
      target_morphology,
      profile_payload
    from parsed
    on conflict (user_id, outfit_id, model_tag)
    do update
      set score = excluded.score,
          target_gender = excluded.target_gender,
          target_styles = excluded.target_styles,
          target_morphology = excluded.target_morphology,
          profile_payload = excluded.profile_payload,
          updated_at = now()
    returning 1
  )
  select count(*) into _count from upserted;

  return _count;
end;
$$;

create or replace function public.upsert_outfit_llm_details(
  p_rows jsonb
)
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
      r.type_label,
      r.summary,
      r.top_item,
      r.bottom_item,
      r.shoes_item,
      r.outerwear_item,
      coalesce(r.accessories, '{}'::text[]) as accessories,
      r.target_gender,
      r.target_styles,
      r.target_morphology,
      coalesce(r.profile_payload, '{}'::jsonb) as profile_payload
    from jsonb_to_recordset(p_rows) as r(
      user_id uuid,
      outfit_id text,
      model_tag text,
      type_label text,
      summary text,
      top_item text,
      bottom_item text,
      shoes_item text,
      outerwear_item text,
      accessories text[],
      target_gender text,
      target_styles text[],
      target_morphology text,
      profile_payload jsonb
    )
    where r.user_id is not null
      and r.outfit_id is not null
      and r.outfit_id <> ''
  ), upserted as (
    insert into public.outfit_llm_details (
      user_id,
      outfit_id,
      model_tag,
      type_label,
      summary,
      top_item,
      bottom_item,
      shoes_item,
      outerwear_item,
      accessories,
      target_gender,
      target_styles,
      target_morphology,
      profile_payload
    )
    select
      user_id,
      outfit_id,
      model_tag,
      type_label,
      summary,
      top_item,
      bottom_item,
      shoes_item,
      outerwear_item,
      accessories,
      target_gender,
      target_styles,
      target_morphology,
      profile_payload
    from parsed
    on conflict (user_id, outfit_id, model_tag)
    do update
      set type_label = excluded.type_label,
          summary = excluded.summary,
          top_item = excluded.top_item,
          bottom_item = excluded.bottom_item,
          shoes_item = excluded.shoes_item,
          outerwear_item = excluded.outerwear_item,
          accessories = excluded.accessories,
          target_gender = excluded.target_gender,
          target_styles = excluded.target_styles,
          target_morphology = excluded.target_morphology,
          profile_payload = excluded.profile_payload,
          updated_at = now()
    returning 1
  )
  select count(*) into _count from upserted;

  return _count;
end;
$$;

revoke all on function public.upsert_outfit_llm_scores(jsonb) from public;
revoke all on function public.upsert_outfit_llm_details(jsonb) from public;
grant execute on function public.upsert_outfit_llm_scores(jsonb) to service_role;
grant execute on function public.upsert_outfit_llm_details(jsonb) to service_role;

-- --------------------------------------------------
-- Storage bucket + policies for avatars
-- --------------------------------------------------
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

commit;

-- Notes:
-- 1) The app reads/writes with anon key + RLS policies above.
-- 2) The batch ML job should use SUPABASE_SERVICE_ROLE_KEY for upserts to
--    public.outfit_ml_scores (service role bypasses RLS).
-- 3) Llama/secondary job should upsert into public.outfit_llm_scores and
--    public.outfit_llm_details (service role bypasses RLS).
-- 4) You can call:
--    select public.upsert_outfit_llm_scores('[{"user_id":"...","outfit_id":"elegant","score":0.84}]'::jsonb);
--    select public.upsert_outfit_llm_details('[{"user_id":"...","outfit_id":"elegant","summary":"Chemise + chino","top_item":"Chemise","bottom_item":"Chino"}]'::jsonb);
