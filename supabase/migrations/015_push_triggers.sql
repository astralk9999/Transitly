-- =============================================================
-- 015_push_triggers.sql — Push notification triggers (pg_net)
-- =============================================================
-- F21. Triggers que invocan la Edge Function send_notification
-- via pg_net para entregar push + in-app de forma asíncrona.
--
-- Requisito previo:
--   El service role key debe estar almacenado en Vault:
--     SELECT vault.create_secret('<service_role_key>', 'service_role_key');
--
--   La extensión pg_net se habilita automáticamente abajo.
--
-- Eventos cubiertos:
--   1. AFTER UPDATE ON incidents   → status IN ('resolved','rejected')
--   2. AFTER INSERT ON route_shares → notifica al destinatario
--   3. AFTER UPDATE ON routes      → source = 'official' (ruta promovida)

-- =============================================================
-- 0. Extensión pg_net + helper
-- =============================================================
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

-- Helper que obtiene el service role key desde Vault.
-- Si Vault no está configurado, intenta current_setting como fallback.
CREATE OR REPLACE FUNCTION get_supabase_service_key()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key TEXT;
BEGIN
  -- Primero intenta Vault
  BEGIN
    SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
    WHERE name = 'service_role_key'
    LIMIT 1;
    IF v_key IS NOT NULL THEN
      RETURN v_key;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

  -- Fallback: setting de base de datos
  v_key := current_setting('app.settings.service_role_key', true);
  IF v_key IS NOT NULL AND v_key != '' THEN
    RETURN v_key;
  END IF;

  RAISE WARNING 'service_role_key not found in vault or settings';
  RETURN '';
END;
$$;

-- Helper que obtiene la base URL de las Edge Functions sin hardcodear
-- el project-ref. Orden: Vault ('functions_url') → setting de BD
-- ('app.settings.functions_url'). Devuelve '' si no está configurado;
-- el caller debe abortar la invocación en ese caso.
CREATE OR REPLACE FUNCTION get_supabase_functions_url()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_url TEXT;
BEGIN
  BEGIN
    SELECT decrypted_secret INTO v_url
    FROM vault.decrypted_secrets
    WHERE name = 'functions_url'
    LIMIT 1;
    IF v_url IS NOT NULL AND v_url != '' THEN
      RETURN rtrim(v_url, '/');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

  v_url := current_setting('app.settings.functions_url', true);
  IF v_url IS NOT NULL AND v_url != '' THEN
    RETURN rtrim(v_url, '/');
  END IF;

  RAISE WARNING 'functions_url not found in vault or settings';
  RETURN '';
END;
$$;

-- Helper que invoca la Edge Function de forma asíncrona.
-- Los errores de red NO revierten la transacción disparadora.
CREATE OR REPLACE FUNCTION invoke_send_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT DEFAULT 'custom',
  p_data JSONB DEFAULT '{}'::jsonb,
  p_deeplink TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_url TEXT;
  v_key TEXT;
  v_req_id BIGINT;
BEGIN
  v_key := get_supabase_service_key();
  IF v_key = '' THEN
    RAISE WARNING 'Cannot invoke send_notification: service_role_key missing';
    RETURN;
  END IF;

  -- Construir URL de la Edge Function sin hardcodear el project-ref.
  v_url := get_supabase_functions_url();
  IF v_url = '' THEN
    RAISE WARNING 'Cannot invoke send_notification: functions_url not configured';
    RETURN;
  END IF;
  v_url := v_url || '/send_notification';

  SELECT net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'user_id', p_user_id,
      'title', p_title,
      'body', p_body,
      'type', p_type,
      'data', p_data,
      'deeplink', p_deeplink
    )
  ) INTO v_req_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'invoke_send_notification failed: %', SQLERRM;
END;
$$;

-- =============================================================
-- 1. Incidente resuelto/rechazado → push al autor
-- =============================================================
CREATE OR REPLACE FUNCTION trg_incident_resolved_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.author_id IS NOT NULL
     AND NEW.status IN ('resolved', 'rejected')
     AND (OLD.status IS NULL OR OLD.status NOT IN ('resolved', 'rejected'))
  THEN
    PERFORM invoke_send_notification(
      NEW.author_id,
      CASE NEW.status
        WHEN 'resolved' THEN 'Incidencia resuelta'
        ELSE 'Incidencia rechazada'
      END,
      CASE NEW.status
        WHEN 'resolved' THEN 'Tu incidencia ha sido resuelta.'
        ELSE 'Tu incidencia ha sido rechazada.'
      END,
      'incident_resolved',
      jsonb_build_object(
        'incident_id', NEW.id,
        'kind', NEW.kind,
        'status', NEW.status
      ),
      format('/incidents/%s', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_incident_resolved_push_upd ON incidents;
CREATE TRIGGER trg_incident_resolved_push_upd
  AFTER UPDATE ON incidents
  FOR EACH ROW
  WHEN (NEW.status IN ('resolved', 'rejected'))
  EXECUTE FUNCTION trg_incident_resolved_push();

-- =============================================================
-- 2. Ruta compartida → push al destinatario
-- =============================================================
CREATE OR REPLACE FUNCTION trg_route_share_push()
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

  PERFORM invoke_send_notification(
    NEW.shared_with_id,
    'Ruta compartida contigo',
    format('%s ha compartido la ruta "%s" contigo.',
           COALESCE(v_sharer_name, 'Alguien'),
           COALESCE(v_route_name, 'desconocida')),
    'share_received',
    jsonb_build_object(
      'route_id', NEW.route_id,
      'shared_by_id', NEW.shared_by_id
    ),
    format('/routes/%s', NEW.route_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_route_share_push_ins ON route_shares;
CREATE TRIGGER trg_route_share_push_ins
  AFTER INSERT ON route_shares
  FOR EACH ROW
  EXECUTE FUNCTION trg_route_share_push();

-- =============================================================
-- 3. Ruta promovida a oficial (source = 'official') → push al owner
-- =============================================================
CREATE OR REPLACE FUNCTION trg_route_official_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.source = 'official'
     AND (OLD.source IS NULL OR OLD.source <> 'official')
  THEN
    -- Notificar al owner previo si existía
    IF OLD.owner_id IS NOT NULL THEN
      PERFORM invoke_send_notification(
        OLD.owner_id,
        'Ruta promovida a oficial',
        format('Tu ruta "%s" ha sido promovida a oficial.', NEW.name),
        'route_promoted',
        jsonb_build_object('route_id', NEW.id),
        format('/routes/%s', NEW.id)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_route_official_push_upd ON routes;
CREATE TRIGGER trg_route_official_push_upd
  AFTER UPDATE ON routes
  FOR EACH ROW
  WHEN (NEW.source = 'official')
  EXECUTE FUNCTION trg_route_official_push();

-- =============================================================
-- Fin de 015_push_triggers.sql
-- =============================================================
