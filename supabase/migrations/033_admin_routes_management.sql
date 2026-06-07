-- 033_admin_routes_management.sql — gestión de líneas/paradas/horarios
--
-- Expone RPCs SECURITY DEFINER para que admin y operator_admin puedan
-- editar rutas, paradas y horarios de su operadora.
--   - admin → cualquier ruta de cualquier operador (incluye reasignar)
--   - operator_admin → solo las rutas de SU operador (profiles.operator_id)
--
-- Validación centralizada en _can_manage_operator(operator_id) que se
-- consulta al inicio de cada RPC. Para reasignar operador se exige
-- además permiso sobre el operador DESTINO (sólo admin podrá si
-- cambian de operador distinto del propio).

-- ── Helper de autorización ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public._can_manage_operator(p_operator_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_admin()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role = 'operator_admin'
        AND operator_id = p_operator_id
    );
$$;
GRANT EXECUTE ON FUNCTION public._can_manage_operator(UUID) TO authenticated;

-- ── updated_at automático en routes ────────────────────────────
CREATE OR REPLACE FUNCTION public._touch_route_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_routes_updated_at ON routes;
CREATE TRIGGER trg_touch_routes_updated_at
  BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION _touch_route_updated_at();

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ RUTAS (líneas)                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public.admin_route_upsert(
  p_id          UUID,
  p_operator_id UUID,
  p_code        TEXT,
  p_name        TEXT,
  p_description TEXT,
  p_color       TEXT,
  p_status      TEXT,
  p_source      TEXT,
  p_active      BOOLEAN
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id UUID;
BEGIN
  IF NOT _can_manage_operator(p_operator_id) THEN
    RAISE EXCEPTION 'No autorizado para editar rutas de este operador';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO routes (operator_id, code, name, description, color,
                        status, source, metadata)
    VALUES (p_operator_id, p_code, p_name, p_description, p_color,
            p_status::route_status, p_source::route_source,
            jsonb_build_object('active', p_active))
    RETURNING id INTO v_id;
  ELSE
    -- Si cambia de operador, además del operador actual hay que tener
    -- permiso sobre el destino. _can_manage_operator(p_operator_id) ya
    -- chequea el destino; chequeamos también el actual.
    IF NOT _can_manage_operator(
      (SELECT operator_id FROM routes WHERE id = p_id)
    ) THEN
      RAISE EXCEPTION 'No autorizado sobre la ruta origen';
    END IF;

    UPDATE routes SET
      operator_id = p_operator_id,
      code        = p_code,
      name        = p_name,
      description = p_description,
      color       = p_color,
      status      = p_status::route_status,
      source      = p_source::route_source,
      metadata    = COALESCE(metadata, '{}'::jsonb)
                    || jsonb_build_object('active', p_active)
    WHERE id = p_id
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_upsert(UUID,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOLEAN)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_route_delete(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  DELETE FROM routes WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_delete(UUID) TO authenticated;

-- Solo admin puede mover ruta a otra operadora (regla dura).
CREATE OR REPLACE FUNCTION public.admin_route_set_operator(
  p_id UUID,
  p_new_operator_id UUID
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Solo admin puede reasignar ruta entre operadoras';
  END IF;
  UPDATE routes SET operator_id = p_new_operator_id WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_set_operator(UUID,UUID) TO authenticated;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PARADAS                                                       ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public.admin_stop_upsert(
  p_id          UUID,
  p_operator_id UUID,
  p_code        TEXT,
  p_name        TEXT,
  p_lat         DOUBLE PRECISION,
  p_lng         DOUBLE PRECISION,
  p_accessible  BOOLEAN,
  p_has_shelter BOOLEAN,
  p_has_bench   BOOLEAN
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id UUID;
  v_geom geometry(POINT,4326) := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
  v_acc JSONB := jsonb_build_object(
    'wheelchair', p_accessible,
    'shelter', p_has_shelter,
    'bench', p_has_bench
  );
BEGIN
  IF NOT _can_manage_operator(p_operator_id) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  IF p_id IS NULL THEN
    INSERT INTO stops (operator_id, code, name, geom, accessibility)
    VALUES (p_operator_id, p_code, p_name, v_geom, v_acc)
    RETURNING id INTO v_id;
  ELSE
    IF NOT _can_manage_operator(
      (SELECT operator_id FROM stops WHERE id = p_id)
    ) THEN
      RAISE EXCEPTION 'No autorizado sobre la parada';
    END IF;
    UPDATE stops SET
      operator_id   = p_operator_id,
      code          = p_code,
      name          = p_name,
      geom          = v_geom,
      accessibility = v_acc
    WHERE id = p_id
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_stop_upsert(UUID,UUID,TEXT,TEXT,DOUBLE PRECISION,DOUBLE PRECISION,BOOLEAN,BOOLEAN,BOOLEAN)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_stop_move(
  p_id UUID, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID;
BEGIN
  SELECT operator_id INTO v_op FROM stops WHERE id = p_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Parada no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  UPDATE stops SET geom = ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)
  WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_stop_move(UUID,DOUBLE PRECISION,DOUBLE PRECISION)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_stop_delete(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID;
BEGIN
  SELECT operator_id INTO v_op FROM stops WHERE id = p_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Parada no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  DELETE FROM stops WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_stop_delete(UUID) TO authenticated;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ ROUTE_STOPS (vincular paradas a rutas, orden)                ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public.admin_route_stop_add(
  p_route_id UUID, p_stop_id UUID, p_sequence INT, p_direction SMALLINT
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  INSERT INTO route_stops (route_id, stop_id, sequence, direction)
  VALUES (p_route_id, p_stop_id, p_sequence, p_direction)
  ON CONFLICT (route_id, stop_id, direction, sequence) DO NOTHING;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_stop_add(UUID,UUID,INT,SMALLINT)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_route_stop_remove(
  p_route_id UUID, p_stop_id UUID, p_direction SMALLINT
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  DELETE FROM route_stops
    WHERE route_id = p_route_id
      AND stop_id  = p_stop_id
      AND direction = p_direction;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_stop_remove(UUID,UUID,SMALLINT)
  TO authenticated;

-- Reordena por completo todas las paradas de una ruta+dirección.
-- p_pairs es JSONB array de [{stop_id, sequence}].
CREATE OR REPLACE FUNCTION public.admin_route_stops_reorder(
  p_route_id UUID, p_direction SMALLINT, p_pairs JSONB
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_op UUID;
  v_pair JSONB;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  -- Borra todas las del par (route, direction) y reinserta.
  DELETE FROM route_stops
    WHERE route_id = p_route_id AND direction = p_direction;
  FOR v_pair IN SELECT * FROM jsonb_array_elements(p_pairs)
  LOOP
    INSERT INTO route_stops (route_id, stop_id, sequence, direction)
    VALUES (
      p_route_id,
      (v_pair->>'stop_id')::UUID,
      (v_pair->>'sequence')::INT,
      p_direction
    );
  END LOOP;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_route_stops_reorder(UUID,SMALLINT,JSONB)
  TO authenticated;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ HORARIOS                                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public.admin_schedule_upsert(
  p_id            UUID,
  p_route_id      UUID,
  p_day_type      TEXT,
  p_direction     SMALLINT,
  p_departure_time TEXT,
  p_notes         TEXT
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_op UUID;
  v_id UUID;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  IF p_id IS NULL THEN
    INSERT INTO schedules (route_id, day_type, direction, departure_time, notes)
    VALUES (p_route_id, p_day_type::day_type, p_direction,
            p_departure_time::time, p_notes)
    RETURNING id INTO v_id;
  ELSE
    UPDATE schedules SET
      route_id = p_route_id,
      day_type = p_day_type::day_type,
      direction = p_direction,
      departure_time = p_departure_time::time,
      notes = p_notes
    WHERE id = p_id
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_schedule_upsert(UUID,UUID,TEXT,SMALLINT,TEXT,TEXT)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_schedule_delete(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_route_id UUID; v_op UUID;
BEGIN
  SELECT route_id INTO v_route_id FROM schedules WHERE id = p_id;
  IF v_route_id IS NULL THEN RAISE EXCEPTION 'Horario no encontrado'; END IF;
  SELECT operator_id INTO v_op FROM routes WHERE id = v_route_id;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  DELETE FROM schedules WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_schedule_delete(UUID) TO authenticated;

-- Bulk generador: rellena horarios cada N minutos desde HH:MM hasta HH:MM
-- para day_type+direction de la ruta. Devuelve cuántos insertó.
CREATE OR REPLACE FUNCTION public.admin_schedules_generate_frequency(
  p_route_id   UUID,
  p_day_type   TEXT,
  p_direction  SMALLINT,
  p_start_time TEXT,
  p_end_time   TEXT,
  p_interval_min INT
) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_op UUID;
  v_t TIME := p_start_time::time;
  v_end TIME := p_end_time::time;
  v_count INT := 0;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  IF p_interval_min <= 0 THEN RAISE EXCEPTION 'Intervalo inválido'; END IF;
  WHILE v_t <= v_end LOOP
    INSERT INTO schedules (route_id, day_type, direction, departure_time)
    VALUES (p_route_id, p_day_type::day_type, p_direction, v_t);
    v_t := v_t + (p_interval_min || ' minutes')::interval;
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_schedules_generate_frequency(UUID,TEXT,SMALLINT,TEXT,TEXT,INT)
  TO authenticated;

-- Borra todos los horarios de una ruta+day_type+direction (para regenerar limpio).
CREATE OR REPLACE FUNCTION public.admin_schedules_clear(
  p_route_id UUID, p_day_type TEXT, p_direction SMALLINT
) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_op UUID; v_count INT;
BEGIN
  SELECT operator_id INTO v_op FROM routes WHERE id = p_route_id;
  IF v_op IS NULL THEN RAISE EXCEPTION 'Ruta no encontrada'; END IF;
  IF NOT _can_manage_operator(v_op) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
  DELETE FROM schedules
    WHERE route_id = p_route_id
      AND day_type = p_day_type::day_type
      AND direction = p_direction;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_schedules_clear(UUID,TEXT,SMALLINT) TO authenticated;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ HELPERS LECTURA (lat/lng desde PostGIS)                       ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public.admin_list_stops(p_operator_id UUID)
RETURNS TABLE (
  id UUID, operator_id UUID, code TEXT, name TEXT,
  lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  accessibility JSONB
)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT s.id, s.operator_id, s.code, s.name,
         ST_Y(s.geom)::float8 AS lat, ST_X(s.geom)::float8 AS lng,
         s.accessibility
  FROM stops s
  WHERE s.operator_id = p_operator_id
    AND _can_manage_operator(p_operator_id)
  ORDER BY s.name;
$$;
GRANT EXECUTE ON FUNCTION public.admin_list_stops(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_list_route_stops(p_route_id UUID)
RETURNS TABLE (
  route_id UUID, stop_id UUID, sequence INT, direction SMALLINT,
  operator_id UUID, code TEXT, name TEXT,
  lat DOUBLE PRECISION, lng DOUBLE PRECISION
)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT rs.route_id, rs.stop_id, rs.sequence, rs.direction,
         s.operator_id, s.code, s.name,
         ST_Y(s.geom)::float8 AS lat, ST_X(s.geom)::float8 AS lng
  FROM route_stops rs
  JOIN routes r ON r.id = rs.route_id
  LEFT JOIN stops s ON s.id = rs.stop_id
  WHERE rs.route_id = p_route_id
    AND _can_manage_operator(r.operator_id)
  ORDER BY rs.direction, rs.sequence;
$$;
GRANT EXECUTE ON FUNCTION public.admin_list_route_stops(UUID) TO authenticated;
