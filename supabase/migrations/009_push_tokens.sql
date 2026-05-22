-- =============================================================
-- 014_push_tokens.sql — device_tokens table for push notifications
-- =============================================================
-- F21. Almacena tokens FCM por usuario para envío de push
-- notifications desde el backend.

CREATE TABLE IF NOT EXISTS device_tokens (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'unknown',
  app_version TEXT,
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY device_tokens_self ON device_tokens
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
