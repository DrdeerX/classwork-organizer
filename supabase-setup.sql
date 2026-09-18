-- Run this once in Supabase Dashboard > SQL Editor, on your own project.
-- Creates tables + storage bucket for Classwork Organizer, with row-level
-- security so each user can only ever read/write their own rows and files.

create table if not exists public.classes (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.files (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  class_id text,
  data jsonb not null,
  created_at timestamptz not null default now()
);
create index if not exists files_class_id_idx on public.files(class_id);

create table if not exists public.questions (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  class_id text,
  data jsonb not null,
  created_at timestamptz not null default now()
);
create index if not exists questions_class_id_idx on public.questions(class_id);

create table if not exists public.events (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.goals (
  id text primary key,
  user_id uuid not null references auth.users(id) default auth.uid(),
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.meta (
  key text not null,
  user_id uuid not null references auth.users(id) default auth.uid(),
  data jsonb not null,
  primary key (user_id, key)
);

alter table public.classes enable row level security;
alter table public.files enable row level security;
alter table public.questions enable row level security;
alter table public.events enable row level security;
alter table public.transactions enable row level security;
alter table public.goals enable row level security;
alter table public.meta enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['classes','files','questions','events','transactions','goals','meta'] loop
    execute format('drop policy if exists "own rows" on public.%I', t);
    execute format('create policy "own rows" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)', t);
  end loop;
end $$;

insert into storage.buckets (id, name, public)
values ('files', 'files', false)
on conflict (id) do nothing;

drop policy if exists "own files" on storage.objects;
create policy "own files" on storage.objects for all
  using (bucket_id = 'files' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'files' and auth.uid()::text = (storage.foldername(name))[1]);
