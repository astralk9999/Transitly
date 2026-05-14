-- =============================================================
-- 012_reputation.sql — Sistema de reputación: función, triggers
-- =============================================================
-- F19. Recálculo de reputation_score + reputation_level en
-- profiles a partir de incidentes, feedbacks y sugerencias.

-- =============================================================
-- recompute_reputation(p_profile_id)
-- =============================================================
CREATE OR REPLACE FUNCTION recompute_reputation(p_profile_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_score INT := 0;
  v_incident_score INT;
  v_feedback_score INT;
  v_suggestion_score INT;
BEGIN
  SELECT COALESCE(SUM(
    CASE
      WHEN status = 'rejected' THEN -10
      ELSE 5
    END), 0) INTO v_incident_score
  FROM incidents WHERE author_id = p_profile_id;

  SELECT COALESCE(SUM(
    CASE
      WHEN status = 'applied' THEN 10
      ELSE 3
    END), 0) INTO v_feedback_score
  FROM route_feedback WHERE author_id = p_profile_id;

  SELECT COALESCE(SUM(
    CASE
      WHEN status = 'accepted' THEN 20
      WHEN status = 'rejected' THEN 0
      ELSE 5
    END), 0) INTO v_suggestion_score
  FROM route_suggestions WHERE author_id = p_profile_id;

  v_score := v_incident_score + v_feedback_score + v_suggestion_score;

  UPDATE profiles
  SET reputation_score = v_score,
      reputation_level = CASE
        WHEN v_score >= 5000 THEN 6
        WHEN v_score >= 1500 THEN 5
        WHEN v_score >= 500  THEN 4
        WHEN v_score >= 200  THEN 3
        WHEN v_score >= 50   THEN 2
        WHEN v_score >= 10   THEN 1
        ELSE 0
      END,
      updated_at = NOW()
  WHERE id = p_profile_id;
END;
$$;
COMMENT ON FUNCTION recompute_reputation(UUID) IS
  'Recomputa reputation_score y reputation_level en profiles a partir de incidents, route_feedback y route_suggestions.';

-- =============================================================
-- trg_incident_reputation()
-- =============================================================
CREATE OR REPLACE FUNCTION trg_incident_reputation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM recompute_reputation(NEW.author_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_incident_reputation_after ON incidents;
CREATE TRIGGER trg_incident_reputation_after
  AFTER INSERT OR UPDATE OF status ON incidents
  FOR EACH ROW EXECUTE FUNCTION trg_incident_reputation();

-- =============================================================
-- trg_feedback_reputation()
-- =============================================================
CREATE OR REPLACE FUNCTION trg_feedback_reputation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM recompute_reputation(NEW.author_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_feedback_reputation_after ON route_feedback;
CREATE TRIGGER trg_feedback_reputation_after
  AFTER INSERT OR UPDATE OF status ON route_feedback
  FOR EACH ROW EXECUTE FUNCTION trg_feedback_reputation();

-- =============================================================
-- trg_suggestion_reputation()
-- =============================================================
CREATE OR REPLACE FUNCTION trg_suggestion_reputation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM recompute_reputation(NEW.author_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_suggestion_reputation_after ON route_suggestions;
CREATE TRIGGER trg_suggestion_reputation_after
  AFTER INSERT OR UPDATE OF status ON route_suggestions
  FOR EACH ROW EXECUTE FUNCTION trg_suggestion_reputation();

-- =============================================================
-- ACHIEVEMENT TRIGGERS (F19 — catalog ready, triggers are
-- commented out until achievement tracking infra is built)
-- =============================================================
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_first_report()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- BEGIN
--   IF (SELECT COUNT(*) FROM incidents WHERE author_id = NEW.author_id) >= 1 THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, 'first_report', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_first_route_created()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- BEGIN
--   IF (SELECT COUNT(*) FROM routes WHERE author_id = NEW.author_id AND source = 'community') >= 1 THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, 'first_route_created', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_first_route_verified()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- BEGIN
--   IF NEW.status = 'verified' THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, 'first_route_verified', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_first_route_official()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- BEGIN
--   IF NEW.status = 'official' THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, 'first_route_official', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_100_votes()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- DECLARE v_count INT;
-- BEGIN
--   SELECT COUNT(*) INTO v_count FROM suggestion_votes WHERE voter_id = NEW.voter_id;
--   IF v_count >= 100 THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.voter_id, '100_votes_cast', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_10_corrections()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- DECLARE v_count INT;
-- BEGIN
--   SELECT COUNT(*) INTO v_count FROM route_feedback WHERE author_id = NEW.author_id AND status = 'accepted';
--   IF v_count >= 10 THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, '10_corrections', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- CREATE OR REPLACE FUNCTION check_achievement_cartographer()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $$
-- DECLARE v_count INT;
-- BEGIN
--   SELECT COUNT(*) INTO v_count FROM routes WHERE author_id = NEW.author_id AND status = 'verified';
--   IF v_count >= 5 THEN
--     INSERT INTO user_achievements (profile_id, code, unlocked_at)
--     VALUES (NEW.author_id, 'cartographer_default', NOW())
--     ON CONFLICT (profile_id, code) DO NOTHING;
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
-- 
-- TODO: bus_finder and early_adopter require client-side or
-- separate tracking (bus_view events, app_open events). These
-- will be handled by the achievement service in a later phase.
