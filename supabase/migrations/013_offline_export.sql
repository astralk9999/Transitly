-- =============================================================
-- 013_offline_export.sql — RPC export_region_data
-- =============================================================
-- F20. Devuelve operadores, paradas, rutas y horarios dentro de
-- un bounding box para descarga offline. Filtra espacialmente con
-- PostGIS y respeta RLS del caller (SECURITY INVOKER).

CREATE OR REPLACE FUNCTION public.export_region_data(
  p_north DOUBLE PRECISION,
  p_south DOUBLE PRECISION,
  p_east DOUBLE PRECISION,
  p_west DOUBLE PRECISION,
  p_zoom_min INT DEFAULT 8,
  p_zoom_max INT DEFAULT 18
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_bbox geometry;
  v_result jsonb;
  v_operator_ids UUID[];
BEGIN
  v_bbox := ST_MakeEnvelope(p_west, p_south, p_east, p_north, 4326);

  WITH op_in_region AS (
    SELECT * FROM operators
    WHERE bbox IS NOT NULL
      AND ST_Intersects(bbox, v_bbox)
  ),
  stops_in_region AS (
    SELECT s.* FROM stops s
    WHERE ST_Within(s.geom, v_bbox)
      AND s.operator_id IN (SELECT id FROM op_in_region)
  ),
  routes_in_region AS (
    SELECT r.* FROM routes r
    WHERE r.geom IS NOT NULL
      AND ST_Intersects(r.geom, v_bbox)
      AND r.operator_id IN (SELECT id FROM op_in_region)
  ),
  schedules_in_region AS (
    SELECT sc.* FROM schedules sc
    WHERE sc.route_id IN (SELECT id FROM routes_in_region)
  )
  SELECT jsonb_build_object(
    'operators',  COALESCE(
      (SELECT jsonb_agg(row_to_json(op_in_region.*)) FROM op_in_region),
      '[]'::jsonb
    ),
    'stops',      COALESCE(
      (SELECT jsonb_agg(row_to_json(stops_in_region.*)) FROM stops_in_region),
      '[]'::jsonb
    ),
    'routes',     COALESCE(
      (SELECT jsonb_agg(row_to_json(routes_in_region.*)) FROM routes_in_region),
      '[]'::jsonb
    ),
    'schedules',  COALESCE(
      (SELECT jsonb_agg(row_to_json(schedules_in_region.*)) FROM schedules_in_region),
      '[]'::jsonb
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.export_region_data(
  DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION,
  DOUBLE PRECISION, INT, INT
) IS 'Exporta operadores, paradas, rutas y horarios dentro de un bounding box para descarga offline. Respeta RLS del caller.';

GRANT EXECUTE ON FUNCTION public.export_region_data(
  DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION,
  DOUBLE PRECISION, INT, INT
) TO anon, authenticated;
