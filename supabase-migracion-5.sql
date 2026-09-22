-- ============================================================
-- Casa NFC — migración 5: tareas asignadas a una persona
-- Pégalo en Supabase → SQL Editor → New query → Run.
-- Es seguro relanzarlo: no borra nada.
-- ============================================================

-- null  = tarea de la casa, la puede hacer cualquiera
-- <id>  = solo esa persona la ve destacada y solo ella la puede marcar
alter table tasks add column if not exists assigned_to text
  references members(id) on delete set null;

create index if not exists tasks_assigned_idx on tasks(assigned_to);
