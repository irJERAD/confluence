-- Confluence — Supabase schema
-- Run this in the Supabase SQL Editor (Project > SQL Editor > New query) once,
-- on a fresh project. Safe to re-run: each statement guards against re-creation.

-- Threads: the open questions/decisions a confluence can resolve.
create table if not exists threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  title text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  resolved_at timestamptz
);

-- Confluences: the logged moments themselves.
create table if not exists confluences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  type text not null check (type in ('echo', 'resolution', 'recurrence', 'convergence', 'unsorted')),
  summary text not null,
  context text not null default '',
  people text[] not null default '{}',
  tags text[] not null default '{}',
  charge smallint not null default 0 check (charge between 0 and 5),
  thread_id uuid references threads (id) on delete set null
);

-- Quick-added confluences (captured by voice, not yet classified) land with
-- needs_review = true until the user opens them and fills in the rest.
alter table confluences
  add column if not exists needs_review boolean not null default false;

-- A resolved thread points back at the confluence that resolved it.
alter table threads
  add column if not exists resolved_by uuid references confluences (id) on delete set null;

create index if not exists confluences_user_created_idx on confluences (user_id, created_at desc);
create index if not exists confluences_thread_idx on confluences (thread_id);
create index if not exists threads_user_status_idx on threads (user_id, status);

-- Row Level Security: every row is only visible to and writable by its owner.
alter table confluences enable row level security;
alter table threads enable row level security;

drop policy if exists "confluences_select_own" on confluences;
create policy "confluences_select_own" on confluences
  for select using (auth.uid() = user_id);

drop policy if exists "confluences_insert_own" on confluences;
create policy "confluences_insert_own" on confluences
  for insert with check (auth.uid() = user_id);

drop policy if exists "confluences_update_own" on confluences;
create policy "confluences_update_own" on confluences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "confluences_delete_own" on confluences;
create policy "confluences_delete_own" on confluences
  for delete using (auth.uid() = user_id);

drop policy if exists "threads_select_own" on threads;
create policy "threads_select_own" on threads
  for select using (auth.uid() = user_id);

drop policy if exists "threads_insert_own" on threads;
create policy "threads_insert_own" on threads
  for insert with check (auth.uid() = user_id);

drop policy if exists "threads_update_own" on threads;
create policy "threads_update_own" on threads
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "threads_delete_own" on threads;
create policy "threads_delete_own" on threads
  for delete using (auth.uid() = user_id);
