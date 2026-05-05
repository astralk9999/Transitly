-- =============================================================
-- 001_init.sql — Schema inicial de Transitly
-- =============================================================
--
-- F2.2 del plan v2. Crea el grafo completo de tablas con PostGIS,
-- pgcrypto, todos los enums tipados, claves foráneas, índices
-- espaciales/secundarios y los triggers que rellenan profile +
-- user_preferences al darse de alta un usuario en auth.users.
--
-- Aplicación:
--   - CLI: supabase link --project-ref mmzahxtiaurkgtmtehxk
--          supabase db push
--   - SQL Editor: copia/pega el archivo entero en
--          https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/sql/new
--          y pulsa Run.
--
-- RLS se aplica en 002_rls.sql (F2.3). Esta migración deja todas
-- las tablas SIN políticas — necesario para que el bootstrap inicial
-- desde service_role funcione antes de aplicar la matriz de
-- permisos de F2.3.

-- =============================================================
-- 1. EXTENSIONES
-- =============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- =============================================================
-- 2. TIPOS ENUM
-- =============================================================
-- Notación mezclada (snake_case y camelCase) preservada del plan v2
-- §F2.2 — los valores camelCase mapean directamente con los enums
-- Dart de los modelos freezed (F1.2/F1.3) sin transformación.

CREATE TYPE user_role AS ENUM (
  'passenger', 'driver', 'operator_admin', 'moderator', 'admin'
);

CREATE TYPE route_source AS ENUM ('official', 'community');

CREATE TYPE route_status AS ENUM (
  'official', 'draft', 'pendingVerification', 'verified', 'suspended'
);

CREATE TYPE incident_kind AS ENUM (
  'delay', 'no_show', 'congestion', 'accident', 'other'
);

CREATE TYPE incident_status AS ENUM (
  'open', 'in_review', 'resolved', 'rejected'
);

CREATE TYPE feedback_kind AS ENUM (
  'stop_change', 'schedule_error', 'info_correction', 'other'
);

CREATE TYPE feedback_status AS ENUM (
  'open', 'in_review', 'applied', 'rejected'
);

CREATE TYPE feature_request_kind AS ENUM (
  'newRoute', 'routeOfficial', 'appFeature', 'dataCorrection', 'other'
);

CREATE TYPE feature_request_status AS ENUM (
  'open', 'inReview', 'accepted', 'rejected', 'scheduled', 'done'
);

CREATE TYPE suggestion_status AS ENUM (
  'open', 'considered', 'accepted', 'rejected'
);

CREATE TYPE share_permission AS ENUM ('view', 'edit');

CREATE TYPE bus_position_source AS ENUM (
  'gtfs_realtime', 'driver', 'estimated'
);

CREATE TYPE notification_type AS ENUM (
  'incident_resolved',
  'route_promoted',
  'share_received',
  'feature_request_replied',
  'bus_approaching_favorite',
  'custom'
);

CREATE TYPE color_blind_mode AS ENUM (
  'none', 'protanopia', 'deuteranopia', 'tritanopia'
);

CREATE TYPE invitation_kind AS ENUM ('driver', 'operator_admin');

CREATE TYPE gtfs_import_status AS ENUM (
  'queued', 'running', 'success', 'failed'
);

CREATE TYPE day_type AS ENUM ('weekday', 'saturday', 'sunday_holiday');

-- =============================================================
-- 3. TABLAS
-- =============================================================
-- Orden topológico: base → entidades referenciadas → entidades de
-- relación. profiles depende de auth.users (provista por Supabase).

-- ── Operadores (COMUJESA, TUSSAM, EMT Madrid, TMB, ...) ────────
CREATE TABLE operators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'ES',
  region TEXT,
  contact_email TEXT,
  website TEXT,
  gtfs_url TEXT,
  gtfs_realtime_url TEXT,
  bbox geometry(POLYGON, 4326),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_operators_bbox ON operators USING GIST (bbox);

-- ── Profiles (espeja auth.users) ───────────────────────────────
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'passenger',
  primary_zone_id UUID,
  reputation_score INT NOT NULL DEFAULT 0,
  reputation_level INT NOT NULL DEFAULT 0,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Asignaciones n:m profiles ↔ operators ──────────────────────
-- `active` GENERATED permite filtrar drivers vivos sin recalcular.
CREATE TABLE driver_assignments (
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  operator_id UUID REFERENCES operators(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES profiles(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  active BOOLEAN GENERATED ALWAYS AS (revoked_at IS NULL) STORED,
  PRIMARY KEY (driver_id, operator_id)
);
CREATE INDEX idx_driver_assignments_active
  ON driver_assignments (driver_id) WHERE revoked_at IS NULL;

-- ── Códigos de invitación de un solo uso ───────────────────────
CREATE TABLE invitation_codes (
  code TEXT PRIMARY KEY,
  operator_id UUID REFERENCES operators(id) ON DELETE CASCADE,
  kind invitation_kind NOT NULL DEFAULT 'driver',
  created_by UUID REFERENCES profiles(id),
  max_uses INT NOT NULL DEFAULT 1,
  uses INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Paradas ─────────────────────────────────────────────────────
CREATE TABLE stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  code TEXT,
  name TEXT NOT NULL,
  geom geometry(POINT, 4326) NOT NULL,
  accessibility JSONB NOT NULL DEFAULT '{}'::jsonb,
  gtfs_stop_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (operator_id, gtfs_stop_id)
);
CREATE INDEX idx_stops_geom ON stops USING GIST (geom);
CREATE INDEX idx_stops_operator ON stops (operator_id);

-- ── Rutas (oficiales y comunitarias en la misma tabla) ─────────
-- El CHECK reemplaza el "dual marker" descrito en ARCHITECTURE.md
-- §3 — `source` es la única fuente de verdad para distinguir.
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  source route_source NOT NULL,
  status route_status NOT NULL,
  code TEXT,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,                  -- hex con o sin # (validación en app)
  owner_id UUID REFERENCES profiles(id),
  gtfs_route_id TEXT,
  geom geometry(LINESTRING, 4326),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (operator_id, gtfs_route_id),
  CHECK (
    (source = 'official' AND owner_id IS NULL AND operator_id IS NOT NULL)
    OR (source = 'community')
  )
);
CREATE INDEX idx_routes_geom ON routes USING GIST (geom);
CREATE INDEX idx_routes_status ON routes (status, source);
CREATE INDEX idx_routes_owner ON routes (owner_id) WHERE source = 'community';

-- ── Paradas dentro de una ruta (orden y dirección) ─────────────
CREATE TABLE route_stops (
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  stop_id UUID REFERENCES stops(id) ON DELETE RESTRICT,
  sequence INT NOT NULL,
  direction SMALLINT NOT NULL DEFAULT 0,   -- 0=ida, 1=vuelta
  PRIMARY KEY (route_id, stop_id, direction, sequence)
);
CREATE INDEX idx_route_stops_route ON route_stops (route_id, direction, sequence);

-- ── Horarios ───────────────────────────────────────────────────
CREATE TABLE schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  day_type day_type NOT NULL,
  direction SMALLINT NOT NULL DEFAULT 0,
  departure_time TIME NOT NULL,
  arrival_offsets JSONB,                   -- [{stopId, deltaSeconds}, ...]
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_schedules_route ON schedules (route_id, day_type);

-- ── Posiciones de bus (live + estimadas + reportadas) ──────────
CREATE TABLE bus_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES profiles(id),
  source bus_position_source NOT NULL,
  geom geometry(POINT, 4326) NOT NULL,
  bearing REAL,
  speed_mps REAL,
  trip_id TEXT,                            -- correlación con GTFS-Realtime
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ                   -- limpieza automática
);
CREATE INDEX idx_bus_positions_route_recorded
  ON bus_positions (route_id, recorded_at DESC);
CREATE INDEX idx_bus_positions_geom ON bus_positions USING GIST (geom);
CREATE INDEX idx_bus_positions_expires
  ON bus_positions (expires_at) WHERE expires_at IS NOT NULL;

-- ── Incidentes ──────────────────────────────────────────────────
CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind incident_kind NOT NULL,
  status incident_status NOT NULL DEFAULT 'open',
  route_id UUID REFERENCES routes(id),
  stop_id UUID REFERENCES stops(id),
  description TEXT,
  geom geometry(POINT, 4326),
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
CREATE INDEX idx_incidents_status ON incidents (status, created_at DESC);
CREATE INDEX idx_incidents_route ON incidents (route_id) WHERE route_id IS NOT NULL;

-- ── Feedback de información (cambios de parada, errores horarios) ──
CREATE TABLE route_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id),
  stop_id UUID REFERENCES stops(id),
  kind feedback_kind NOT NULL,
  status feedback_status NOT NULL DEFAULT 'open',
  description TEXT NOT NULL,
  proposed_change JSONB,                   -- nueva posición, nuevo horario, etc.
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
CREATE INDEX idx_route_feedback_status ON route_feedback (status, created_at DESC);

-- ── Sugerencias de nuevas rutas ────────────────────────────────
CREATE TABLE route_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status suggestion_status NOT NULL DEFAULT 'open',
  origin_geom geometry(POINT, 4326) NOT NULL,
  destination_geom geometry(POINT, 4326) NOT NULL,
  motivation TEXT NOT NULL,
  desired_frequency TEXT,
  desired_operator_id UUID REFERENCES operators(id),
  votes INT NOT NULL DEFAULT 0,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_route_suggestions_origin ON route_suggestions USING GIST (origin_geom);
CREATE INDEX idx_route_suggestions_dest ON route_suggestions USING GIST (destination_geom);

-- Voto único por usuario+sugerencia.
CREATE TABLE route_suggestion_votes (
  suggestion_id UUID REFERENCES route_suggestions(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (suggestion_id, voter_id)
);

-- ── Solicitudes genéricas (FeatureRequest) ─────────────────────
-- Incluye "convertir mi ruta comunitaria en oficial", "nueva
-- feature de la app", correcciones de datos, etc.
CREATE TABLE feature_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind feature_request_kind NOT NULL,
  status feature_request_status NOT NULL DEFAULT 'open',
  priority TEXT NOT NULL DEFAULT 'normal',
  title TEXT NOT NULL,
  description TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Para kind='routeOfficial' payload incluye {route_id, justification}.
  votes INT NOT NULL DEFAULT 0,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
CREATE INDEX idx_feature_requests_status ON feature_requests (status, created_at DESC);

CREATE TABLE feature_request_votes (
  request_id UUID REFERENCES feature_requests(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (request_id, voter_id)
);

-- ── Compartir rutas ────────────────────────────────────────────
CREATE TABLE route_shares (
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  shared_with_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  shared_by_id UUID REFERENCES profiles(id),
  permission share_permission NOT NULL DEFAULT 'view',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  PRIMARY KEY (route_id, shared_with_id)
);

-- Enlaces públicos compartibles (slug corto).
CREATE TABLE route_public_links (
  slug TEXT PRIMARY KEY,
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  revoked BOOLEAN NOT NULL DEFAULT false
);
CREATE INDEX idx_route_public_links_route ON route_public_links (route_id);

-- ── Regiones offline ───────────────────────────────────────────
CREATE TABLE offline_regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  bounds geometry(POLYGON, 4326) NOT NULL,
  zoom_min SMALLINT NOT NULL DEFAULT 12,
  zoom_max SMALLINT NOT NULL DEFAULT 16,
  size_bytes BIGINT,
  status TEXT NOT NULL DEFAULT 'queued',
  downloaded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_offline_regions_user ON offline_regions (user_id);

-- ── Preferencias de usuario (apariencia + accesibilidad) ───────
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  theme_palette_id TEXT NOT NULL DEFAULT 'default',
  custom_colors JSONB,
  background_id TEXT,
  background_enabled BOOLEAN NOT NULL DEFAULT true,
  background_opacity REAL NOT NULL DEFAULT 1.0,
  font_scale REAL NOT NULL DEFAULT 1.0,
  color_blind_mode color_blind_mode NOT NULL DEFAULT 'none',
  dyslexia_font_enabled BOOLEAN NOT NULL DEFAULT false,
  reduce_motion BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Notificaciones in-app ──────────────────────────────────────
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user_unread
  ON notifications (user_id, created_at DESC) WHERE read = false;

-- ── Auditoría ──────────────────────────────────────────────────
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  target_kind TEXT,
  target_id UUID,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_actor_time ON audit_log (actor_id, created_at DESC);

-- ── Importaciones GTFS ─────────────────────────────────────────
CREATE TABLE gtfs_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  gtfs_url TEXT NOT NULL,
  status gtfs_import_status NOT NULL DEFAULT 'queued',
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  errors JSONB NOT NULL DEFAULT '[]'::jsonb,
  stats JSONB NOT NULL DEFAULT '{}'::jsonb,   -- {routes:n, stops:n, schedules:n}
  feed_version TEXT,
  triggered_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_gtfs_imports_operator_status ON gtfs_imports (operator_id, status);

-- ── GDPR ───────────────────────────────────────────────────────
CREATE TABLE privacy_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  consent_kind TEXT NOT NULL,                -- analytics | marketing | crash_reporting
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  policy_version TEXT NOT NULL
);
CREATE INDEX idx_privacy_consents_user ON privacy_consents (user_id);

CREATE TABLE data_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'queued',
  file_url TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE data_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'requested',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_at TIMESTAMPTZ,                  -- 30 días tras requested_at
  completed_at TIMESTAMPTZ
);

-- =============================================================
-- 4. TRIGGERS
-- =============================================================

-- Auto-crear profile + user_preferences al darse de alta.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, email_verified)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email_confirmed_at IS NOT NULL
  );
  INSERT INTO public.user_preferences (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- updated_at automático en mutaciones.
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_routes_touch BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_operators_touch BEFORE UPDATE ON operators
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_profiles_touch BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_user_prefs_touch BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Limpieza de bus_positions vencidas. Programar con pg_cron si está
-- habilitado en el plan de Supabase, o invocar desde una Edge Function
-- periódica (F2.5).
CREATE OR REPLACE FUNCTION cleanup_expired_bus_positions()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM bus_positions
  WHERE expires_at IS NOT NULL
    AND expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- =============================================================
-- 5. COMENTARIOS DE SCHEMA (autodocumentación inline)
-- =============================================================

COMMENT ON TABLE operators IS 'Operadores de transporte (público, comunitario, multi-país).';
COMMENT ON TABLE profiles IS 'Espejo público de auth.users con rol y reputación.';
COMMENT ON TABLE driver_assignments IS 'Vínculo n:m driver↔operador con revocación blanda vía revoked_at.';
COMMENT ON TABLE invitation_codes IS 'Códigos de un solo uso (típicamente XXX-XXXX-XX) generados por operadores.';
COMMENT ON TABLE routes IS 'Rutas oficiales y comunitarias en una misma tabla, distinguidas por source.';
COMMENT ON TABLE bus_positions IS 'Telemetría: GTFS-Realtime, driver en vivo, estimaciones. Limpieza periódica vía cleanup_expired_bus_positions().';
COMMENT ON COLUMN routes.color IS 'Hex con o sin # (validación en app, no en DB).';

-- =============================================================
-- Fin de 001_init.sql
-- =============================================================
