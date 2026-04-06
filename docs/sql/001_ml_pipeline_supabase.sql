-- ML pipeline schema for MagicMirror
-- Safe to run multiple times.

-- Needed for gen_random_uuid() in default values.
create extension if not exists pgcrypto;

-- -------------------------------------
-- Feedback events (written by app)
-- -------------------------------------
create table if not exists public.outfit_feedback_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  outfit_id text,
  payload jsonb,
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

-- -------------------------------------
-- ML scores (read by app, written by batch job)
-- -------------------------------------
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

-- Keep updated_at consistent on updates.
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

-- NOTE:
-- The Railway batch uses SUPABASE_SERVICE_ROLE_KEY.
-- Service role bypasses RLS and can upsert into outfit_ml_scores.
