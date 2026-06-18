-- Tasker initial schema
-- Profiles, lists, list membership (sharing), tasks, task assignees, friendships.
-- Row Level Security is enforced everywhere; helper functions are SECURITY DEFINER
-- to avoid recursive policy evaluation between lists and list_members.
--
-- Colors are stored as full ARGB ints (e.g. 0xFF22D3EE) which exceed int4 range,
-- so color columns are bigint.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  emoji        text   not null default '🙂',
  color        bigint not null default 4280472558,           -- 0xFF22D3EE
  handle       text   unique not null,                       -- short friend code
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- lists
-- ---------------------------------------------------------------------------
create table if not exists public.lists (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references public.profiles (id) on delete cascade,
  name            text,            -- literal name for user-created lists
  name_key        text,            -- 'personal' | 'shared' | 'family' | 'work' for defaults
  color           bigint not null,
  icon_code_point int  not null,
  icon_font_family text,
  position        int  not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists lists_owner_idx on public.lists (owner_id);

create trigger lists_set_updated_at
  before update on public.lists
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- list_members  (who can access a list)
-- ---------------------------------------------------------------------------
create table if not exists public.list_members (
  list_id    uuid not null references public.lists (id) on delete cascade,
  member_id  uuid not null references public.profiles (id) on delete cascade,
  role       text not null default 'member',   -- 'owner' | 'member'
  created_at timestamptz not null default now(),
  primary key (list_id, member_id)
);

create index if not exists list_members_member_idx on public.list_members (member_id);

-- ---------------------------------------------------------------------------
-- tasks
-- ---------------------------------------------------------------------------
create table if not exists public.tasks (
  id           uuid primary key default gen_random_uuid(),
  list_id      uuid not null references public.lists (id) on delete cascade,
  created_by   uuid references public.profiles (id) on delete set null,
  title        text not null,
  note         text,
  done         boolean not null default false,
  completed_by uuid references public.profiles (id) on delete set null,
  completed_at timestamptz,
  due_at       timestamptz,
  position     int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists tasks_list_idx on public.tasks (list_id);

create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- task_assignees
-- ---------------------------------------------------------------------------
create table if not exists public.task_assignees (
  task_id   uuid not null references public.tasks (id) on delete cascade,
  member_id uuid not null references public.profiles (id) on delete cascade,
  primary key (task_id, member_id)
);

-- ---------------------------------------------------------------------------
-- friendships  (one row per direction; insert both directions on accept)
-- ---------------------------------------------------------------------------
create table if not exists public.friendships (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  friend_id  uuid not null references public.profiles (id) on delete cascade,
  status     text not null default 'accepted',   -- 'pending' | 'accepted'
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

-- ---------------------------------------------------------------------------
-- access helpers (SECURITY DEFINER -> bypass RLS to break policy recursion)
-- ---------------------------------------------------------------------------
create or replace function public.is_list_member(_list uuid, _user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.lists l
    where l.id = _list and l.owner_id = _user
  ) or exists (
    select 1 from public.list_members lm
    where lm.list_id = _list and lm.member_id = _user
  );
$$;

create or replace function public.is_list_owner(_list uuid, _user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.lists l
    where l.id = _list and l.owner_id = _user
  );
$$;

create or replace function public.task_list(_task uuid)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select list_id from public.tasks where id = _task;
$$;

-- ---------------------------------------------------------------------------
-- new user bootstrap: profile + handle + four default lists (+ owner membership)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_handle text;
  defaults   record;
  new_list   uuid;
begin
  -- unique 6-char handle
  loop
    new_handle := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (select 1 from public.profiles where handle = new_handle);
  end loop;

  insert into public.profiles (id, display_name, emoji, handle)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'emoji', ''), '🙂'),
    new_handle
  );

  -- seed the four default lists, matching the app's design defaults
  for defaults in
    select * from (values
      ('personal', 4280472558::bigint, 58519, 0),  -- person_outline,  0xFF22D3EE / 0xe497
      ('shared',   4286680312::bigint, 61657, 1),  -- group_outlined,  0xFF818CF8 / 0xf0d9
      ('family',   4294668677::bigint, 61703, 2),  -- home_outlined,   0xFFFB7185 / 0xf107
      ('work',     4294688548::bigint, 59124, 3)   -- work_outline,    0xFFFBBF24 / 0xe6f4
    ) as t(name_key, color, icon_code_point, position)
  loop
    insert into public.lists (owner_id, name_key, color, icon_code_point, icon_font_family, position)
    values (new.id, defaults.name_key, defaults.color, defaults.icon_code_point, 'MaterialIcons', defaults.position)
    returning id into new_list;

    insert into public.list_members (list_id, member_id, role)
    values (new_list, new.id, 'owner');
  end loop;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles       enable row level security;
alter table public.lists          enable row level security;
alter table public.list_members   enable row level security;
alter table public.tasks          enable row level security;
alter table public.task_assignees enable row level security;
alter table public.friendships    enable row level security;

-- profiles: readable by any authenticated user (needed to resolve friends /
-- list members / handles); writable only by the owner.
create policy profiles_select on public.profiles
  for select to authenticated using (true);
create policy profiles_insert on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy profiles_update on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- lists
create policy lists_select on public.lists
  for select to authenticated using (public.is_list_member(id, auth.uid()));
create policy lists_insert on public.lists
  for insert to authenticated with check (owner_id = auth.uid());
create policy lists_update on public.lists
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy lists_delete on public.lists
  for delete to authenticated using (owner_id = auth.uid());

-- list_members: you can see membership of lists you belong to; only the list
-- owner can add/remove members; you may always remove yourself.
create policy list_members_select on public.list_members
  for select to authenticated using (public.is_list_member(list_id, auth.uid()));
create policy list_members_insert on public.list_members
  for insert to authenticated with check (public.is_list_owner(list_id, auth.uid()));
create policy list_members_delete on public.list_members
  for delete to authenticated
  using (public.is_list_owner(list_id, auth.uid()) or member_id = auth.uid());

-- tasks: any member of the list can read/write tasks
create policy tasks_select on public.tasks
  for select to authenticated using (public.is_list_member(list_id, auth.uid()));
create policy tasks_insert on public.tasks
  for insert to authenticated with check (public.is_list_member(list_id, auth.uid()));
create policy tasks_update on public.tasks
  for update to authenticated using (public.is_list_member(list_id, auth.uid()))
  with check (public.is_list_member(list_id, auth.uid()));
create policy tasks_delete on public.tasks
  for delete to authenticated using (public.is_list_member(list_id, auth.uid()));

-- task_assignees: gated by membership of the parent task's list
create policy task_assignees_select on public.task_assignees
  for select to authenticated using (public.is_list_member(public.task_list(task_id), auth.uid()));
create policy task_assignees_insert on public.task_assignees
  for insert to authenticated with check (public.is_list_member(public.task_list(task_id), auth.uid()));
create policy task_assignees_delete on public.task_assignees
  for delete to authenticated using (public.is_list_member(public.task_list(task_id), auth.uid()));

-- friendships: you manage only your own rows
create policy friendships_select on public.friendships
  for select to authenticated using (user_id = auth.uid());
create policy friendships_insert on public.friendships
  for insert to authenticated with check (user_id = auth.uid());
create policy friendships_delete on public.friendships
  for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime: broadcast row changes for live collaboration
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.lists;
alter publication supabase_realtime add table public.list_members;
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.task_assignees;
alter publication supabase_realtime add table public.friendships;
