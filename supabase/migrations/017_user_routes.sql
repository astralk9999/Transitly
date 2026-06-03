-- =============================================================
-- 017_user_routes.sql — Sistema user_routes (V14)
-- =============================================================
-- Tablas para rutas creadas por usuarios, paradas custom,
-- horarios, votos, reportes y analíticas.
-- Adaptado al schema existente: profiles.reputation_score como XP.
-- =============================================================

-- Extender profiles con routes_created_count
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  routes_created_count INT NOT NULL DEFAULT 0;

-- =============================================================
-- 1) USER STOPS (paradas custom — FK a user_routes es 3)
-- =============================================================
CREATE TABLE IF NOT EXISTS user_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  official_stop_id UUID REFERENCES stops(id),
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 80),
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  stop_type TEXT NOT NULL DEFAULT 'custom' CHECK (stop_type IN (
    'official', 'urban_custom', 'hotel', 'motel', 'gas_station',
    'rest_area', 'beach', 'airport', 'train_station', 'ferry',
    'landmark', 'custom'
  )),
  description TEXT,
  promotion_status TEXT DEFAULT 'none' CHECK (promotion_status IN (
    'none', 'requested', 'approved', 'rejected'
  )),
  promoted_to_official_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_stops_author_idx ON user_stops(author_id);
CREATE INDEX IF NOT EXISTS user_stops_geom_idx ON user_stops(lat, lng);
CREATE INDEX IF NOT EXISTS user_stops_promotion_idx ON user_stops(promotion_status)
  WHERE promotion_status = 'requested';

-- =============================================================
-- 2) USER ROUTES
-- =============================================================
CREATE TABLE IF NOT EXISTS user_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 3 AND 80),
  description TEXT CHECK (char_length(description) <= 500),
  route_color TEXT NOT NULL DEFAULT '#977DDF',
  service_type TEXT NOT NULL CHECK (service_type IN (
    'urban', 'interurban', 'long_distance', 'school', 'on_demand', 'custom'
  )),
  visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN (
    'public', 'unlisted', 'private'
  )),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'published', 'review_pending',
    'community_approved', 'rejected', 'reported'
  )),
  share_code TEXT UNIQUE,
  public_slug TEXT UNIQUE,
  total_distance_km NUMERIC(7,2),
  total_duration_min INT,
  view_count INT NOT NULL DEFAULT 0,
  vote_count INT NOT NULL DEFAULT 0,
  report_count INT NOT NULL DEFAULT 0,
  country_code CHAR(2) DEFAULT 'ES',
  region TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS user_routes_author_idx ON user_routes(author_id);
CREATE INDEX IF NOT EXISTS user_routes_vis_status_idx
  ON user_routes(visibility, status) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS user_routes_share_code_idx ON user_routes(share_code);
CREATE INDEX IF NOT EXISTS user_routes_public_slug_idx ON user_routes(public_slug);

-- Full-text search en español
ALTER TABLE user_routes ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS user_routes_search_idx ON user_routes USING GIN(search_vector);

-- Trigger para mantener search_vector
CREATE OR REPLACE FUNCTION user_routes_search_update() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('spanish', coalesce(NEW.name, '') || ' ' || coalesce(NEW.description, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_routes_search ON user_routes;
CREATE TRIGGER trg_user_routes_search
  BEFORE INSERT OR UPDATE OF name, description ON user_routes
  FOR EACH ROW EXECUTE FUNCTION user_routes_search_update();

-- =============================================================
-- 3) USER ROUTE STOPS (pivote)
-- =============================================================
CREATE TABLE IF NOT EXISTS user_route_stops (
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  user_stop_id UUID NOT NULL REFERENCES user_stops(id) ON DELETE CASCADE,
  order_index SMALLINT NOT NULL CHECK (order_index >= 0),
  duration_to_next_min INT,
  distance_to_next_km NUMERIC(6,2),
  PRIMARY KEY (route_id, order_index)
);

CREATE INDEX IF NOT EXISTS user_route_stops_route_idx ON user_route_stops(route_id);
CREATE INDEX IF NOT EXISTS user_route_stops_stop_idx ON user_route_stops(user_stop_id);

-- =============================================================
-- 4) USER ROUTE SCHEDULES
-- =============================================================
CREATE TABLE IF NOT EXISTS user_route_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  day_type TEXT NOT NULL CHECK (day_type IN (
    'weekday', 'saturday', 'sunday', 'holiday',
    'summer', 'winter', 'every_day'
  )),
  departure_time TIME NOT NULL,
  origin_stop_id UUID REFERENCES user_stops(id),
  notes TEXT
);

CREATE INDEX IF NOT EXISTS user_route_schedules_route_idx ON user_route_schedules(route_id);

-- =============================================================
-- 5) USER ROUTE VOTES
-- =============================================================
CREATE TABLE IF NOT EXISTS user_route_votes (
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (route_id, voter_id)
);

-- =============================================================
-- 6) USER ROUTE REPORTS
-- =============================================================
CREATE TABLE IF NOT EXISTS user_route_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN (
    'spam', 'inappropriate', 'wrong_data', 'duplicated', 'other'
  )),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 7) USER ROUTE VIEWS (analytics)
-- =============================================================
CREATE TABLE IF NOT EXISTS user_route_views (
  id BIGSERIAL PRIMARY KEY,
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  via_share_code BOOLEAN DEFAULT FALSE,
  via_public_link BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS user_route_views_route_date_idx
  ON user_route_views(route_id, viewed_at DESC);

-- =============================================================
-- FUNCIONES
-- =============================================================

-- Cuota de rutas según nivel
CREATE OR REPLACE FUNCTION user_routes_quota(p_user_id UUID) RETURNS INT AS $$
  SELECT CASE reputation_level
    WHEN 0 THEN 1
    WHEN 1 THEN 3
    WHEN 2 THEN 10
    WHEN 3 THEN 30
    WHEN 4 THEN 100
    WHEN 5 THEN 200
    WHEN 6 THEN 500
    ELSE 1
  END FROM profiles WHERE id = p_user_id;
$$ LANGUAGE SQL STABLE;

-- Generador de share_code (6 chars, sin O,0,I,1,L)
CREATE OR REPLACE FUNCTION generate_share_code() RETURNS TEXT AS $$
DECLARE
  alphabet TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code TEXT;
  attempts INT := 0;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..6 LOOP
      code := code || substr(alphabet, floor(random() * 30)::int + 1, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM user_routes WHERE share_code = code);
    attempts := attempts + 1;
    IF attempts > 50 THEN
      RAISE EXCEPTION 'unable to generate share_code';
    END IF;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Generador de public_slug (9 bytes base64 → 12 chars, url-safe)
CREATE OR REPLACE FUNCTION generate_public_slug() RETURNS TEXT AS $$
  SELECT substr(replace(replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''), ' ', ''), 1, 12)
$$ LANGUAGE SQL VOLATILE;

-- Trigger BEFORE INSERT: verifica cuota + genera códigos
CREATE OR REPLACE FUNCTION check_user_routes_quota() RETURNS TRIGGER AS $$
DECLARE
  current_count INT;
  quota INT;
BEGIN
  SELECT routes_created_count INTO current_count FROM profiles WHERE id = NEW.author_id;
  SELECT user_routes_quota(NEW.author_id) INTO quota;
  IF current_count >= quota AND NEW.status NOT IN ('draft') THEN
    RAISE EXCEPTION 'route quota exceeded: %. Sube de nivel para crear más rutas.', current_count;
  END IF;
  IF NEW.share_code IS NULL THEN
    NEW.share_code := generate_share_code();
  END IF;
  IF NEW.public_slug IS NULL THEN
    NEW.public_slug := generate_public_slug();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_routes_quota ON user_routes;
CREATE TRIGGER trg_user_routes_quota
  BEFORE INSERT ON user_routes
  FOR EACH ROW EXECUTE FUNCTION check_user_routes_quota();

-- Trigger AFTER INSERT: sube routes_created_count
CREATE OR REPLACE FUNCTION inc_routes_created_count() RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET routes_created_count = routes_created_count + 1
    WHERE id = NEW.author_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_routes_count_inc ON user_routes;
CREATE TRIGGER trg_user_routes_count_inc
  AFTER INSERT ON user_routes
  FOR EACH ROW EXECUTE FUNCTION inc_routes_created_count();

-- XP por acciones (usa reputation_score existente)
CREATE OR REPLACE FUNCTION add_xp(p_user_id UUID, p_xp INT) RETURNS VOID AS $$
DECLARE
  new_score INT;
  new_level INT;
BEGIN
  UPDATE profiles SET reputation_score = reputation_score + p_xp
    WHERE id = p_user_id
    RETURNING reputation_score INTO new_score;

  new_level := CASE
    WHEN new_score >= 5000 THEN 6
    WHEN new_score >= 1500 THEN 5
    WHEN new_score >= 500  THEN 4
    WHEN new_score >= 200  THEN 3
    WHEN new_score >= 50   THEN 2
    WHEN new_score >= 10   THEN 1
    ELSE 0
  END;

  UPDATE profiles SET reputation_level = new_level WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger: auto add_xp al publicar ruta (+10)
CREATE OR REPLACE FUNCTION trg_route_published_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'published' AND OLD.status = 'draft' THEN
    PERFORM add_xp(NEW.author_id, 10);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_route_published_xp ON user_routes;
CREATE TRIGGER trg_route_published_xp
  AFTER UPDATE OF status ON user_routes
  FOR EACH ROW EXECUTE FUNCTION trg_route_published_xp();

-- Trigger: auto add_xp al votar (+1 al autor)
CREATE OR REPLACE FUNCTION trg_route_vote_xp() RETURNS TRIGGER AS $$
BEGIN
  -- XP al autor de la ruta
  PERFORM add_xp(
    (SELECT author_id FROM user_routes WHERE id = NEW.route_id), 1
  );
  -- Incrementar vote_count
  UPDATE user_routes SET vote_count = vote_count + 1 WHERE id = NEW.route_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_route_vote_xp ON user_route_votes;
CREATE TRIGGER trg_route_vote_xp
  AFTER INSERT ON user_route_votes
  FOR EACH ROW EXECUTE FUNCTION trg_route_vote_xp();

-- =============================================================
-- RLS POLICIES
-- =============================================================

ALTER TABLE user_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_views ENABLE ROW LEVEL SECURITY;

-- Helper: is current user an admin
CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role IN ('admin', 'moderator')
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- USER ROUTES

DROP POLICY IF EXISTS "Owner sees own routes" ON user_routes;
CREATE POLICY "Owner sees own routes" ON user_routes
  FOR SELECT USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Public routes visible to all" ON user_routes;
CREATE POLICY "Public routes visible to all" ON user_routes
  FOR SELECT USING (
    visibility = 'public' AND status IN ('published', 'community_approved')
  );

DROP POLICY IF EXISTS "Admin sees all routes" ON user_routes;
CREATE POLICY "Admin sees all routes" ON user_routes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'moderator'))
  );

DROP POLICY IF EXISTS "Owner inserts" ON user_routes;
CREATE POLICY "Owner inserts" ON user_routes
  FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Owner updates own" ON user_routes;
CREATE POLICY "Owner updates own" ON user_routes
  FOR UPDATE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Admin updates any route" ON user_routes;
CREATE POLICY "Admin updates any route" ON user_routes
  FOR UPDATE USING (is_admin());

DROP POLICY IF EXISTS "Owner deletes own" ON user_routes;
CREATE POLICY "Owner deletes own" ON user_routes
  FOR DELETE USING (auth.uid() = author_id);

-- USER STOPS

DROP POLICY IF EXISTS "Stops visible if in visible route" ON user_stops;
CREATE POLICY "Stops visible if in visible route" ON user_stops
  FOR SELECT USING (
    auth.uid() = author_id
    OR EXISTS (
      SELECT 1 FROM user_route_stops urs
      JOIN user_routes ur ON ur.id = urs.route_id
      WHERE urs.user_stop_id = user_stops.id
      AND (
        ur.visibility = 'public'
        OR ur.author_id = auth.uid()
        OR is_admin()
      )
      AND ur.status IN ('published', 'community_approved', 'review_pending')
    )
    OR is_admin()
  );

DROP POLICY IF EXISTS "Owner inserts stops" ON user_stops;
CREATE POLICY "Owner inserts stops" ON user_stops
  FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Owner updates own stops" ON user_stops;
CREATE POLICY "Owner updates own stops" ON user_stops
  FOR UPDATE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Admin updates any stop" ON user_stops;
CREATE POLICY "Admin updates any stop" ON user_stops
  FOR UPDATE USING (is_admin());

DROP POLICY IF EXISTS "Owner deletes own stops" ON user_stops;
CREATE POLICY "Owner deletes own stops" ON user_stops
  FOR DELETE USING (auth.uid() = author_id);

-- USER ROUTE STOPS

DROP POLICY IF EXISTS "Route stops visible with route" ON user_route_stops;
CREATE POLICY "Route stops visible with route" ON user_route_stops
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id
      AND (
        ur.author_id = auth.uid()
        OR ur.visibility = 'public'
        OR is_admin()
      )
    )
  );

DROP POLICY IF EXISTS "Route owner manages stops" ON user_route_stops;
CREATE POLICY "Route owner manages stops" ON user_route_stops
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND ur.author_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Route owner deletes stops" ON user_route_stops;
CREATE POLICY "Route owner deletes stops" ON user_route_stops
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND ur.author_id = auth.uid()
    )
  );

-- USER ROUTE SCHEDULES

DROP POLICY IF EXISTS "Schedules visible with route" ON user_route_schedules;
CREATE POLICY "Schedules visible with route" ON user_route_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id
      AND (
        ur.author_id = auth.uid()
        OR ur.visibility = 'public'
        OR is_admin()
      )
    )
  );

DROP POLICY IF EXISTS "Route owner manages schedules" ON user_route_schedules;
CREATE POLICY "Route owner manages schedules" ON user_route_schedules
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND ur.author_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Route owner updates schedules" ON user_route_schedules;
CREATE POLICY "Route owner updates schedules" ON user_route_schedules
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND ur.author_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Route owner deletes schedules" ON user_route_schedules;
CREATE POLICY "Route owner deletes schedules" ON user_route_schedules
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND ur.author_id = auth.uid()
    )
  );

-- USER ROUTE VOTES

DROP POLICY IF EXISTS "Votes visible to all" ON user_route_votes;
CREATE POLICY "Votes visible to all" ON user_route_votes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can vote" ON user_route_votes;
CREATE POLICY "Authenticated users can vote" ON user_route_votes
  FOR INSERT WITH CHECK (auth.uid() = voter_id);

DROP POLICY IF EXISTS "Users can remove own votes" ON user_route_votes;
CREATE POLICY "Users can remove own votes" ON user_route_votes
  FOR DELETE USING (auth.uid() = voter_id);

-- USER ROUTE REPORTS

DROP POLICY IF EXISTS "Users see own reports" ON user_route_reports;
CREATE POLICY "Users see own reports" ON user_route_reports
  FOR SELECT USING (reporter_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Authenticated users can report" ON user_route_reports;
CREATE POLICY "Authenticated users can report" ON user_route_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Admin manages reports" ON user_route_reports;
CREATE POLICY "Admin manages reports" ON user_route_reports
  FOR UPDATE USING (is_admin());

-- USER ROUTE VIEWS

DROP POLICY IF EXISTS "Views visible to route author and admin" ON user_route_views;
CREATE POLICY "Views visible to route author and admin" ON user_route_views
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_routes ur
      WHERE ur.id = route_id AND (ur.author_id = auth.uid() OR is_admin())
    )
    OR is_admin()
  );

DROP POLICY IF EXISTS "Any user can register view" ON user_route_views;
CREATE POLICY "Any user can register view" ON user_route_views
  FOR INSERT WITH CHECK (true);
