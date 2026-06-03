-- =============================================================
-- 019_arrivals_realtime.sql — Sistema de llegadas reales
-- =============================================================
-- Tabla de horarios programados + vista materializada + RPCs
-- públicas para widgets y UI.
-- =============================================================

-- 1 ── Tabla de salidas programadas ─────────────────────────────
CREATE TABLE IF NOT EXISTS scheduled_departures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_code TEXT NOT NULL,
  day_type TEXT NOT NULL CHECK (day_type IN (
    'weekday', 'saturday', 'sunday_holiday'
  )),
  departure_time TIME NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS scheduled_dep_route_day_idx
  ON scheduled_departures(route_code, day_type, departure_time);

ALTER TABLE scheduled_departures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read schedules" ON scheduled_departures;
CREATE POLICY "Public read schedules" ON scheduled_departures
  FOR SELECT USING (true);

-- 2 ── Vista materializada: próximas llegadas (self-refresh) ────
DROP MATERIALIZED VIEW IF EXISTS next_scheduled_arrivals CASCADE;
CREATE MATERIALIZED VIEW next_scheduled_arrivals AS
SELECT
  sd.id,
  sd.route_code,
  sd.day_type,
  sd.departure_time,
  CASE
    WHEN EXTRACT(DOW FROM NOW()) IN (1,2,3,4,5) THEN 'weekday'
    WHEN EXTRACT(DOW FROM NOW()) = 6 THEN 'saturday'
    ELSE 'sunday_holiday'
  END AS current_day_type,
  EXTRACT(EPOCH FROM (
    (NOW()::date + sd.departure_time) - NOW()
  )) / 60 AS minutes_until
FROM scheduled_departures sd
WHERE sd.departure_time > NOW()::time
   OR (sd.departure_time <= NOW()::time
       AND sd.departure_time > (NOW() - INTERVAL '1 hour')::time)
ORDER BY sd.departure_time;

CREATE UNIQUE INDEX IF NOT EXISTS next_arrivals_id_idx
  ON next_scheduled_arrivals(id);

-- Refresh nocturno
SELECT cron.schedule(
  'refresh-next-arrivals',
  '0 3 * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY next_scheduled_arrivals;$$
) WHERE NOT EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'refresh-next-arrivals'
);

-- 3 ── RPC: próximas salidas para una línea ──────────────────────
CREATE OR REPLACE FUNCTION get_next_departures_for_route(
  p_route_code TEXT,
  p_limit INT DEFAULT 4
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
  v_day TEXT;
BEGIN
  SELECT CASE
    WHEN EXTRACT(DOW FROM NOW()) IN (1,2,3,4,5) THEN 'weekday'
    WHEN EXTRACT(DOW FROM NOW()) = 6 THEN 'saturday'
    ELSE 'sunday_holiday'
  END INTO v_day;

  SELECT json_agg(t ORDER BY t.departure_time)
  INTO v_result
  FROM (
    SELECT
      sd.departure_time::TEXT AS departure_time,
      EXTRACT(EPOCH FROM (
        (CURRENT_DATE + sd.departure_time) - NOW()
      )) / 60 AS minutes_until
    FROM scheduled_departures sd
    WHERE sd.route_code = p_route_code
      AND sd.day_type = v_day
      AND (CURRENT_DATE + sd.departure_time) > NOW()
    ORDER BY sd.departure_time
    LIMIT p_limit
  ) t;

  -- Si no quedan salidas hoy, devolver las primeras de mañana
  IF v_result IS NULL THEN
    SELECT json_agg(t ORDER BY t.departure_time)
    INTO v_result
    FROM (
      SELECT
        sd.departure_time::TEXT AS departure_time,
        EXTRACT(EPOCH FROM (
          (CURRENT_DATE + INTERVAL '1 day' + sd.departure_time) - NOW()
        )) / 60 AS minutes_until
      FROM scheduled_departures sd
      WHERE sd.route_code = p_route_code
        AND sd.day_type = v_day
      ORDER BY sd.departure_time
      LIMIT p_limit
    ) t;
  END IF;

  RETURN COALESCE(v_result, '[]'::JSON);
END;
$$;

-- 4 ── RPC: próximas salidas para ruta+parada (con offset) ───────
-- El offset es 2 minutos por parada (mismo criterio que mock)
CREATE OR REPLACE FUNCTION get_next_departures_for_route_stop(
  p_route_code TEXT,
  p_stop_index INT DEFAULT 0,
  p_limit INT DEFAULT 3
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
  v_day TEXT;
  v_offset INT;
BEGIN
  v_offset := p_stop_index * 2;

  SELECT CASE
    WHEN EXTRACT(DOW FROM NOW()) IN (1,2,3,4,5) THEN 'weekday'
    WHEN EXTRACT(DOW FROM NOW()) = 6 THEN 'saturday'
    ELSE 'sunday_holiday'
  END INTO v_day;

  SELECT json_agg(t ORDER BY t.departure_time)
  INTO v_result
  FROM (
    SELECT
      sd.departure_time::TEXT AS departure_time,
      EXTRACT(EPOCH FROM (
        (CURRENT_DATE + sd.departure_time + (v_offset * INTERVAL '1 minute')) - NOW()
      )) / 60 AS minutes_until
    FROM scheduled_departures sd
    WHERE sd.route_code = p_route_code
      AND sd.day_type = v_day
      AND (CURRENT_DATE + sd.departure_time + (v_offset * INTERVAL '1 minute')) > NOW()
    ORDER BY sd.departure_time
    LIMIT p_limit
  ) t;

  IF v_result IS NULL THEN
    SELECT json_agg(t ORDER BY t.departure_time)
    INTO v_result
    FROM (
      SELECT
        sd.departure_time::TEXT AS departure_time,
        EXTRACT(EPOCH FROM (
          (CURRENT_DATE + INTERVAL '1 day' + sd.departure_time + (v_offset * INTERVAL '1 minute')) - NOW()
        )) / 60 AS minutes_until
      FROM scheduled_departures sd
      WHERE sd.route_code = p_route_code
        AND sd.day_type = v_day
      ORDER BY sd.departure_time
      LIMIT p_limit
    ) t;
  END IF;

  RETURN COALESCE(v_result, '[]'::JSON);
END;
$$;
