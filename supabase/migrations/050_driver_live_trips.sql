-- 050_driver_live_trips.sql
-- Modo conductor SIMPLIFICADO: un conductor inicia una ruta eligiendo línea +
-- hora y publica su posición GPS en vivo. Cualquier usuario ve el bus moverse
-- en el mapa (Supabase Realtime). Sustituye al flujo antiguo de conductor
-- (editor/grabación). Ver docs/DESACTIVADO.md.

CREATE TABLE IF NOT EXISTS public.driver_live_trips (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operator_id   uuid REFERENCES public.operators(id) ON DELETE SET NULL,
  route_id      text NOT NULL,            -- id de la línea (oficial: código; comunidad: uuid)
  route_code    text,
  route_name    text,
  route_color   text,
  departure_time text,                    -- hora elegida HH:mm
  lat           double precision NOT NULL,
  lng           double precision NOT NULL,
  heading       double precision,
  driver_name   text,
  started_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  active        boolean NOT NULL DEFAULT true
);

-- Un único viaje activo por conductor.
CREATE UNIQUE INDEX IF NOT EXISTS driver_live_one_active
  ON public.driver_live_trips(driver_id) WHERE active;

ALTER TABLE public.driver_live_trips ENABLE ROW LEVEL SECURITY;

-- Lectura: todos (autenticados) ven los viajes en vivo.
DROP POLICY IF EXISTS "live trips readable" ON public.driver_live_trips;
CREATE POLICY "live trips readable" ON public.driver_live_trips
  FOR SELECT USING (true);

-- El conductor gestiona SOLO su propio viaje.
DROP POLICY IF EXISTS "driver inserts own live" ON public.driver_live_trips;
CREATE POLICY "driver inserts own live" ON public.driver_live_trips
  FOR INSERT WITH CHECK (auth.uid() = driver_id);

DROP POLICY IF EXISTS "driver updates own live" ON public.driver_live_trips;
CREATE POLICY "driver updates own live" ON public.driver_live_trips
  FOR UPDATE USING (auth.uid() = driver_id) WITH CHECK (auth.uid() = driver_id);

DROP POLICY IF EXISTS "driver deletes own live" ON public.driver_live_trips;
CREATE POLICY "driver deletes own live" ON public.driver_live_trips
  FOR DELETE USING (auth.uid() = driver_id);

-- Realtime: emite cambios de esta tabla.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname='supabase_realtime' AND schemaname='public'
      AND tablename='driver_live_trips'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_live_trips;
  END IF;
END $$;

-- Cierra un viaje (marca inactivo). El conductor cierra el suyo.
CREATE OR REPLACE FUNCTION public.end_my_live_trip()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path TO 'public'
AS $$
  UPDATE public.driver_live_trips SET active=false, updated_at=now()
  WHERE driver_id = auth.uid() AND active;
$$;
GRANT EXECUTE ON FUNCTION public.end_my_live_trip() TO authenticated;
