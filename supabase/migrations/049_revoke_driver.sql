-- 049_revoke_driver.sql
-- Revoca un conductor de una operadora: cierra su asignación (si existe) y, si
-- su perfil pertenece a esa operadora, lo devuelve a pasajero. Autorizado a
-- admin global o admin de la operadora. La RPC no existía y el panel de
-- conductores fallaba al revocar.
-- Aplicada vía MCP (apply_migration); consolidado para el repo.
CREATE OR REPLACE FUNCTION public.revoke_driver(p_driver_id uuid, p_operator_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (is_admin() OR is_operator_admin_of(p_operator_id)) THEN
    RAISE EXCEPTION 'No autorizado para revocar conductores de esta operadora';
  END IF;
  UPDATE driver_assignments
    SET revoked_at = now()
    WHERE driver_id = p_driver_id AND operator_id = p_operator_id
      AND revoked_at IS NULL;
  UPDATE profiles
    SET role = 'passenger', operator_id = NULL
    WHERE id = p_driver_id AND role = 'driver' AND operator_id = p_operator_id;
END $function$;
GRANT EXECUTE ON FUNCTION public.revoke_driver(uuid, uuid) TO authenticated;
