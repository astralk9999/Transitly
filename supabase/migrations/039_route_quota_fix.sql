-- 039_route_quota_fix.sql — cuota de rutas de comunidad.
-- - Admins/moderadores exentos de cuota.
-- - El conteo pasa a ser EN VIVO (count de rutas no-borrador del autor) en
--   lugar del contador acumulado routes_created_count, de modo que eliminar
--   una ruta libera cuota.
CREATE OR REPLACE FUNCTION public.check_user_routes_quota()
RETURNS trigger LANGUAGE plpgsql AS $function$
DECLARE
  current_count INT;
  quota INT;
  v_staff BOOLEAN;
BEGIN
  SELECT role IN ('admin','moderator') INTO v_staff FROM profiles WHERE id = NEW.author_id;
  IF NOT COALESCE(v_staff, false) THEN
    SELECT count(*) INTO current_count
      FROM user_routes WHERE author_id = NEW.author_id AND status <> 'draft';
    SELECT user_routes_quota(NEW.author_id) INTO quota;
    IF current_count >= quota AND NEW.status NOT IN ('draft') THEN
      RAISE EXCEPTION 'route quota exceeded: %. Sube de nivel o elimina una ruta.', current_count
        USING ERRCODE = 'P0001';
    END IF;
  END IF;
  IF NEW.share_code IS NULL THEN
    NEW.share_code := generate_share_code();
  END IF;
  IF NEW.public_slug IS NULL THEN
    NEW.public_slug := generate_public_slug();
  END IF;
  RETURN NEW;
END;
$function$;
