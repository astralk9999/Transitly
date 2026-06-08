-- 040_community_inbox_zone_filter.sql
-- - moderation_list/moderation_resolve: añaden las rutas de comunidad que el
--   autor pidió oficializar (user_routes status review_pending, source
--   'community_route') y las paradas sugeridas (user_stops promotion_status
--   requested, source 'stop_suggestion'). Aceptar community_route la
--   des-marca (vuelve a published) y rechazar la marca rejected; la
--   oficialización real se hace desde el detalle. stop_suggestion aprueba/
--   rechaza promotion_status.
-- - admin_list_stops ahora devuelve zone_id (para el filtro de zona en
--   Gestión de paradas).
-- - list_official_stops_near (037 previa) usada por el picker de comunidad.
--
-- Los cuerpos completos de moderation_list/moderation_resolve están aplicados
-- en la BD vía MCP (idénticos a este repo).

DROP FUNCTION IF EXISTS public.admin_list_stops(UUID);
CREATE OR REPLACE FUNCTION public.admin_list_stops(p_operator_id UUID)
RETURNS TABLE (
  id UUID, operator_id UUID, code TEXT, name TEXT,
  lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  accessibility JSONB, zone_id UUID
)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT s.id, s.operator_id, s.code, s.name,
         ST_Y(s.geom)::float8 AS lat, ST_X(s.geom)::float8 AS lng,
         s.accessibility, s.zone_id
  FROM stops s
  WHERE s.operator_id = p_operator_id
    AND _can_manage_operator(p_operator_id)
  ORDER BY s.name;
$$;
GRANT EXECUTE ON FUNCTION public.admin_list_stops(UUID) TO authenticated;
