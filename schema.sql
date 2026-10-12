-- Crewboard schema for Supabase. Run in SQL Editor.
create table positions (            -- roles the manager can assign
  id uuid primary key default gen_random_uuid(),
  name text not null unique, hint text, division text, level int not null default 0,
  created_at timestamptz not null default now());

create table workers (
  id uuid primary key default gen_random_uuid(),
  name text not null, phone text not null,
  position text,                                   -- what the worker applied as
  assigned_role_id uuid references positions(id) on delete set null,  -- set by manager
  title text, years int check (years >= 0), area text, skills text,
  available boolean not null default true,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now());

create table suppliers (
  id uuid primary key default gen_random_uuid(),
  company text not null, contact text, phone text not null, category text, area text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now());

create table supplier_items (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references suppliers(id) on delete cascade,
  name text not null, unit text, price numeric(12,2) check (price >= 0));

create table projects (
  id uuid primary key default gen_random_uuid(),
  name text not null, client text, site text,
  status text not null default 'planning' check (status in ('planning','active','done')),
  source text, start_date date, end_date date, created_at timestamptz not null default now());

create table assignments (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  project_id uuid not null references projects(id) on delete cascade,
  since timestamptz not null default now(),
  unique (worker_id, project_id));

create table supply_orders (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references suppliers(id) on delete restrict,
  project_id uuid references projects(id) on delete set null,
  details text, amount numeric(12,2), due_date date,
  status text not null default 'ordered' check (status in ('ordered','delivered','cancelled')),
  created_at timestamptz not null default now());

create table managers (user_id uuid primary key references auth.users(id) on delete cascade);

create index on workers(status); create index on suppliers(status);
create index on assignments(project_id); create index on supplier_items(supplier_id);

-- Row Level Security
create function is_manager() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from managers where user_id = auth.uid()) $$;

alter table positions enable row level security;  alter table workers enable row level security;
alter table suppliers enable row level security;  alter table supplier_items enable row level security;
alter table projects enable row level security;   alter table assignments enable row level security;
alter table supply_orders enable row level security; alter table managers enable row level security;

-- managers: full access to everything
do $$ declare t text; begin
  foreach t in array array['positions','workers','suppliers','supplier_items','projects','assignments','supply_orders'] loop
    execute format('create policy "mgr all" on %I for all to authenticated using (is_manager()) with check (is_manager())', t);
  end loop; end $$;

-- the public join form: insert only, never read
create policy "join worker"   on workers        for insert to anon with check (status = 'pending' and assigned_role_id is null);
create policy "join supplier" on suppliers      for insert to anon with check (status = 'pending');
create policy "join items"    on supplier_items for insert to anon with check (true);
create policy "read positions" on positions     for select to anon, authenticated using (true);
create policy "see self" on managers for select to authenticated using (user_id = auth.uid());

-- After creating your login under Authentication > Users, make yourself manager:
-- insert into managers (user_id) values ('YOUR-AUTH-USER-UUID');
