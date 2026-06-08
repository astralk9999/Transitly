-- 047_zones_perimeter.sql
-- Zonas con PERÍMETRO circular (mismo modelo que geo_alerts: centro + radio).
-- Permite dibujar la zona en el mapa, elegirla como "zona principal" del
-- perfil y usar su centro como destino por defecto del mapa cuando no hay
-- ubicación. Aplicada vía MCP (apply_migration); consolidado para el repo.
ALTER TABLE public.zones
  ADD COLUMN IF NOT EXISTS center_lat double precision,
  ADD COLUMN IF NOT EXISTS center_lng double precision,
  ADD COLUMN IF NOT EXISTS radius_m   integer;

-- list_zones: ahora también devuelve la geometría (cambia el tipo de retorno
-- → DROP + CREATE).
DROP FUNCTION IF EXISTS public.list_zones(boolean);
CREATE FUNCTION public.list_zones(p_include_pending boolean DEFAULT false)
RETURNS TABLE(id uuid, name text, zone_type text, status text,
              operator_id uuid, center_lat double precision,
              center_lng double precision, radius_m integer)
LANGUAGE sql SECURITY DEFINER SET search_path TO 'public'
AS $function$
  SELECT z.id, z.name, z.zone_type, z.status::text, z.operator_id,
         z.center_lat, z.center_lng, z.radius_m
  FROM zones z
  WHERE z.status='active' OR (p_include_pending AND is_admin())
  ORDER BY z.name;
$function$;

-- zone_upsert: acepta centro + radio. Mantiene la autorización admin global
-- o admin de la operadora indicada.
DROP FUNCTION IF EXISTS public.zone_upsert(uuid, text, text, uuid, uuid);
CREATE FUNCTION public.zone_upsert(
  p_id uuid, p_name text, p_type text, p_parent uuid, p_operator_id uuid,
  p_center_lat double precision DEFAULT NULL,
  p_center_lng double precision DEFAULT NULL,
  p_radius_m integer DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_id UUID;
BEGIN
  IF NOT (is_admin() OR (p_operator_id IS NOT NULL AND _can_manage_operator(p_operator_id))) THEN
    RAISE EXCEPTION 'No autorizado para crear zonas';
  END IF;
  IF p_id IS NULL THEN
    INSERT INTO zones (name, zone_type, parent_zone_id, status, operator_id,
                       created_by, center_lat, center_lng, radius_m)
    VALUES (p_name, COALESCE(p_type,'municipality'), p_parent, 'active',
            p_operator_id, auth.uid(), p_center_lat, p_center_lng, p_radius_m)
    RETURNING id INTO v_id;
  ELSE
    UPDATE zones SET name=p_name, zone_type=COALESCE(p_type,'municipality'),
      parent_zone_id=p_parent, operator_id=p_operator_id, status='active',
      center_lat=COALESCE(p_center_lat, center_lat),
      center_lng=COALESCE(p_center_lng, center_lng),
      radius_m=COALESCE(p_radius_m, radius_m)
    WHERE id=p_id RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $function$;

GRANT EXECUTE ON FUNCTION public.list_zones(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zone_upsert(uuid,text,text,uuid,uuid,double precision,double precision,integer) TO authenticated;
