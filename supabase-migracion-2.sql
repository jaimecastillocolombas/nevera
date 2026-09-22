-- ============================================================
-- Casa NFC — migración 2: PIN por persona
-- Pégalo en Supabase → SQL Editor → Run.
-- Es seguro relanzarlo: no borra nada.
-- ============================================================

-- PIN propio de cada miembro de la casa.
-- null = todavía no ha elegido PIN; la app se lo pedirá al entrar.
alter table members add column if not exists pin text;

-- Los ajustes manuales de puntos son logs sin tarea asociada,
-- así que task_id tiene que poder quedarse vacío.
alter table logs alter column task_id drop not null;

-- Marca quién puede configurar. Cámbialo a tu gusto.
update members set is_parent = true  where name in ('Mamá', 'Papá');
update members set is_parent = false where name = 'Jaime';

-- El PIN global de "modo padres" ya no se usa: ahora cada persona
-- tiene el suyo. La tabla config se queda por si hace falta más adelante.
