-- 045_user_routes_imported_from.sql
-- Marca las rutas que son una COPIA importada por un usuario (no una ruta
-- original creada/propuesta a la comunidad). Permite excluirlas del panel de
-- gestión de comunidad (community_management_screen) para que importar una
-- línea de otro usuario no la duplique ahí.
--
-- Aplicada vía MCP (apply_migration); este archivo es el consolidado del repo.

ALTER TABLE public.user_routes
  ADD COLUMN IF NOT EXISTS imported_from uuid
  REFERENCES public.user_routes(id) ON DELETE SET NULL;

-- import_community_route ahora registra el id de origen en imported_from.
CREATE OR REPLACE FUNCTION public.import_community_route(p_route_id UUID)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_src user_routes%ROWTYPE;
  v_new_route UUID;
  v_map JSONB := '{}'::jsonb;
  rs RECORD;
  v_new_stop UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Auth requerida'; END IF;
  SELECT * INTO v_src FROM user_routes WHERE id = p_route_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  INSERT INTO user_routes (author_id, name, code, description, route_color,
                           service_type, visibility, status, country_code, region,
                           imported_from)
  VALUES (v_uid, v_src.name || ' (importada)', v_src.code, v_src.description,
          v_src.route_color, v_src.service_type, 'private', 'draft',
          COALESCE(v_src.country_code,'ES'), v_src.region,
          p_route_id)
  RETURNING id INTO v_new_route;
  FOR rs IN
    SELECT us.* FROM user_route_stops urs
    JOIN user_stops us ON us.id = urs.user_stop_id
    WHERE urs.route_id = p_route_id
  LOOP
    INSERT INTO user_stops (author_id, official_stop_id, name, lat, lng,
                            stop_type, description)
    VALUES (v_uid, rs.official_stop_id, rs.name, rs.lat, rs.lng,
            rs.stop_type, rs.description)
    RETURNING id INTO v_new_stop;
    v_map := v_map || jsonb_build_object(rs.id::text, v_new_stop::text);
  END LOOP;
  INSERT INTO user_route_stops (route_id, user_stop_id, order_index,
                                duration_to_next_min, distance_to_next_km)
  SELECT v_new_route, (v_map->>(urs.user_stop_id::text))::uuid,
         urs.order_index, urs.duration_to_next_min, urs.distance_to_next_km
  FROM user_route_stops urs
  WHERE urs.route_id = p_route_id AND v_map ? urs.user_stop_id::text;
  INSERT INTO user_route_schedules (route_id, day_type, departure_time,
                                    origin_stop_id, notes)
  SELECT v_new_route, s.day_type, s.departure_time,
         CASE WHEN s.origin_stop_id IS NOT NULL AND v_map ? s.origin_stop_id::text
              THEN (v_map->>(s.origin_stop_id::text))::uuid ELSE NULL END,
         s.notes
  FROM user_route_schedules s WHERE s.route_id = p_route_id;
  RETURN v_new_route;
END $$;
GRANT EXECUTE ON FUNCTION public.import_community_route(UUID) TO authenticated;

-- Backfill de copias ya existentes (importadas antes de esta migración):
-- enlazan a su original por nombre; si no se identifica, se autorreferencian
-- como marca de importación para quedar excluidas del panel.
UPDATE public.user_routes c
SET imported_from = COALESCE(
  (SELECT src.id FROM public.user_routes src
   WHERE src.id <> c.id
     AND src.name = left(c.name, length(c.name) - length(' (importada)'))
   ORDER BY (src.visibility='public') DESC, src.created_at
   LIMIT 1),
  c.id)
WHERE c.imported_from IS NULL
  AND c.visibility='private' AND c.status='draft'
  AND c.name LIKE '% (importada)';
