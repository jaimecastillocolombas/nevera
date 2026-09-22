-- ============================================================
-- Casa NFC — esquema de Supabase
-- Pégalo entero en Supabase → SQL Editor → Run.
-- ============================================================

-- ---------- tablas ----------

create table if not exists members (
  id         text primary key,
  name       text not null,
  color      text not null default '#0E7C5A',
  is_parent  boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists items (
  id         text primary key,
  name       text not null,
  qty        text default '',
  category   text default 'Otros',
  added_by   text references members(id) on delete set null,
  created_at timestamptz not null default now(),
  done       boolean not null default false,
  done_by    text references members(id) on delete set null,
  done_at    timestamptz
);

create table if not exists tasks (
  id         text primary key,
  title      text not null,
  points     integer not null default 5,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists logs (
  id         text primary key,
  task_id    text,
  title      text not null,
  member_id  text references members(id) on delete cascade,
  points     integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists rewards (
  id         text primary key,
  title      text not null,
  cost       integer not null default 50,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists redemptions (
  id         text primary key,
  reward_id  text,
  title      text not null,
  member_id  text references members(id) on delete cascade,
  cost       integer not null default 0,
  status     text not null default 'pendiente',   -- pendiente | aprobado | rechazado
  created_at timestamptz not null default now()
);

create table if not exists config (
  id         text primary key,
  pin        text not null default '1234',
  updated_at timestamptz not null default now()
);

create index if not exists items_done_idx  on items(done);
create index if not exists logs_member_idx on logs(member_id);

-- ---------- acceso ----------
-- Esta app no tiene login: el navegador usa la clave "anon" pública.
-- Por eso abrimos las políticas a cualquiera que tenga la URL de la app.
-- Es un tablón de casa, no guardes aquí nada sensible.
-- Si algún día quieres cerrarlo, activa Supabase Auth y cambia
-- "using (true)" por "using (auth.uid() is not null)".

do $$
declare t text;
begin
  foreach t in array array['members','items','tasks','logs','rewards','redemptions','config'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists casa_all on %I', t);
    execute format(
      'create policy casa_all on %I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ---------- tiempo real ----------
-- Hace que los cambios lleguen solos a los demás móviles.
do $$
declare t text;
begin
  foreach t in array array['members','items','tasks','logs','rewards','redemptions','config'] loop
    begin
      execute format('alter publication supabase_realtime add table %I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

alter table items       replica identity full;
alter table logs        replica identity full;
alter table redemptions replica identity full;

-- ---------- datos iniciales ----------

insert into config (id, pin) values ('main', '1234')
  on conflict (id) do nothing;

insert into members (id, name, color, is_parent) values
  ('m_jaime', 'Jaime', '#0E7C5A', false),
  ('m_mama',  'Mamá',  '#3F6BB5', true),
  ('m_papa',  'Papá',  '#B4690E', true)
  on conflict (id) do nothing;

insert into tasks (id, title, points) values
  ('t_basura',   'Sacar la basura',        5),
  ('t_lavav_on', 'Poner el lavavajillas',  5),
  ('t_lavav_off','Vaciar el lavavajillas', 5),
  ('t_tender',   'Tender la lavadora',    10),
  ('t_compra',   'Hacer la compra',       20),
  ('t_aspirar',  'Pasar la aspiradora',   15)
  on conflict (id) do nothing;

insert into rewards (id, title, cost) values
  ('r_cena',  'Eliges tú la cena del viernes',  40),
  ('r_peli',  'Noche de peli, la eliges tú',    60),
  ('r_libre', 'Te libras de una tarea',         80),
  ('r_fuera', 'Cena fuera de casa',            200)
  on conflict (id) do nothing;
