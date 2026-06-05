-- ============================================================================
-- 021_admin_extras.sql
-- P1.5-02 — campos faltantes para el sistema admin/operator/driver:
--   - operators.is_active, operators.color
--   - stops.source (route_source enum reutilizado)
--   - operator_route_proposals (rutas creadas por driver pendientes)
--   - operator_applications (solicitudes alta de operator)
--   - driver_applications (solicitudes alta de driver vía operator)
--   - route_feedback.escalated_to_admin
--   - incidents.escalated_to_admin
--   - RLS: admin total, operator_admin solo lo suyo, driver solo lo suyo.
--
-- Idempotente: ejecutable múltiples veces sin error.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. operators: is_active + color
-- ----------------------------------------------------------------------------
ALTER TABLE public.operators
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.operators
  ADD COLUMN IF NOT EXISTS color TEXT;

COMMENT ON COLUMN public.operators.is_active IS
  'Si false el operador queda invisible en mapa y listados; preserva las rutas.';
COMMENT ON COLUMN public.operators.color IS
  'Color hex (sin #) para badge en UI. Ej: FF6F00 = COMUJESA naranja.';

-- ----------------------------------------------------------------------------
-- 2. stops.source: distinguir oficiales vs comunidad.
-- Reutilizamos el enum route_source (official | community).
-- ----------------------------------------------------------------------------
ALTER TABLE public.stops
  ADD COLUMN IF NOT EXISTS source public.route_source NOT NULL DEFAULT 'official';

ALTER TABLE public.stops
  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.stops.source IS
  'official: creadas por operator/driver/admin. community: sugeridas por usuarios.';
COMMENT ON COLUMN public.stops.owner_id IS
  'Quién creó la parada (community). NULL para oficiales heredadas de GTFS.';

-- ----------------------------------------------------------------------------
-- 3. operator_route_proposals: rutas creadas por driver pendientes de aprobar.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.operator_route_proposals (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id     UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  operator_id  UUID NOT NULL REFERENCES public.operators(id) ON DELETE CASCADE,
  proposed_by  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at  TIMESTAMPTZ,
  review_notes TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS operator_route_proposals_status_idx
  ON public.operator_route_proposals(status, operator_id);
CREATE INDEX IF NOT EXISTS operator_route_proposals_proposer_idx
  ON public.operator_route_proposals(proposed_by);

COMMENT ON TABLE public.operator_route_proposals IS
  'Cuando un driver crea una ruta, queda en pending hasta que admin u operator_admin la aprueba.';

-- ----------------------------------------------------------------------------
-- 4. operator_applications: solicitudes de alta de operator_admin.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.operator_applications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  operator_name   TEXT NOT NULL,
  operator_slug   TEXT,
  contact_email   TEXT NOT NULL,
  contact_phone   TEXT,
  country         TEXT NOT NULL DEFAULT 'ES',
  region          TEXT,
  justification   TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  review_notes    TEXT,
  created_operator_id UUID REFERENCES public.operators(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS operator_applications_status_idx
  ON public.operator_applications(status);
CREATE INDEX IF NOT EXISTS operator_applications_applicant_idx
  ON public.operator_applications(applicant_id);

COMMENT ON TABLE public.operator_applications IS
  'Solicitudes de usuarios para convertirse en operator_admin. Solo admin aprueba.';

-- ----------------------------------------------------------------------------
-- 5. driver_applications: solicitudes de alta de driver vía operator.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.driver_applications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  operator_id     UUID NOT NULL REFERENCES public.operators(id) ON DELETE CASCADE,
  contact_phone   TEXT,
  license_number  TEXT,
  experience_yrs  INTEGER,
  justification   TEXT,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  review_notes    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS driver_applications_status_idx
  ON public.driver_applications(status, operator_id);
CREATE INDEX IF NOT EXISTS driver_applications_applicant_idx
  ON public.driver_applications(applicant_id);

COMMENT ON TABLE public.driver_applications IS
  'Solicitudes para ser driver en un operador. Aprueba el operator_admin del operador, o admin.';

-- ----------------------------------------------------------------------------
-- 6. escalated_to_admin en incidents y route_feedback.
-- ----------------------------------------------------------------------------
ALTER TABLE public.incidents
  ADD COLUMN IF NOT EXISTS escalated_to_admin BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.route_feedback
  ADD COLUMN IF NOT EXISTS escalated_to_admin BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS incidents_escalated_idx
  ON public.incidents(escalated_to_admin) WHERE escalated_to_admin = true;
CREATE INDEX IF NOT EXISTS route_feedback_escalated_idx
  ON public.route_feedback(escalated_to_admin) WHERE escalated_to_admin = true;

-- ============================================================================
-- 7. RLS — admin total, operator_admin restringido a sus operadores,
-- driver restringido a sus assignments, user solo lee oficiales + propias.
-- ============================================================================

-- Helper: ¿es admin el usuario actual?
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
  LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- Helper: ¿es operator_admin de operator_id?
CREATE OR REPLACE FUNCTION public.is_operator_admin_of(p_operator_id UUID)
  RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN public.driver_assignments d ON d.driver_id = p.id
    WHERE p.id = auth.uid()
      AND p.role = 'operator_admin'
      AND d.operator_id = p_operator_id
      AND d.revoked_at IS NULL
  );
$$;

-- 7.1 operator_route_proposals
ALTER TABLE public.operator_route_proposals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS operator_route_proposals_select ON public.operator_route_proposals;
CREATE POLICY operator_route_proposals_select
  ON public.operator_route_proposals FOR SELECT
  USING (
    public.is_admin()
    OR public.is_operator_admin_of(operator_id)
    OR proposed_by = auth.uid()
  );

DROP POLICY IF EXISTS operator_route_proposals_insert ON public.operator_route_proposals;
CREATE POLICY operator_route_proposals_insert
  ON public.operator_route_proposals FOR INSERT
  WITH CHECK (proposed_by = auth.uid());

DROP POLICY IF EXISTS operator_route_proposals_update ON public.operator_route_proposals;
CREATE POLICY operator_route_proposals_update
  ON public.operator_route_proposals FOR UPDATE
  USING (
    public.is_admin()
    OR public.is_operator_admin_of(operator_id)
  );

-- 7.2 operator_applications: el usuario ve la suya, admin ve todas.
ALTER TABLE public.operator_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS operator_applications_select ON public.operator_applications;
CREATE POLICY operator_applications_select
  ON public.operator_applications FOR SELECT
  USING (public.is_admin() OR applicant_id = auth.uid());

DROP POLICY IF EXISTS operator_applications_insert ON public.operator_applications;
CREATE POLICY operator_applications_insert
  ON public.operator_applications FOR INSERT
  WITH CHECK (applicant_id = auth.uid());

DROP POLICY IF EXISTS operator_applications_update ON public.operator_applications;
CREATE POLICY operator_applications_update
  ON public.operator_applications FOR UPDATE
  USING (public.is_admin());

-- 7.3 driver_applications: el usuario ve la suya, operator_admin del operador ve las suyas, admin todo.
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS driver_applications_select ON public.driver_applications;
CREATE POLICY driver_applications_select
  ON public.driver_applications FOR SELECT
  USING (
    public.is_admin()
    OR public.is_operator_admin_of(operator_id)
    OR applicant_id = auth.uid()
  );

DROP POLICY IF EXISTS driver_applications_insert ON public.driver_applications;
CREATE POLICY driver_applications_insert
  ON public.driver_applications FOR INSERT
  WITH CHECK (applicant_id = auth.uid());

DROP POLICY IF EXISTS driver_applications_update ON public.driver_applications;
CREATE POLICY driver_applications_update
  ON public.driver_applications FOR UPDATE
  USING (
    public.is_admin()
    OR public.is_operator_admin_of(operator_id)
  );

-- 7.4 stops: lectura pública (anon + auth), escritura solo admin/operator/driver.
-- (las políticas existentes no se tocan; añadimos un check para community).
-- Nota: si ya hay políticas de SELECT/INSERT/UPDATE en stops, esta migración
-- las respeta. Crear adicionales NO bloquea las anteriores.

DROP POLICY IF EXISTS stops_insert_community ON public.stops;
CREATE POLICY stops_insert_community
  ON public.stops FOR INSERT
  WITH CHECK (
    source = 'community' AND owner_id = auth.uid()
  );

-- ============================================================================
-- 8. Auto-update updated_at trigger en las tablas nuevas.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS TRIGGER
  LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS operator_route_proposals_updated_at ON public.operator_route_proposals;
CREATE TRIGGER operator_route_proposals_updated_at
  BEFORE UPDATE ON public.operator_route_proposals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS operator_applications_updated_at ON public.operator_applications;
CREATE TRIGGER operator_applications_updated_at
  BEFORE UPDATE ON public.operator_applications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS driver_applications_updated_at ON public.driver_applications;
CREATE TRIGGER driver_applications_updated_at
  BEFORE UPDATE ON public.driver_applications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMIT;

-- ============================================================================
-- Verificación post-migración (ejecutar manualmente para confirmar):
--
--   SELECT column_name FROM information_schema.columns
--     WHERE table_schema = 'public' AND table_name = 'operators';
--   -- Debe incluir: is_active, color
--
--   SELECT column_name FROM information_schema.columns
--     WHERE table_schema = 'public' AND table_name = 'stops';
--   -- Debe incluir: source, owner_id
--
--   SELECT tablename FROM pg_tables WHERE schemaname = 'public'
--     AND tablename IN ('operator_route_proposals', 'operator_applications',
--                        'driver_applications');
--   -- Debe devolver 3 filas.
--
-- ============================================================================
