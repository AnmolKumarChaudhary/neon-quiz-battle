create extension if not exists pgcrypto;
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_player_id uuid,
  status text not null default 'lobby' check (status in ('lobby','playing','finished')),
  category text not null,
  question_index integer not null default 0,
  question_started_at timestamptz,
  current_question jsonb,
  question_ids jsonb not null default '[]'::jsonb,
  total_questions integer not null default 10,
  created_at timestamptz not null default now()
);
create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  nickname text not null,
  score integer not null default 0,
  is_host boolean not null default false,
  joined_at timestamptz not null default now(),
  unique(room_id, nickname)
);
alter table public.rooms add constraint rooms_host_player_fk foreign key (host_player_id) references public.players(id) on delete set null;
create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  question_index integer not null,
  answer_index integer not null,
  submitted_at timestamptz not null default now(),
  unique(room_id, player_id, question_index)
);
create index if not exists players_room_id_idx on public.players(room_id);
create index if not exists submissions_room_question_idx on public.submissions(room_id, question_index);
alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.submissions enable row level security;
-- No direct client access. All reads/writes go through the Edge Function using the service role.
revoke all on public.rooms from anon, authenticated;
revoke all on public.players from anon, authenticated;
revoke all on public.submissions from anon, authenticated;
-- Supabase Realtime sends change notifications; clients refetch the safe room view through the Edge Function.
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;
-- Permit realtime row-change delivery for public game state only. Sensitive submissions remain server-only.
grant select on public.rooms, public.players to anon, authenticated;
create policy "realtime rooms readable" on public.rooms for select to anon, authenticated using (true);
create policy "realtime players readable" on public.players for select to anon, authenticated using (true);
