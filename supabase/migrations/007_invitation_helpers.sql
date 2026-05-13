-- 007_invitation_helpers.sql
-- Funciones auxiliares para el flujo de códigos de invitación (F6).
-- `claim_invitation_code` ya existe en 005_functions.sql (F2.5).
-- Aquí añadimos `create_invitation_code` y `revoke_driver`.

-- ── create_invitation_code ────────────────────────────────────────
-- Genera un código de invitación para un operador y lo inserta en
-- invitation_codes. El código tiene formato XXX-XXXX-XX (3 letras
-- del slug del operador en mayúsculas, 4 alfanuméricos aleatorios,
-- 2 alfanuméricos más). Solo callable por operator_admin del
-- operador o admin.
CREATE OR REPLACE FUNCTION public.create_invitation_code(
  p_operator_id UUID,
  p_max_uses INT DEFAULT 1,
  p_expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
  p_kind invitation_kind DEFAULT 'driver'
) RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug TEXT;
  v_prefix TEXT;
  v_random_part TEXT;
  v_code TEXT;
  v_is_authorized BOOLEAN;
BEGIN
  -- Autorización: debe ser operator_admin del operador o admin.
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND (role = 'admin'
           OR (role = 'operator_admin'
               AND EXISTS (
                 SELECT 1 FROM driver_assignments
                 WHERE driver_id = auth.uid()
                   AND operator_id = p_operator_id
                   AND revoked_at IS NULL
               )))
  ) INTO v_is_authorized;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'No tienes permiso para crear códigos para este operador';
  END IF;

  -- Los admin pueden crear códigos de tipo operator_admin.
  IF p_kind = 'operator_admin' THEN
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
      RAISE EXCEPTION 'Solo los administradores pueden crear códigos de tipo operator_admin';
    END IF;
  END IF;

  -- Obtener slug del operador.
  SELECT slug INTO v_slug FROM operators WHERE id = p_operator_id;
  IF v_slug IS NULL THEN
    RAISE EXCEPTION 'Operador no encontrado';
  END IF;

  -- Prefijo: 3 primeras letras del slug en mayúsculas.
  v_prefix := UPPER(SUBSTRING(v_slug FROM 1 FOR 3));
  IF LENGTH(v_prefix) < 3 THEN
    v_prefix := RPAD(v_prefix, 3, 'X');
  END IF;

  -- Generar código único (hasta 10 intentos para evitar colisiones).
  FOR i IN 1..10 LOOP
    v_random_part := UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 6));
    v_code := v_prefix || '-' || SUBSTRING(v_random_part FROM 1 FOR 4) || '-' || SUBSTRING(v_random_part FROM 5 FOR 2);

    IF NOT EXISTS (SELECT 1 FROM invitation_codes WHERE code = v_code) THEN
      INSERT INTO invitation_codes (code, operator_id, kind, created_by, max_uses, expires_at)
      VALUES (v_code, p_operator_id, p_kind, auth.uid(), p_max_uses, p_expires_at);

      INSERT INTO audit_log (actor_id, action, target_kind, target_id, payload)
      VALUES (auth.uid(), 'create_invitation_code', 'invitation_code', v_code::UUID,
              jsonb_build_object('operator_id', p_operator_id, 'kind', p_kind, 'max_uses', p_max_uses));

      RETURN v_code;
    END IF;
  END LOOP;

  RAISE EXCEPTION 'No se pudo generar un código único tras 10 intentos';
END;
$$;

COMMENT ON FUNCTION public.create_invitation_code(UUID, INT, TIMESTAMPTZ, invitation_kind) IS
  'Genera un código de invitación formato XXX-XXXX-XX para un operador. Solo operator_admin del operador o admin.';

GRANT EXECUTE ON FUNCTION public.create_invitation_code(UUID, INT, TIMESTAMPTZ, invitation_kind) TO authenticated;

-- ── revoke_driver ──────────────────────────────────────────────────
-- Revoca una asignación de conductor. Si el driver no tiene ninguna
-- otra asignación activa, revierte su role a 'passenger'.
CREATE OR REPLACE FUNCTION public.revoke_driver(
  p_driver_id UUID,
  p_operator_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_is_authorized BOOLEAN;
  v_remaining_active INT;
BEGIN
  -- Autorización: operator_admin del operador o admin.
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND (role = 'admin'
           OR (role = 'operator_admin'
               AND EXISTS (
                 SELECT 1 FROM driver_assignments
                 WHERE driver_id = auth.uid()
                   AND operator_id = p_operator_id
                   AND revoked_at IS NULL
               )))
  ) INTO v_is_authorized;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'No tienes permiso para revocar conductores de este operador';
  END IF;

  -- Marcar como revocado.
  UPDATE driver_assignments
  SET revoked_at = NOW()
  WHERE driver_id = p_driver_id
    AND operator_id = p_operator_id
    AND revoked_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No se encontró una asignación activa para este conductor en este operador';
  END IF;

  -- Si no le quedan asignaciones activas, volver a passenger.
  SELECT COUNT(*) INTO v_remaining_active
  FROM driver_assignments
  WHERE driver_id = p_driver_id
    AND revoked_at IS NULL;

  IF v_remaining_active = 0 THEN
    UPDATE profiles SET role = 'passenger' WHERE id = p_driver_id;
  END IF;

  INSERT INTO audit_log (actor_id, action, target_kind, target_id, payload)
  VALUES (auth.uid(), 'revoke_driver', 'driver_assignment', p_driver_id,
          jsonb_build_object('operator_id', p_operator_id));
END;
$$;

COMMENT ON FUNCTION public.revoke_driver(UUID, UUID) IS
  'Revoca la asignación de un conductor a un operador. Si no le quedan asignaciones, revierte su role a passenger.';

GRANT EXECUTE ON FUNCTION public.revoke_driver(UUID, UUID) TO authenticated;
