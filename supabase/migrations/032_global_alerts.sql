-- 032_global_alerts.sql — avisos globales + segmentación + broadcast
--
-- Extiende geo_alerts para soportar avisos sin ubicación (globales),
-- con expiración, programación, segmentación por rol y URL de acción.
-- Añade una RPC admin_broadcast_alert que inserta una notificación a
-- cada destinatario para disparar push/in-app inmediatos.

ALTER TABLE geo_alerts
  ADD COLUMN IF NOT EXISTS is_global BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS target_role TEXT,
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS action_url TEXT;

CREATE INDEX IF NOT EXISTS geo_alerts_global_active_idx
  ON geo_alerts(is_global, active)
  WHERE is_global = true AND active = true;

ALTER TABLE geo_alerts ALTER COLUMN center_lat DROP NOT NULL;
ALTER TABLE geo_alerts ALTER COLUMN center_lng DROP NOT NULL;
ALTER TABLE geo_alerts ALTER COLUMN radius_m DROP NOT NULL;

CREATE OR REPLACE FUNCTION admin_broadcast_alert(p_alert_id UUID)
RETURNS INT AS $$
DECLARE
  v_alert RECORD;
  v_count INT := 0;
  v_payload JSONB;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Solo admins pueden difundir avisos';
  END IF;
  SELECT * INTO v_alert FROM geo_alerts WHERE id = p_alert_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Aviso no encontrado';
  END IF;

  v_payload := jsonb_build_object(
    'title', v_alert.title,
    'body', v_alert.body,
    'severity', v_alert.severity::text,
    'alert_id', v_alert.id,
    'kind', CASE WHEN v_alert.is_global THEN 'global_alert' ELSE 'geo_alert' END,
    'action_url', v_alert.action_url
  );

  INSERT INTO notifications (user_id, type, payload)
  SELECT p.id, 'custom', v_payload
  FROM profiles p
  WHERE
    (v_alert.target_role IS NULL OR p.role::text = v_alert.target_role)
    AND p.is_banned = false;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin_broadcast_alert(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_broadcast_alert(UUID) TO authenticated;
