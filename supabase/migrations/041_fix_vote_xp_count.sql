-- 041_fix_vote_xp_count.sql — votos: contador correcto y XP solo el 1er voto.
-- Antes: trg_route_vote_xp sumaba vote_count y +1 XP en cada INSERT, y no
-- había trigger en DELETE → quitar y volver a votar inflaba el contador y
-- regalaba puntos infinitos.
CREATE TABLE IF NOT EXISTS public.route_vote_xp_awarded (
  voter_id UUID NOT NULL,
  route_id UUID NOT NULL,
  PRIMARY KEY (voter_id, route_id)
);

UPDATE user_routes ur SET vote_count = COALESCE((
  SELECT count(*) FROM user_route_votes v WHERE v.route_id = ur.id), 0);

CREATE OR REPLACE FUNCTION public.trg_route_vote_xp()
RETURNS trigger LANGUAGE plpgsql AS $function$
DECLARE v_author UUID; v_first BOOLEAN;
BEGIN
  UPDATE user_routes SET vote_count = vote_count + 1 WHERE id = NEW.route_id;
  INSERT INTO route_vote_xp_awarded (voter_id, route_id)
  VALUES (NEW.voter_id, NEW.route_id) ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS v_first = ROW_COUNT;
  IF v_first THEN
    SELECT author_id INTO v_author FROM user_routes WHERE id = NEW.route_id;
    IF v_author IS NOT NULL AND v_author <> NEW.voter_id THEN
      PERFORM add_xp(v_author, 1);
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_route_unvote()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
  UPDATE user_routes SET vote_count = GREATEST(vote_count - 1, 0)
  WHERE id = OLD.route_id;
  RETURN OLD;
END;
$function$;

DROP TRIGGER IF EXISTS trg_route_unvote ON public.user_route_votes;
CREATE TRIGGER trg_route_unvote AFTER DELETE ON public.user_route_votes
  FOR EACH ROW EXECUTE FUNCTION trg_route_unvote();
