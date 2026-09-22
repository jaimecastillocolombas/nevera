-- ============================================================
-- Casa NFC — migración 3: pruebas con foto en las tareas
-- Pégalo en Supabase → SQL Editor → New query → Run.
-- Es seguro relanzarlo: no borra nada.
-- ============================================================

-- Las fotos no se guardan en la tabla, solo su dirección pública.
alter table logs add column if not exists photo_before text;
alter table logs add column if not exists photo_after  text;

-- ---------- almacén de fotos ----------
-- Bucket público: las fotos se ven con su URL, igual que la app.
insert into storage.buckets (id, name, public)
values ('pruebas', 'pruebas', true)
on conflict (id) do update set public = true;

-- Quien pueda abrir la app puede subir y ver pruebas.
-- Borrar solo desde el panel de Supabase, para que nadie tape su rastro.
drop policy if exists pruebas_leer   on storage.objects;
drop policy if exists pruebas_subir  on storage.objects;

create policy pruebas_leer on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'pruebas');

create policy pruebas_subir on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'pruebas');
