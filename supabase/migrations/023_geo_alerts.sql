-- ============================================================================
-- 023_geo_alerts.sql
-- P2-#55 — Sistema de avisos geolocalizados administrados.
--
-- El admin define un aviso con centro (lat, lng) + radio (m) + severidad +
-- contenido. Los usuarios que estén dentro del radio reciben el aviso en
-- el home y opcionalmente una push local.
-- ============================================================================

BEGIN;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'geo_alert_severity') THEN
    CREATE TYPE public.geo_alert_severity AS ENUM ('info', 'warning', 'critical');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.geo_alerts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  severity     public.geo_alert_severity NOT NULL DEFAULT 'info',
  center_lat   DOUBLE PRECISION NOT NULL,
  center_lng   DOUBLE PRECISION NOT NULL,
  radius_m     INTEGER NOT NULL CHECK (radius_m BETWEEN 50 AND 50000),
  active       BOOLEAN NOT NULL DEFAULT true,
  created_by   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS geo_alerts_active_idx
  ON public.geo_alerts(active, expires_at) WHERE active = true;

COMMENT ON TABLE public.geo_alerts IS
  'P2-#55: avisos geo definidos por admin. Usuarios dentro del radio reciben el aviso.';

ALTER TABLE public.geo_alerts ENABLE ROW LEVEL SECURITY;

-- Lectura pública (cualquier usuario autenticado puede leer avisos activos
-- no expirados) — el filtrado por distancia se hace cliente-side por simplicidad.
DROP POLICY IF EXISTS geo_alerts_select ON public.geo_alerts;
CREATE POLICY geo_alerts_select
  ON public.geo_alerts FOR SELECT
  USING (
    active = true
    AND (expires_at IS NULL OR expires_at > NOW())
  );

-- Solo admin puede crear / editar / borrar.
DROP POLICY IF EXISTS geo_alerts_insert ON public.geo_alerts;
CREATE POLICY geo_alerts_insert
  ON public.geo_alerts FOR INSERT
  WITH CHECK (public.is_admin() AND created_by = auth.uid());

DROP POLICY IF EXISTS geo_alerts_update ON public.geo_alerts;
CREATE POLICY geo_alerts_update
  ON public.geo_alerts FOR UPDATE
  USING (public.is_admin());

DROP POLICY IF EXISTS geo_alerts_delete ON public.geo_alerts;
CREATE POLICY geo_alerts_delete
  ON public.geo_alerts FOR DELETE
  USING (public.is_admin());

COMMIT;
