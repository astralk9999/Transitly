-- =============================================================
-- 007_notification_triggers.sql — In-app notification triggers
-- =============================================================
-- F12.3 (previously missing). Inserta directamente en la tabla
-- `notifications` cuando ocurren eventos que el usuario debe ver
-- en su bandeja de notificaciones dentro de la app.
--
-- Los triggers push (FCM) van en 015_push_triggers.sql e invocan
-- la Edge Function send_notification via pg_net.
--
-- Eventos cubiertos:
--   1. AFTER INSERT ON incidents       → notifica al owner de la ruta
--   2. AFTER INSERT ON route_feedback  → si status = 'applied'
--   3. AFTER INSERT ON route_suggestions → si status = 'accepted'
--   4. AFTER INSERT ON route_shares    → notifica al destinatario

-- =============================================================
-- 1. Nueva incidencia → notificar al dueño de la ruta
-- =============================================================
CREATE OR REPLACE FUNCTION trg_incident_inapp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_owner_id UUID;
  v_route_name TEXT;
BEGIN
  IF NEW.route_id IS NOT NULL THEN
    SELECT owner_id, name INTO v_owner_id, v_route_name
    FROM routes WHERE id = NEW.route_id;

    IF v_owner_id IS NOT NULL AND v_owner_id IS DISTINCT FROM NEW.author_id THEN
      INSERT INTO notifications (user_id, type, payload)
      VALUES (
        v_owner_id,
        'custom',
        jsonb_build_object(
          'title', format('Nueva incidencia en %s',
                          COALESCE(v_route_name, 'tu ruta')),
          'body', format('Se ha reportado %s.', NEW.kind::text),
          'incident_id', NEW.id,
          'route_id', NEW.route_id,
          'kind', NEW.kind
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_incident_inapp_insert ON incidents;
CREATE TRIGGER trg_incident_inapp_insert
  AFTER INSERT ON incidents
  FOR EACH ROW
  EXECUTE FUNCTION trg_incident_inapp();

-- =============================================================
-- 2. Feedback aplicado → notificar al autor
-- =============================================================
CREATE OR REPLACE FUNCTION trg_feedback_applied_inapp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.status = 'applied' AND NEW.author_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, payload)
    VALUES (
      NEW.author_id,
      'custom',
      jsonb_build_object(
        'title', 'Feedback aplicado',
        'body', 'Tu sugerencia de mejora ha sido aplicada.',
        'feedback_id', NEW.id,
        'route_id', NEW.route_id,
        'kind', NEW.kind
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_feedback_applied_inapp ON route_feedback;
CREATE TRIGGER trg_feedback_applied_inapp
  AFTER INSERT ON route_feedback
  FOR EACH ROW
  EXECUTE FUNCTION trg_feedback_applied_inapp();

-- =============================================================
-- 3. Sugerencia de ruta aceptada → notificar al autor
-- =============================================================
CREATE OR REPLACE FUNCTION trg_suggestion_accepted_inapp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.status = 'accepted' AND NEW.author_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, payload)
    VALUES (
      NEW.author_id,
      'custom',
      jsonb_build_object(
        'title', 'Sugerencia de ruta aceptada',
        'body', 'Tu sugerencia de nueva ruta ha sido aceptada.',
        'suggestion_id', NEW.id
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_suggestion_accepted_inapp ON route_suggestions;
CREATE TRIGGER trg_suggestion_accepted_inapp
  AFTER INSERT ON route_suggestions
  FOR EACH ROW
  EXECUTE FUNCTION trg_suggestion_accepted_inapp();

-- =============================================================
-- 4. Ruta compartida → notificar al destinatario (in-app)
-- =============================================================
CREATE OR REPLACE FUNCTION trg_route_share_inapp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_sharer_name TEXT;
  v_route_name  TEXT;
BEGIN
  SELECT display_name INTO v_sharer_name
  FROM profiles WHERE id = NEW.shared_by_id;

  SELECT name INTO v_route_name
  FROM routes WHERE id = NEW.route_id;

  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    NEW.shared_with_id,
    'share_received',
    jsonb_build_object(
      'title', 'Ruta compartida contigo',
      'body', format('%s ha compartido la ruta "%s" contigo.',
                     COALESCE(v_sharer_name, 'Alguien'),
                     COALESCE(v_route_name, 'desconocida')),
      'route_id', NEW.route_id,
      'shared_by_id', NEW.shared_by_id
    )
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_route_share_inapp_insert ON route_shares;
CREATE TRIGGER trg_route_share_inapp_insert
  AFTER INSERT ON route_shares
  FOR EACH ROW
  EXECUTE FUNCTION trg_route_share_inapp();

-- =============================================================
-- Fin de 007_notification_triggers.sql
-- =============================================================
