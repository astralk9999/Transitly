-- =============================================================
-- 003_rls_fixes.sql — Parche del linter de Supabase tras 002_rls
-- =============================================================
-- Resuelve los hallazgos de get_advisors(security) que aparecieron
-- al habilitar RLS en F2.3. Aplicar después de 002_rls.sql.
--
-- Cubre:
--   - WARN function_search_path_mutable en touch_updated_at y
--     cleanup_expired_bus_positions (añade SET search_path).
--   - WARN authenticated_security_definer_function_executable en
--     handle_new_user (revocamos EXECUTE; el trigger sigue
--     funcionando porque corre como el owner postgres).
--
-- Hallazgos NO arreglables / aceptados conscientemente:
--   - ERROR rls_disabled_in_public en spatial_ref_sys: la tabla la
--     posee supabase_admin, no podemos hacer ALTER. Es un falso
--     positivo común en Supabase — la tabla solo contiene metadata
--     SRID de PostGIS, no datos sensibles. Documentado en
--     PENDIENTES.md como [SIN ASIGNAR] (idealmente Supabase lo
--     arregla en su lado).
--   - WARN extension_in_public en postgis: mover postgis a otro
--     schema rompería todas las queries con `geometry` en `public.*`.
--     Coste/beneficio desfavorable hoy. Pospuesto a una migración
--     dedicada (SIN ASIGNAR).
--   - {anon,authenticated}_security_definer_function_executable en
--     is_admin / is_moderator_or_admin / is_driver_of /
--     is_operator_admin_of: necesarias para evaluar policies de
--     RLS. Las funciones leen auth.uid() del caller, NO exponen
--     info de otros usuarios. Excepción aceptada.
--   - st_estimatedextent (PostGIS): fuera de nuestro control.

-- 1. search_path explícito en helpers de F2.2.
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_expired_bus_positions()
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  DELETE FROM bus_positions
  WHERE expires_at IS NOT NULL
    AND expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- 2. handle_new_user — revocar EXECUTE de PUBLIC/anon/authenticated.
-- El trigger on_auth_user_created sigue funcionando porque corre
-- como el owner postgres. Solo cerramos la puerta de RPC directa.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;
