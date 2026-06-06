-- =============================================================
-- 024_user_favorites.sql — B2: favoritos persistidos en BD
-- =============================================================
-- Sincroniza líneas y paradas favoritas entre dispositivos del
-- mismo usuario. Hive sigue siendo cache local/offline; esta
-- tabla es la fuente de verdad cuando hay sesión.
-- =============================================================

CREATE TABLE IF NOT EXISTS user_favorites (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('line', 'stop')),
  entity_id TEXT NOT NULL CHECK (char_length(entity_id) BETWEEN 1 AND 80),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, kind, entity_id)
);

CREATE INDEX IF NOT EXISTS user_favorites_user_kind_idx
  ON user_favorites(user_id, kind);

ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner reads own favorites" ON user_favorites;
CREATE POLICY "Owner reads own favorites" ON user_favorites
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Owner inserts own favorites" ON user_favorites;
CREATE POLICY "Owner inserts own favorites" ON user_favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Owner deletes own favorites" ON user_favorites;
CREATE POLICY "Owner deletes own favorites" ON user_favorites
  FOR DELETE USING (auth.uid() = user_id);
