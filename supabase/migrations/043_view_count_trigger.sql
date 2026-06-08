-- 043_view_count_trigger.sql — vistas de rutas de comunidad.
-- No existia trigger en user_route_views, asi que view_count nunca subia.
-- Cuenta la PRIMERA vista de cada visitante (no acumula por reaperturas).
UPDATE user_routes ur SET view_count = COALESCE((
  SELECT count(DISTINCT viewer_id) FROM user_route_views v WHERE v.route_id = ur.id
), 0);

CREATE OR REPLACE FUNCTION public.trg_user_route_view_count()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_route_views
    WHERE route_id = NEW.route_id
      AND viewer_id IS NOT DISTINCT FROM NEW.viewer_id
      AND id <> NEW.id
  ) THEN
    UPDATE user_routes SET view_count = view_count + 1 WHERE id = NEW.route_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_route_view_count ON public.user_route_views;
CREATE TRIGGER trg_user_route_view_count AFTER INSERT ON public.user_route_views
  FOR EACH ROW EXECUTE FUNCTION trg_user_route_view_count();
