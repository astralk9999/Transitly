-- 029_admin_ban_users.sql — ban + soft-delete admin panel
--
-- Añade columnas a profiles para que el admin pueda banear sin
-- eliminar el registro. Un usuario baneado mantiene su perfil pero
-- queda bloqueado para acciones (auth puede seguir, las RLS de
-- otras tablas filtran por banned).

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS banned_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS ban_reason TEXT;

-- Helper para marcar baneado/desbaneado de forma atómica.
CREATE OR REPLACE FUNCTION admin_set_ban(
  p_user_id UUID,
  p_banned BOOLEAN,
  p_reason TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Solo admins pueden banear';
  END IF;
  UPDATE profiles SET
    is_banned = p_banned,
    banned_at = CASE WHEN p_banned THEN NOW() ELSE NULL END,
    banned_by = CASE WHEN p_banned THEN auth.uid() ELSE NULL END,
    ban_reason = CASE WHEN p_banned THEN p_reason ELSE NULL END
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin_set_ban(UUID, BOOLEAN, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_set_ban(UUID, BOOLEAN, TEXT) TO authenticated;

-- Operadora por defecto del TFG (Jerez). Idempotente.
INSERT INTO operators (id, slug, name, country, region, is_active, color)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'comujesa',
  'COMUJESA',
  'ES',
  'Jerez de la Frontera',
  true,
  '#977DDF'
)
ON CONFLICT (id) DO NOTHING;
