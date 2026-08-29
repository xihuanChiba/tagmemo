create table if not exists public.notes (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  labels jsonb not null default '[]'::jsonb,
  color_value bigint not null default 4294965432,
  is_pinned boolean not null default false,
  is_archived boolean not null default false,
  created_at bigint not null,
  updated_at bigint not null,
  deleted_at bigint,
  constraint notes_labels_array check (jsonb_typeof(labels) = 'array')
);

create index if not exists notes_user_updated_idx
  on public.notes(user_id, updated_at);

alter table public.notes enable row level security;

drop policy if exists "Users can read own notes" on public.notes;
create policy "Users can read own notes"
  on public.notes for select
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create own notes" on public.notes;
create policy "Users can create own notes"
  on public.notes for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own notes" on public.notes;
create policy "Users can update own notes"
  on public.notes for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own notes" on public.notes;
create policy "Users can delete own notes"
  on public.notes for delete
  using ((select auth.uid()) = user_id);
