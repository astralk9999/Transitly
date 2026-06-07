-- 037_community_reports_import.sql
-- - mark_all_notifications_read(): marca todas como leídas en una operación.
-- - Reportes de rutas de comunidad: trigger que avisa a admins al reportar,
--   inclusión en moderation_list y rama en moderation_resolve (aceptar borra
--   la ruta, rechazar la descarta sin más).
-- - import_community_route(): copia una ruta de comunidad (paradas + horarios)
--   a las rutas del usuario actual.
--
-- Aplicada vía MCP en bloques; este archivo es el consolidado para el repo.
-- Ver el cuerpo completo de moderation_list / moderation_resolve en la BD.

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_count INT;
BEGIN
  UPDATE notifications SET read = true
  WHERE user_id = auth.uid() AND read = false;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END $$;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;

CREATE OR REPLACE FUNCTION public._notify_admins_on_route_report()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_route_name TEXT;
BEGIN
  SELECT name INTO v_route_name FROM user_routes WHERE id = NEW.route_id;
  INSERT INTO notifications (user_id, type, payload)
  SELECT p.id, 'custom', jsonb_build_object(
    'title','Nuevo reporte de ruta',
    'body', COALESCE(v_route_name,'Ruta de comunidad')||' · '||NEW.reason,
    'kind','route_report','report_id', NEW.id, 'route_id', NEW.route_id)
  FROM profiles p WHERE p.role='admin';
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_notify_admins_route_report ON user_route_reports;
CREATE TRIGGER trg_notify_admins_route_report
  AFTER INSERT ON user_route_reports
  FOR EACH ROW EXECUTE FUNCTION _notify_admins_on_route_report();

-- import_community_route: copia ruta + paradas + horarios al usuario actual.
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
                           service_type, visibility, status, country_code, region)
  VALUES (v_uid, v_src.name || ' (importada)', v_src.code, v_src.description,
          v_src.route_color, v_src.service_type, 'private', 'draft',
          COALESCE(v_src.country_code,'ES'), v_src.region)
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

-- NOTA: moderation_list y moderation_resolve se recrean en la BD para
-- incluir el source 'route_report' (lista) y la rama que borra la ruta al
-- aceptar / la descarta al rechazar (resolve). Ver definición en la BD.
