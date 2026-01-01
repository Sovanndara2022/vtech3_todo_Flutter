
begin;

-- Optional but common: enables gen_random_uuid()
create extension if not exists pgcrypto;

-- Clean reset (prevents old schema cache mismatch)
drop table if exists public.todos cascade;

create table public.todos (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  normalized_text text generated always as (lower(trim(text))) stored,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- No duplicates globally (case-insensitive + trimmed)
create unique index todos_normalized_text_unique
  on public.todos (normalized_text);

-- updated_at trigger function
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger todos_set_updated_at
before update on public.todos
for each row
execute function public.set_updated_at();

-- RLS
alter table public.todos enable row level security;

drop policy if exists "anon select" on public.todos;
create policy "anon select"
on public.todos
for select
to anon
using (true);

drop policy if exists "anon insert" on public.todos;
create policy "anon insert"
on public.todos
for insert
to anon
with check (true);

drop policy if exists "anon update" on public.todos;
create policy "anon update"
on public.todos
for update
to anon
using (true)
with check (true);

drop policy if exists "anon delete" on public.todos;
create policy "anon delete"
on public.todos
for delete
to anon
using (true);

-- Enable Realtime publication for Postgres Changes
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      execute 'alter publication supabase_realtime add table public.todos';
    exception
      when duplicate_object then null;
    end;
  end if;
end;
$$;

-- IMPORTANT: force PostgREST schema cache reload (fixes PGRST204)
notify pgrst, 'reload schema';

commit;
