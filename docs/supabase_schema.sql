-- Flow & Park Puzzle — Supabase schema
-- Run in the Supabase SQL editor. Cloud features are optional; the game is
-- fully playable offline without any of this.

-- ── users ────────────────────────────────────────────────────────────────────
create table if not exists public.users (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text,
  coins       integer not null default 0,
  level       integer not null default 1,
  created_at  timestamptz not null default now()
);

-- If the table already exists, add the display-name column:
-- alter table public.users add column if not exists name text;

-- ── progress ─────────────────────────────────────────────────────────────────
create table if not exists public.progress (
  user_id     uuid not null references public.users (id) on delete cascade,
  level       integer not null,
  score       integer not null default 0,
  last_played timestamptz not null default now(),
  primary key (user_id, level)
);

-- ── analytics_events ─────────────────────────────────────────────────────────
create table if not exists public.analytics_events (
  id         bigserial primary key,
  user_id    uuid references public.users (id) on delete set null,
  event_name text not null,
  timestamp  timestamptz not null default now()
);

-- ── Row Level Security ───────────────────────────────────────────────────────
alter table public.users enable row level security;
alter table public.progress enable row level security;
alter table public.analytics_events enable row level security;

create policy "own user row" on public.users
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Anyone may read the (non-sensitive) leaderboard columns of every user.
create policy "leaderboard read" on public.users
  for select using (true);

create policy "own progress" on public.progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own analytics" on public.analytics_events
  for insert with check (auth.uid() = user_id);

-- ── Leaderboard (public read of a safe view) ─────────────────────────────────
create or replace view public.leaderboard as
  select id, level, coins from public.users
  order by level desc, coins desc
  limit 100;
