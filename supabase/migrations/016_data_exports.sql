-- 016_data_exports.sql
-- GDPR: índices auxiliares y función de borrado programado
-- Las tablas (privacy_consents, data_exports, data_deletion_requests)
-- existen en 001_init.sql. RLS en 002_rls.sql. Storage en 004_storage.sql.

-- ── Índices para consultas de exportación y borrado ─────────────

CREATE INDEX IF NOT EXISTS idx_data_exports_user_status
  ON data_exports (user_id, status);

CREATE INDEX IF NOT EXISTS idx_data_deletion_requests_user_status
  ON data_deletion_requests (user_id, status);

-- ── Función: solicitar exportación de datos ──────────────────────
-- La UI inserta un row con status='queued'. Una Edge Function
-- cron/scheduled procesa los queued, genera el ZIP y lo sube a
-- Storage bucket 'data-exports'.

CREATE OR REPLACE FUNCTION public.request_data_export()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.data_exports (user_id, status)
  VALUES (auth.uid(), 'queued');
END;
$$;

COMMENT ON FUNCTION public.request_data_export() IS
  'Inserta una fila en data_exports para el usuario autenticado.';

GRANT EXECUTE ON FUNCTION public.request_data_export() TO authenticated;

-- ── Función: solicitar borrado de cuenta (GDPR derecho al olvido)
-- La UI inserta un row con status='requested' y scheduled_at = +30d.
-- Una Edge Function cron comprueba scheduled_at <= NOW() y ejecuta
-- el borrado (limpia datos del usuario, anonimiza perfiles).

CREATE OR REPLACE FUNCTION public.request_data_deletion()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.data_deletion_requests (user_id, status, requested_at, scheduled_at)
  VALUES (
    auth.uid(),
    'requested',
    NOW(),
    NOW() + INTERVAL '30 days'
  );
END;
$$;

COMMENT ON FUNCTION public.request_data_deletion() IS
  'Solicita el borrado de datos del usuario autenticado (periodo de gracia 30 días).';

GRANT EXECUTE ON FUNCTION public.request_data_deletion() TO authenticated;
