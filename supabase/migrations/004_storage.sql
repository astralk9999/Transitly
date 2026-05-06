-- =============================================================
-- 004_storage.sql — Buckets de Storage + policies
-- =============================================================
-- F2.4 del plan v2. Crea los 5 buckets de Transitly con sus límites
-- de tamaño y MIME types, y las policies sobre storage.objects que
-- aplican la matriz de roles del Anexo D al filesystem.
--
-- Convención de paths para buckets privados:
--   <auth.uid()>/<scope>/<filename>
--   Ej: 'a1b2.../incident-42/photo1.jpg'
-- Esto permite a las policies validar ownership con
--   (storage.foldername(name))[1] = auth.uid()::text
-- sin necesidad de columnas adicionales.
--
-- Buckets PÚBLICOS (avatars, operator-assets):
--   - SELECT abierto a anon y authenticated.
--   - INSERT/UPDATE/DELETE restringido por path o rol.
--
-- Buckets PRIVADOS (report-attachments, route-attachments,
-- data-exports):
--   - SELECT solo el dueño (path[1] == auth.uid()) y, donde aplica,
--     moderator/admin para revisión.
--   - INSERT solo el dueño en su path.
--   - data-exports especial: el INSERT viene de Edge Functions
--     (service_role), no de clients. SELECT abierto al dueño.
--
-- storage.objects ya viene con RLS habilitado por Supabase. Solo
-- añadimos policies; sin ALTER TABLE.

-- =============================================================
-- 1. CREAR BUCKETS
-- =============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars',             'avatars',             true,   2097152,   ARRAY['image/png','image/jpeg','image/webp','image/gif']),
  ('report-attachments',  'report-attachments',  false,  5242880,   ARRAY['image/png','image/jpeg','image/webp','image/heic','video/mp4']),
  ('route-attachments',   'route-attachments',   false,  5242880,   ARRAY['image/png','image/jpeg','image/webp','application/json','application/geo+json']),
  ('data-exports',        'data-exports',        false,  104857600, ARRAY['application/zip','application/json']),
  ('operator-assets',     'operator-assets',     true,   5242880,   ARRAY['image/png','image/jpeg','image/webp','image/svg+xml'])
ON CONFLICT (id) DO UPDATE
  SET public            = EXCLUDED.public,
      file_size_limit   = EXCLUDED.file_size_limit,
      allowed_mime_types= EXCLUDED.allowed_mime_types;

-- =============================================================
-- 2. POLICIES sobre storage.objects
-- =============================================================

-- ── avatars (público, 2 MB, image/*) ───────────────────────────
CREATE POLICY "avatars_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_self"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_update_self"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_delete_self"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_admin_all"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'avatars' AND public.is_admin())
  WITH CHECK (bucket_id = 'avatars' AND public.is_admin());

-- ── report-attachments (privado, 5 MB, image/* + video/mp4) ────
CREATE POLICY "report_attachments_select_owner"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'report-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "report_attachments_select_mod_admin"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'report-attachments'
    AND public.is_moderator_or_admin()
  );

CREATE POLICY "report_attachments_insert_self"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'report-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "report_attachments_delete_owner"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'report-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "report_attachments_delete_admin"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'report-attachments' AND public.is_admin());

-- ── route-attachments (privado, 5 MB) ──────────────────────────
CREATE POLICY "route_attachments_select_owner"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'route-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "route_attachments_select_mod_admin"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'route-attachments'
    AND public.is_moderator_or_admin()
  );

CREATE POLICY "route_attachments_insert_self"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'route-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "route_attachments_delete_owner"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'route-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "route_attachments_delete_admin"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'route-attachments' AND public.is_admin());

-- ── data-exports (privado, 100 MB, generado por el sistema) ────
-- INSERT lo hacen Edge Functions con service_role (bypassea RLS).
-- Para anon/authenticated: solo SELECT del propio export.
CREATE POLICY "data_exports_select_owner"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'data-exports'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "data_exports_select_admin"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'data-exports' AND public.is_admin());

CREATE POLICY "data_exports_delete_owner"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'data-exports'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── operator-assets (público, 5 MB, logos) ─────────────────────
-- Path convention: <operator_id_uuid>/<filename>.
CREATE POLICY "operator_assets_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'operator-assets');

-- Solo admin o operator_admin del operador correspondiente puede
-- subir/modificar/borrar assets. La validación cruza el path
-- (primer segmento = operator_id) con is_operator_admin_of().
CREATE POLICY "operator_assets_insert_authorized"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'operator-assets'
    AND (
      public.is_admin()
      OR public.is_operator_admin_of(((storage.foldername(name))[1])::uuid)
    )
  );

CREATE POLICY "operator_assets_update_authorized"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'operator-assets'
    AND (
      public.is_admin()
      OR public.is_operator_admin_of(((storage.foldername(name))[1])::uuid)
    )
  )
  WITH CHECK (
    bucket_id = 'operator-assets'
    AND (
      public.is_admin()
      OR public.is_operator_admin_of(((storage.foldername(name))[1])::uuid)
    )
  );

CREATE POLICY "operator_assets_delete_authorized"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'operator-assets'
    AND (
      public.is_admin()
      OR public.is_operator_admin_of(((storage.foldername(name))[1])::uuid)
    )
  );

-- =============================================================
-- Fin de 004_storage.sql
-- =============================================================
