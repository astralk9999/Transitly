-- ============================================================================
-- 022_invitation_helpers.sql
-- P1.5-05 — RPC `create_invitation_code` para que operator_admin / admin
-- puedan generar códigos desde la app.
--
-- Formato del código: XXX-XXXX-XX (alfanumérico mayúsculas + dígitos, sin
-- caracteres ambiguos 0/O/1/I/L para evitar confusión al teclearlos).
-- Idempotente: ejecutable múltiples veces.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.generate_invitation_code_string()
  RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  alphabet TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';  -- sin 0/O/1/I/L
  result TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..3 LOOP
    result := result || substr(alphabet, (random() * length(alphabet))::int + 1, 1);
  END LOOP;
  result := result || '-';
  FOR i IN 1..4 LOOP
    result := result || substr(alphabet, (random() * length(alphabet))::int + 1, 1);
  END LOOP;
  result := result || '-';
  FOR i IN 1..2 LOOP
    result := result || substr(alphabet, (random() * length(alphabet))::int + 1, 1);
  END LOOP;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_invitation_code(
  p_operator_id UUID,
  p_max_uses INT DEFAULT 1,
  p_expires_days INT DEFAULT 30,
  p_kind TEXT DEFAULT 'driver'
) RETURNS TEXT
  LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_code TEXT;
  v_kind public.invitation_kind;
  v_uid UUID := auth.uid();
  v_attempts INT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Permission check: admin o operator_admin del operador.
  IF NOT (
    public.is_admin()
    OR public.is_operator_admin_of(p_operator_id)
  ) THEN
    RAISE EXCEPTION 'Forbidden: not admin nor operator_admin of %', p_operator_id;
  END IF;

  v_kind := p_kind::public.invitation_kind;

  IF p_max_uses < 1 OR p_max_uses > 1000 THEN
    RAISE EXCEPTION 'p_max_uses must be between 1 and 1000';
  END IF;

  -- Loop para evitar colisiones (probabilidad despreciable pero por si acaso).
  LOOP
    v_code := public.generate_invitation_code_string();
    BEGIN
      INSERT INTO public.invitation_codes (
        code, operator_id, kind, created_by, max_uses, uses, expires_at
      ) VALUES (
        v_code,
        p_operator_id,
        v_kind,
        v_uid,
        p_max_uses,
        0,
        CASE WHEN p_expires_days > 0 THEN NOW() + (p_expires_days || ' days')::INTERVAL
             ELSE NULL END
      );
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      v_attempts := v_attempts + 1;
      IF v_attempts >= 5 THEN
        RAISE EXCEPTION 'Could not generate unique code after 5 attempts';
      END IF;
    END;
  END LOOP;

  RETURN v_code;
END;
$$;

COMMENT ON FUNCTION public.create_invitation_code(UUID, INT, INT, TEXT) IS
  'P1.5-05: genera y persiste un código de invitación. Solo admin u operator_admin del operador. Devuelve el código generado.';

-- ----------------------------------------------------------------------------
-- Revoke por expiración: en lugar de DELETE, marcar expires_at = NOW().
-- Esto preserva la auditoría de quién usó el código antes de revocarlo.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.revoke_invitation_code(p_code TEXT)
  RETURNS BOOLEAN
  LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_row public.invitation_codes;
BEGIN
  SELECT * INTO v_row FROM public.invitation_codes WHERE code = p_code;
  IF v_row.code IS NULL THEN
    RETURN false;
  END IF;

  IF NOT (
    public.is_admin()
    OR public.is_operator_admin_of(v_row.operator_id)
    OR v_row.created_by = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Forbidden: cannot revoke code %', p_code;
  END IF;

  UPDATE public.invitation_codes
    SET expires_at = NOW()
    WHERE code = p_code;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION public.revoke_invitation_code(TEXT) IS
  'P1.5-05: marca expires_at = NOW() en vez de borrar, preservando auditoría.';

COMMIT;
