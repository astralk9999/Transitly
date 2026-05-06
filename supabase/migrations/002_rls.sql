-- =============================================================
-- 002_rls.sql — Row-Level Security
-- =============================================================
-- F2.3 del plan v2. Implementa la matriz de roles × permisos del
-- Anexo D del plan: passenger, driver, operator_admin, moderator,
-- admin. La política por defecto en TODAS las tablas de public es
-- DENY — cada operación requiere una policy explícita.
--
-- Convención:
--   - Policies nombradas <table>_<action>_<who_or_when>.
--   - Las funciones helper viven en public con SECURITY DEFINER y
--     NULL-safe: si auth.uid() es NULL, devuelven false en lugar de
--     fallar.
--   - Las inserciones que deben pasar SOLO por funciones SECURITY
--     DEFINER (driver_assignments, audit_log, notifications, etc.)
--     NO tienen policy INSERT — quedan denegadas para anon y
--     authenticated; service_role y SECURITY DEFINER las atraviesan.
--   - service_role bypasea RLS por defecto (no usamos FORCE RLS).
--
-- Para cada policy hay un COMMENT ON POLICY que documenta su intent.

-- =============================================================
-- 1. HELPERS de autorización
-- =============================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role = 'admin' FROM profiles WHERE id = auth.uid()),
    false
  );
$$;
COMMENT ON FUNCTION public.is_admin() IS
  'true si auth.uid() corresponde a un profile con role=admin.';

CREATE OR REPLACE FUNCTION public.is_moderator_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role IN ('moderator', 'admin') FROM profiles WHERE id = auth.uid()),
    false
  );
$$;
COMMENT ON FUNCTION public.is_moderator_or_admin() IS
  'true si auth.uid() corresponde a un profile con role IN (moderator, admin).';

CREATE OR REPLACE FUNCTION public.is_driver_of(p_operator_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM driver_assignments
    WHERE driver_id = auth.uid()
      AND operator_id = p_operator_id
      AND revoked_at IS NULL
  );
$$;
COMMENT ON FUNCTION public.is_driver_of(UUID) IS
  'true si auth.uid() tiene una driver_assignment activa con el operador.';

CREATE OR REPLACE FUNCTION public.is_operator_admin_of(p_operator_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role = 'operator_admin' FROM profiles WHERE id = auth.uid()),
    false
  ) AND EXISTS (
    SELECT 1 FROM driver_assignments
    WHERE driver_id = auth.uid()
      AND operator_id = p_operator_id
      AND revoked_at IS NULL
  );
$$;
COMMENT ON FUNCTION public.is_operator_admin_of(UUID) IS
  'true si auth.uid() es operator_admin Y tiene driver_assignment activa con ese operador.';

GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_moderator_or_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_driver_of(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_operator_admin_of(UUID) TO anon, authenticated;

-- =============================================================
-- 2. ENABLE RLS en TODAS las tablas de la migración 001
-- =============================================================

ALTER TABLE operators                ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_assignments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitation_codes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE stops                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops              ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules                ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_positions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents                ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_feedback           ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_suggestions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_suggestion_votes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_requests         ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_request_votes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_shares             ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_public_links       ENABLE ROW LEVEL SECURITY;
ALTER TABLE offline_regions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications            ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log                ENABLE ROW LEVEL SECURITY;
ALTER TABLE gtfs_imports             ENABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_consents         ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_exports             ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_deletion_requests   ENABLE ROW LEVEL SECURITY;

-- =============================================================
-- 3. POLICIES
-- =============================================================

-- ── operators ──────────────────────────────────────────────────
CREATE POLICY operators_select_public ON operators
  FOR SELECT USING (true);
COMMENT ON POLICY operators_select_public ON operators IS
  'Anónimo y autenticado leen todos los operadores (lista pública para mapa y picker).';

CREATE POLICY operators_insert_admin ON operators
  FOR INSERT TO authenticated WITH CHECK (is_admin());
COMMENT ON POLICY operators_insert_admin ON operators IS
  'Solo admin crea operadores.';

CREATE POLICY operators_update_admin ON operators
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());
COMMENT ON POLICY operators_update_admin ON operators IS
  'Solo admin actualiza operadores.';

CREATE POLICY operators_delete_admin ON operators
  FOR DELETE TO authenticated USING (is_admin());
COMMENT ON POLICY operators_delete_admin ON operators IS
  'Solo admin borra operadores.';

-- ── profiles ───────────────────────────────────────────────────
CREATE POLICY profiles_select_authenticated ON profiles
  FOR SELECT TO authenticated USING (true);
COMMENT ON POLICY profiles_select_authenticated ON profiles IS
  'Cualquier usuario autenticado lee profiles (display_name, role, reputación).';

CREATE POLICY profiles_update_self ON profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid() AND role = (SELECT role FROM profiles WHERE id = auth.uid()));
COMMENT ON POLICY profiles_update_self ON profiles IS
  'El usuario edita su propio perfil pero NO puede cambiar su role (solo admin/función SECURITY DEFINER).';

CREATE POLICY profiles_update_admin_mod ON profiles
  FOR UPDATE TO authenticated USING (is_moderator_or_admin())
  WITH CHECK (is_moderator_or_admin());
COMMENT ON POLICY profiles_update_admin_mod ON profiles IS
  'Admin y moderator actualizan cualquier profile (incluyendo role para promoción).';

-- ── driver_assignments ─────────────────────────────────────────
CREATE POLICY driver_assignments_select_self ON driver_assignments
  FOR SELECT TO authenticated USING (driver_id = auth.uid());
COMMENT ON POLICY driver_assignments_select_self ON driver_assignments IS
  'El driver lee sus asignaciones.';

CREATE POLICY driver_assignments_select_operator_admin ON driver_assignments
  FOR SELECT TO authenticated USING (is_operator_admin_of(operator_id));
COMMENT ON POLICY driver_assignments_select_operator_admin ON driver_assignments IS
  'operator_admin lee las asignaciones de su operador.';

CREATE POLICY driver_assignments_select_admin ON driver_assignments
  FOR SELECT TO authenticated USING (is_admin());
COMMENT ON POLICY driver_assignments_select_admin ON driver_assignments IS
  'admin lee todas las asignaciones.';

-- INSERT solo via claim_invitation_code() SECURITY DEFINER (F2.5).
-- No creamos policy INSERT — denegado para anon y authenticated.

CREATE POLICY driver_assignments_update_revoke_operator_admin ON driver_assignments
  FOR UPDATE TO authenticated
  USING (is_operator_admin_of(operator_id))
  WITH CHECK (is_operator_admin_of(operator_id));
COMMENT ON POLICY driver_assignments_update_revoke_operator_admin ON driver_assignments IS
  'operator_admin revoca asignaciones de su operador (set revoked_at).';

CREATE POLICY driver_assignments_update_admin ON driver_assignments
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());
COMMENT ON POLICY driver_assignments_update_admin ON driver_assignments IS
  'admin actualiza cualquier asignación.';

-- ── invitation_codes ───────────────────────────────────────────
CREATE POLICY invitation_codes_select_creator ON invitation_codes
  FOR SELECT TO authenticated USING (created_by = auth.uid());
COMMENT ON POLICY invitation_codes_select_creator ON invitation_codes IS
  'El creador del código lo ve.';

CREATE POLICY invitation_codes_select_operator_admin ON invitation_codes
  FOR SELECT TO authenticated USING (is_operator_admin_of(operator_id));
COMMENT ON POLICY invitation_codes_select_operator_admin ON invitation_codes IS
  'operator_admin lee los códigos de su operador.';

CREATE POLICY invitation_codes_select_admin ON invitation_codes
  FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY invitation_codes_insert_operator_admin ON invitation_codes
  FOR INSERT TO authenticated
  WITH CHECK (is_operator_admin_of(operator_id) AND created_by = auth.uid());
COMMENT ON POLICY invitation_codes_insert_operator_admin ON invitation_codes IS
  'operator_admin crea códigos para su operador, marcado como created_by sí mismo.';

CREATE POLICY invitation_codes_insert_admin ON invitation_codes
  FOR INSERT TO authenticated
  WITH CHECK (is_admin() AND created_by = auth.uid());

CREATE POLICY invitation_codes_delete_creator ON invitation_codes
  FOR DELETE TO authenticated USING (created_by = auth.uid());

CREATE POLICY invitation_codes_delete_admin ON invitation_codes
  FOR DELETE TO authenticated USING (is_admin());

-- ── stops ──────────────────────────────────────────────────────
CREATE POLICY stops_select_public ON stops
  FOR SELECT USING (true);
COMMENT ON POLICY stops_select_public ON stops IS
  'Paradas son datos públicos (mapa).';

CREATE POLICY stops_insert_authenticated ON stops
  FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);
COMMENT ON POLICY stops_insert_authenticated ON stops IS
  'Cualquier usuario autenticado puede crear paradas — comunitarias se flaggean en metadata.';

CREATE POLICY stops_update_admin_mod ON stops
  FOR UPDATE TO authenticated
  USING (is_moderator_or_admin()) WITH CHECK (is_moderator_or_admin());

CREATE POLICY stops_delete_admin_mod ON stops
  FOR DELETE TO authenticated USING (is_moderator_or_admin());

-- ── routes ─────────────────────────────────────────────────────
CREATE POLICY routes_select_visible ON routes
  FOR SELECT USING (
    source = 'official'
    OR (source = 'community' AND status = 'verified')
    OR (source = 'community' AND owner_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM route_shares rs
      WHERE rs.route_id = routes.id AND rs.shared_with_id = auth.uid()
    )
    OR is_moderator_or_admin()
  );
COMMENT ON POLICY routes_select_visible ON routes IS
  'Visibilidad pública: oficiales + community verified. Privadas: owner, shared_with, moderator/admin.';

CREATE POLICY routes_insert_community ON routes
  FOR INSERT TO authenticated
  WITH CHECK (
    source = 'community'
    AND owner_id = auth.uid()
    AND status IN ('draft', 'verified', 'pendingVerification')
  );
COMMENT ON POLICY routes_insert_community ON routes IS
  'Cualquier usuario autenticado crea ruta comunitaria propia. Status official requiere promote_route_to_official() (admin).';

CREATE POLICY routes_update_owner ON routes
  FOR UPDATE TO authenticated
  USING (
    source = 'community'
    AND owner_id = auth.uid()
    AND status NOT IN ('official', 'suspended')
  )
  WITH CHECK (
    source = 'community'
    AND owner_id = auth.uid()
    AND status NOT IN ('official', 'suspended')
  );
COMMENT ON POLICY routes_update_owner ON routes IS
  'El owner edita su ruta comunitaria salvo si ya es oficial o está suspendida.';

CREATE POLICY routes_update_operator_admin ON routes
  FOR UPDATE TO authenticated
  USING (source = 'official' AND is_operator_admin_of(operator_id))
  WITH CHECK (source = 'official' AND is_operator_admin_of(operator_id));
COMMENT ON POLICY routes_update_operator_admin ON routes IS
  'operator_admin edita rutas oficiales de su operador.';

CREATE POLICY routes_update_admin ON routes
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());
COMMENT ON POLICY routes_update_admin ON routes IS
  'admin actualiza cualquier ruta (promoción comunitaria → oficial vía promote_route_to_official).';

CREATE POLICY routes_delete_owner ON routes
  FOR DELETE TO authenticated
  USING (source = 'community' AND owner_id = auth.uid() AND status NOT IN ('official', 'suspended'));

CREATE POLICY routes_delete_admin ON routes
  FOR DELETE TO authenticated USING (is_admin());

-- ── route_stops ────────────────────────────────────────────────
-- Visibilidad y edición delegadas a la ruta padre.

CREATE POLICY route_stops_select ON route_stops
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = route_stops.route_id
      AND (
        r.source = 'official'
        OR (r.source = 'community' AND r.status = 'verified')
        OR (r.source = 'community' AND r.owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM route_shares rs WHERE rs.route_id = r.id AND rs.shared_with_id = auth.uid())
        OR is_moderator_or_admin()
      )
    )
  );

CREATE POLICY route_stops_write_owner ON route_stops
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = route_stops.route_id
      AND r.source = 'community' AND r.owner_id = auth.uid()
      AND r.status NOT IN ('official', 'suspended')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = route_stops.route_id
      AND r.source = 'community' AND r.owner_id = auth.uid()
      AND r.status NOT IN ('official', 'suspended')
    )
  );

CREATE POLICY route_stops_write_operator_admin ON route_stops
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = route_stops.route_id
      AND r.source = 'official' AND is_operator_admin_of(r.operator_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = route_stops.route_id
      AND r.source = 'official' AND is_operator_admin_of(r.operator_id)
    )
  );

CREATE POLICY route_stops_write_admin ON route_stops
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── schedules ──────────────────────────────────────────────────
CREATE POLICY schedules_select ON schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = schedules.route_id
      AND (
        r.source = 'official'
        OR (r.source = 'community' AND r.status = 'verified')
        OR (r.source = 'community' AND r.owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM route_shares rs WHERE rs.route_id = r.id AND rs.shared_with_id = auth.uid())
        OR is_moderator_or_admin()
      )
    )
  );

CREATE POLICY schedules_write_owner ON schedules
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = schedules.route_id
      AND r.source = 'community' AND r.owner_id = auth.uid()
      AND r.status NOT IN ('official', 'suspended')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = schedules.route_id
      AND r.source = 'community' AND r.owner_id = auth.uid()
      AND r.status NOT IN ('official', 'suspended')
    )
  );

CREATE POLICY schedules_write_operator_admin ON schedules
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = schedules.route_id
      AND r.source = 'official' AND is_operator_admin_of(r.operator_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM routes r WHERE r.id = schedules.route_id
      AND r.source = 'official' AND is_operator_admin_of(r.operator_id)
    )
  );

CREATE POLICY schedules_write_admin ON schedules
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── bus_positions ──────────────────────────────────────────────
CREATE POLICY bus_positions_select_public ON bus_positions
  FOR SELECT USING (true);
COMMENT ON POLICY bus_positions_select_public ON bus_positions IS
  'Telemetría es pública (anónimo lee buses para el mapa).';

CREATE POLICY bus_positions_insert_driver ON bus_positions
  FOR INSERT TO authenticated
  WITH CHECK (
    source = 'driver'
    AND driver_id = auth.uid()
    AND is_driver_of((SELECT operator_id FROM routes WHERE id = bus_positions.route_id))
  );
COMMENT ON POLICY bus_positions_insert_driver ON bus_positions IS
  'Solo un driver con asignación activa al operador de la ruta puede publicar posición con source=driver.';

-- INSERT con source='gtfs_realtime' o 'estimated' solo via service_role
-- desde Edge Functions — ninguna policy INSERT cubre esos casos.

CREATE POLICY bus_positions_delete_driver_self ON bus_positions
  FOR DELETE TO authenticated
  USING (source = 'driver' AND driver_id = auth.uid());

CREATE POLICY bus_positions_delete_admin ON bus_positions
  FOR DELETE TO authenticated USING (is_admin());

-- ── incidents ──────────────────────────────────────────────────
CREATE POLICY incidents_select_author ON incidents
  FOR SELECT TO authenticated USING (author_id = auth.uid());

CREATE POLICY incidents_select_mod_admin ON incidents
  FOR SELECT TO authenticated USING (is_moderator_or_admin());

CREATE POLICY incidents_insert_self ON incidents
  FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY incidents_update_author_open ON incidents
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND status = 'open')
  WITH CHECK (
    author_id = auth.uid()
    AND status = 'open'
    -- el autor no puede cambiar status, admin_notes, assignee_id desde este policy.
    -- Esos campos quedan stable porque ya status='open' está en el USING.
  );
COMMENT ON POLICY incidents_update_author_open ON incidents IS
  'El autor edita su incident solo mientras siga open.';

CREATE POLICY incidents_update_mod_admin ON incidents
  FOR UPDATE TO authenticated
  USING (is_moderator_or_admin()) WITH CHECK (is_moderator_or_admin());
COMMENT ON POLICY incidents_update_mod_admin ON incidents IS
  'moderator/admin actualizan cualquier incident — typical: cambiar status, asignar assignee, escribir admin_notes.';

CREATE POLICY incidents_delete_admin ON incidents
  FOR DELETE TO authenticated USING (is_admin());

-- ── route_feedback ─────────────────────────────────────────────
CREATE POLICY route_feedback_select_author ON route_feedback
  FOR SELECT TO authenticated USING (author_id = auth.uid());

CREATE POLICY route_feedback_select_mod_admin ON route_feedback
  FOR SELECT TO authenticated USING (is_moderator_or_admin());

CREATE POLICY route_feedback_insert_self ON route_feedback
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());

CREATE POLICY route_feedback_update_author_open ON route_feedback
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND status = 'open')
  WITH CHECK (author_id = auth.uid() AND status = 'open');

CREATE POLICY route_feedback_update_mod_admin ON route_feedback
  FOR UPDATE TO authenticated
  USING (is_moderator_or_admin()) WITH CHECK (is_moderator_or_admin());

CREATE POLICY route_feedback_delete_admin ON route_feedback
  FOR DELETE TO authenticated USING (is_admin());

-- ── route_suggestions ──────────────────────────────────────────
CREATE POLICY route_suggestions_select_author ON route_suggestions
  FOR SELECT TO authenticated USING (author_id = auth.uid());

CREATE POLICY route_suggestions_select_mod_admin ON route_suggestions
  FOR SELECT TO authenticated USING (is_moderator_or_admin());

CREATE POLICY route_suggestions_insert_self ON route_suggestions
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());

CREATE POLICY route_suggestions_update_author_open ON route_suggestions
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND status = 'open')
  WITH CHECK (author_id = auth.uid() AND status = 'open');

CREATE POLICY route_suggestions_update_mod_admin ON route_suggestions
  FOR UPDATE TO authenticated
  USING (is_moderator_or_admin()) WITH CHECK (is_moderator_or_admin());

CREATE POLICY route_suggestions_delete_admin ON route_suggestions
  FOR DELETE TO authenticated USING (is_admin());

-- ── route_suggestion_votes ─────────────────────────────────────
CREATE POLICY route_suggestion_votes_select_public ON route_suggestion_votes
  FOR SELECT USING (true);
COMMENT ON POLICY route_suggestion_votes_select_public ON route_suggestion_votes IS
  'Conteo de votos visible para cualquiera — necesario para mostrar ranking.';

CREATE POLICY route_suggestion_votes_insert_self ON route_suggestion_votes
  FOR INSERT TO authenticated WITH CHECK (voter_id = auth.uid());

CREATE POLICY route_suggestion_votes_delete_self ON route_suggestion_votes
  FOR DELETE TO authenticated USING (voter_id = auth.uid());

-- ── feature_requests ───────────────────────────────────────────
CREATE POLICY feature_requests_select_author ON feature_requests
  FOR SELECT TO authenticated USING (author_id = auth.uid());

CREATE POLICY feature_requests_select_mod_admin ON feature_requests
  FOR SELECT TO authenticated USING (is_moderator_or_admin());

CREATE POLICY feature_requests_insert_self ON feature_requests
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());

CREATE POLICY feature_requests_update_author_open ON feature_requests
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND status = 'open')
  WITH CHECK (author_id = auth.uid() AND status = 'open');

CREATE POLICY feature_requests_update_mod_admin ON feature_requests
  FOR UPDATE TO authenticated
  USING (is_moderator_or_admin()) WITH CHECK (is_moderator_or_admin());

CREATE POLICY feature_requests_delete_admin ON feature_requests
  FOR DELETE TO authenticated USING (is_admin());

-- ── feature_request_votes ──────────────────────────────────────
CREATE POLICY feature_request_votes_select_public ON feature_request_votes
  FOR SELECT USING (true);

CREATE POLICY feature_request_votes_insert_self ON feature_request_votes
  FOR INSERT TO authenticated WITH CHECK (voter_id = auth.uid());

CREATE POLICY feature_request_votes_delete_self ON feature_request_votes
  FOR DELETE TO authenticated USING (voter_id = auth.uid());

-- ── route_shares ───────────────────────────────────────────────
CREATE POLICY route_shares_select_owner ON route_shares
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM routes r WHERE r.id = route_shares.route_id AND r.owner_id = auth.uid())
  );
COMMENT ON POLICY route_shares_select_owner ON route_shares IS
  'El owner de la ruta ve a quién la ha compartido.';

CREATE POLICY route_shares_select_recipient ON route_shares
  FOR SELECT TO authenticated USING (shared_with_id = auth.uid());
COMMENT ON POLICY route_shares_select_recipient ON route_shares IS
  'El destinatario ve los shares en los que está incluido.';

CREATE POLICY route_shares_select_admin ON route_shares
  FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY route_shares_insert_owner ON route_shares
  FOR INSERT TO authenticated
  WITH CHECK (
    shared_by_id = auth.uid()
    AND EXISTS (SELECT 1 FROM routes r WHERE r.id = route_shares.route_id AND r.owner_id = auth.uid())
  );
COMMENT ON POLICY route_shares_insert_owner ON route_shares IS
  'Solo el owner de la ruta puede crear un share.';

CREATE POLICY route_shares_delete_owner ON route_shares
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM routes r WHERE r.id = route_shares.route_id AND r.owner_id = auth.uid()));

CREATE POLICY route_shares_delete_recipient ON route_shares
  FOR DELETE TO authenticated USING (shared_with_id = auth.uid());
COMMENT ON POLICY route_shares_delete_recipient ON route_shares IS
  'El destinatario puede salirse del share borrando su fila.';

CREATE POLICY route_shares_delete_admin ON route_shares
  FOR DELETE TO authenticated USING (is_admin());

-- ── route_public_links ─────────────────────────────────────────
CREATE POLICY route_public_links_select_public ON route_public_links
  FOR SELECT USING (revoked = false);
COMMENT ON POLICY route_public_links_select_public ON route_public_links IS
  'Anónimo y autenticado resuelven slugs no revocados.';

CREATE POLICY route_public_links_insert_creator ON route_public_links
  FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());

CREATE POLICY route_public_links_update_creator ON route_public_links
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

CREATE POLICY route_public_links_delete_creator ON route_public_links
  FOR DELETE TO authenticated USING (created_by = auth.uid());

CREATE POLICY route_public_links_all_admin ON route_public_links
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── offline_regions ────────────────────────────────────────────
CREATE POLICY offline_regions_self ON offline_regions
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
COMMENT ON POLICY offline_regions_self ON offline_regions IS
  'Cada usuario gestiona solo sus propias regiones offline.';

-- ── user_preferences ───────────────────────────────────────────
CREATE POLICY user_preferences_self ON user_preferences
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
COMMENT ON POLICY user_preferences_self ON user_preferences IS
  'Cada usuario lee/escribe solo sus preferencias. Inserción inicial via trigger handle_new_user (SECURITY DEFINER).';

-- ── notifications ──────────────────────────────────────────────
CREATE POLICY notifications_select_recipient ON notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY notifications_update_recipient ON notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
COMMENT ON POLICY notifications_update_recipient ON notifications IS
  'El destinatario marca como read=true. INSERT está reservado a Edge Functions/triggers (service_role).';

CREATE POLICY notifications_delete_recipient ON notifications
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- INSERT: solo via service_role / SECURITY DEFINER. No policy INSERT.

-- ── audit_log ──────────────────────────────────────────────────
CREATE POLICY audit_log_select_admin ON audit_log
  FOR SELECT TO authenticated USING (is_admin());
COMMENT ON POLICY audit_log_select_admin ON audit_log IS
  'Solo admin lee la pista de auditoría.';

-- INSERT: solo via SECURITY DEFINER (claim_invitation_code,
-- promote_route_to_official, etc.). No policy INSERT.

-- ── gtfs_imports ───────────────────────────────────────────────
CREATE POLICY gtfs_imports_select_admin ON gtfs_imports
  FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY gtfs_imports_select_operator_admin ON gtfs_imports
  FOR SELECT TO authenticated USING (is_operator_admin_of(operator_id));

CREATE POLICY gtfs_imports_insert_admin ON gtfs_imports
  FOR INSERT TO authenticated
  WITH CHECK (is_admin() AND triggered_by = auth.uid());

CREATE POLICY gtfs_imports_insert_operator_admin ON gtfs_imports
  FOR INSERT TO authenticated
  WITH CHECK (is_operator_admin_of(operator_id) AND triggered_by = auth.uid());

CREATE POLICY gtfs_imports_update_admin ON gtfs_imports
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- Edge Functions con service_role bypassean RLS para escribir status/stats.

-- ── privacy_consents ───────────────────────────────────────────
CREATE POLICY privacy_consents_self ON privacy_consents
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY privacy_consents_select_admin ON privacy_consents
  FOR SELECT TO authenticated USING (is_admin());
COMMENT ON POLICY privacy_consents_select_admin ON privacy_consents IS
  'admin lee consentimientos para cumplimiento GDPR (auditoría).';

-- ── data_exports ───────────────────────────────────────────────
CREATE POLICY data_exports_self ON data_exports
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── data_deletion_requests ─────────────────────────────────────
CREATE POLICY data_deletion_requests_self_select ON data_deletion_requests
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY data_deletion_requests_self_insert ON data_deletion_requests
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY data_deletion_requests_select_admin ON data_deletion_requests
  FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY data_deletion_requests_update_admin ON data_deletion_requests
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- =============================================================
-- Fin de 002_rls.sql
-- =============================================================
