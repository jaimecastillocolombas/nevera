-- ============================================================
-- Casa NFC — migración 4: rechazos con motivo y avisos
-- Pégalo en Supabase → SQL Editor → New query → Run.
-- Es seguro relanzarlo: no borra nada.
-- ============================================================

-- Una tarea rechazada NO se borra: se queda en el historial tachada y
-- deja de sumar. Así queda el rastro de qué pasó y por qué.
alter table logs add column if not exists rejected      boolean not null default false;
alter table logs add column if not exists reject_reason text;
alter table logs add column if not exists rejected_by   text;
alter table logs add column if not exists rejected_at   timestamptz;

-- `seen` = la persona ya ha leído el aviso y le ha dado a "Vale".
alter table logs        add column if not exists seen boolean not null default false;
alter table redemptions add column if not exists seen boolean not null default false;

alter table redemptions add column if not exists reject_reason text;

-- Lo que ya existía queda como visto, para que nadie se encuentre
-- veinte avisos viejos al abrir la app.
update logs        set seen = true where seen = false;
update redemptions set seen = true where seen = false;

create index if not exists logs_rejected_idx  on logs(member_id, rejected, seen);
create index if not exists redem_seen_idx     on redemptions(member_id, seen);
