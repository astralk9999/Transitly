-- 038_officialize_admin_delete.sql
-- - admin_delete_user_route(): admin borra la ruta de cualquier usuario.
-- - officialize_user_route(): admin convierte una ruta de comunidad en
--   oficial (crea routes + stops + route_stops + schedules, registra el
--   cambio en route_changelog y borra la comunitaria). Operador obligatorio,
--   zona y código opcionales.
-- Aplicadas vía MCP; consolidado para el repo.

CREATE OR REPLACE FUNCTION public.admin_delete_user_route(p_route_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Solo admin puede borrar rutas de otros usuarios';
  END IF;
  DELETE FROM user_routes WHERE id = p_route_id;
END $$;
GRANT EXECUTE ON FUNCTION public.admin_delete_user_route(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.officialize_user_route(
  p_route_id   UUID, p_operator_id UUID, p_zone_id UUID,
  p_code TEXT, p_color TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE
  v_src user_routes%ROWTYPE; v_new UUID; rs RECORD; v_stop UUID; v_seq INT := 0;
BEGIN
  IF NOT is_admin() THEN RAISE EXCEPTION 'Solo admin puede oficializar rutas'; END IF;
  IF p_operator_id IS NULL THEN RAISE EXCEPTION 'Una ruta oficial requiere operador'; END IF;
  SELECT * INTO v_src FROM user_routes WHERE id = p_route_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;

  INSERT INTO routes (operator_id, source, status, code, name, description, color, zone_id, metadata)
  VALUES (p_operator_id, 'official', 'official',
          COALESCE(NULLIF(p_code,''), v_src.code, 'NUEVA'),
          v_src.name, v_src.description,
          COALESCE(NULLIF(p_color,''), v_src.route_color),
          p_zone_id, jsonb_build_object('active', true))
  RETURNING id INTO v_new;

  FOR rs IN
    SELECT us.*, urs.order_index FROM user_route_stops urs
    JOIN user_stops us ON us.id = urs.user_stop_id
    WHERE urs.route_id = p_route_id ORDER BY urs.order_index
  LOOP
    IF rs.official_stop_id IS NOT NULL THEN
      v_stop := rs.official_stop_id;
    ELSE
      INSERT INTO stops (operator_id, name, geom, zone_id, accessibility)
      VALUES (p_operator_id, rs.name, ST_SetSRID(ST_MakePoint(rs.lng, rs.lat), 4326),
              p_zone_id, '{}'::jsonb)
      RETURNING id INTO v_stop;
    END IF;
    v_seq := v_seq + 1;
    INSERT INTO route_stops (route_id, stop_id, sequence, direction)
    VALUES (v_new, v_stop, v_seq, 0)
    ON CONFLICT (route_id, stop_id, direction, sequence) DO NOTHING;
  END LOOP;

  INSERT INTO schedules (route_id, day_type, direction, departure_time)
  SELECT v_new,
         (CASE WHEN s.day_type IN ('weekday','saturday','sunday_holiday') THEN s.day_type
               WHEN s.day_type IN ('sunday','holiday') THEN 'sunday_holiday'
               ELSE 'weekday' END)::day_type,
         0, s.departure_time
  FROM user_route_schedules s WHERE s.route_id = p_route_id;

  PERFORM log_route_change(v_new, 'officialized', 'Ruta oficializada desde la comunidad');
  DELETE FROM user_routes WHERE id = p_route_id;
  RETURN v_new;
END $$;
GRANT EXECUTE ON FUNCTION public.officialize_user_route(UUID,UUID,UUID,TEXT,TEXT) TO authenticated;
