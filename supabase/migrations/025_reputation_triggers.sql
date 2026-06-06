-- 025_reputation_triggers.sql — XP por eventos que lista la UI de reputación
-- Cada trigger ejecuta add_xp() (definida en 017_user_routes.sql), que
-- añade puntos y recalcula reputation_level.
--
-- Mapeo eventos UI → tabla / status:
--   incidentCreated         +5  → INSERT incidents
--   incidentRejectedSpam   -10  → UPDATE incidents.status → 'rejected'
--   feedbackSubmitted       +3  → INSERT route_feedback
--   feedbackAccepted       +10  → UPDATE route_feedback.status → 'applied'
--   suggestionCreated       +5  → INSERT route_suggestions
--   suggestionVoteReceived  +2  → INSERT route_suggestion_votes (al autor)
--   suggestionVerified     +20  → UPDATE route_suggestions.status → 'accepted'
--   duplicateReport         +1  → INSERT user_route_reports con reason='duplicated'
-- (routeLikeReceived +1 ya cubierto por trg_route_vote_xp en 017_user_routes.sql)
-- (suggestionOfficial +50 omitido: no hay estado/columna que represente
--  la promoción a "oficial"; queda como futura ampliación cuando exista)

-- ── INCIDENTS ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_incident_created_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, 5);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_incident_created_xp ON incidents;
CREATE TRIGGER trg_incident_created_xp
  AFTER INSERT ON incidents
  FOR EACH ROW EXECUTE FUNCTION trg_incident_created_xp();

CREATE OR REPLACE FUNCTION trg_incident_rejected_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'rejected'
     AND OLD.status IS DISTINCT FROM 'rejected'
     AND NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, -10);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_incident_rejected_xp ON incidents;
CREATE TRIGGER trg_incident_rejected_xp
  AFTER UPDATE OF status ON incidents
  FOR EACH ROW EXECUTE FUNCTION trg_incident_rejected_xp();

-- ── ROUTE FEEDBACK ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_feedback_submitted_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, 3);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_feedback_submitted_xp ON route_feedback;
CREATE TRIGGER trg_feedback_submitted_xp
  AFTER INSERT ON route_feedback
  FOR EACH ROW EXECUTE FUNCTION trg_feedback_submitted_xp();

CREATE OR REPLACE FUNCTION trg_feedback_accepted_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'applied'
     AND OLD.status IS DISTINCT FROM 'applied'
     AND NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, 10);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_feedback_accepted_xp ON route_feedback;
CREATE TRIGGER trg_feedback_accepted_xp
  AFTER UPDATE OF status ON route_feedback
  FOR EACH ROW EXECUTE FUNCTION trg_feedback_accepted_xp();

-- ── ROUTE SUGGESTIONS ───────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_suggestion_created_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, 5);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_suggestion_created_xp ON route_suggestions;
CREATE TRIGGER trg_suggestion_created_xp
  AFTER INSERT ON route_suggestions
  FOR EACH ROW EXECUTE FUNCTION trg_suggestion_created_xp();

CREATE OR REPLACE FUNCTION trg_suggestion_verified_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'accepted'
     AND OLD.status IS DISTINCT FROM 'accepted'
     AND NEW.author_id IS NOT NULL THEN
    PERFORM add_xp(NEW.author_id, 20);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_suggestion_verified_xp ON route_suggestions;
CREATE TRIGGER trg_suggestion_verified_xp
  AFTER UPDATE OF status ON route_suggestions
  FOR EACH ROW EXECUTE FUNCTION trg_suggestion_verified_xp();

CREATE OR REPLACE FUNCTION trg_suggestion_vote_xp() RETURNS TRIGGER AS $$
DECLARE
  author UUID;
BEGIN
  SELECT author_id INTO author FROM route_suggestions WHERE id = NEW.suggestion_id;
  IF author IS NOT NULL AND author <> NEW.voter_id THEN
    PERFORM add_xp(author, 2);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_suggestion_vote_xp ON route_suggestion_votes;
CREATE TRIGGER trg_suggestion_vote_xp
  AFTER INSERT ON route_suggestion_votes
  FOR EACH ROW EXECUTE FUNCTION trg_suggestion_vote_xp();

-- ── USER ROUTE REPORTS (duplicateReport) ───────────────────
CREATE OR REPLACE FUNCTION trg_duplicate_report_xp() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.reason = 'duplicated' AND NEW.reporter_id IS NOT NULL THEN
    PERFORM add_xp(NEW.reporter_id, 1);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_duplicate_report_xp ON user_route_reports;
CREATE TRIGGER trg_duplicate_report_xp
  AFTER INSERT ON user_route_reports
  FOR EACH ROW EXECUTE FUNCTION trg_duplicate_report_xp();
