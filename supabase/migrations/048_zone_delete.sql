-- 048_zone_delete.sql
-- Borrado de zona: admin global, o admin de la operadora dueña de la zona.
-- Desvincula la zona de los perfiles que la tuvieran como zona principal.
-- Aplicada vía MCP (apply_migration); consolidado para el repo.
CREATE OR REPLACE FUNCTION public.zone_delete(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_op uuid;
BEGIN
  SELECT operator_id INTO v_op FROM zones WHERE id = p_id;
  IF NOT FOUND THEN RETURN; END IF;
  IF NOT (is_admin() OR (v_op IS NOT NULL AND _can_manage_operator(v_op))) THEN
    RAISE EXCEPTION 'No autorizado para borrar esta zona';
  END IF;
  UPDATE profiles SET primary_zone_id = NULL WHERE primary_zone_id = p_id;
  DELETE FROM zones WHERE id = p_id;
END $function$;
GRANT EXECUTE ON FUNCTION public.zone_delete(uuid) TO authenticated;
