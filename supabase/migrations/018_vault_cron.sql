-- =============================================================
-- 018_vault_cron.sql — Cron diario de borrado de cuenta vía Vault
-- =============================================================
-- Elimina perfiles y datos de usuarios que solicitaron borrado
-- hace 30+ días.
--
-- Manual setup en Dashboard (UNA SOLA VEZ):
-- 1. Settings → API → copiar service_role secret
-- 2. Database → Vault → New Secret
--    Name: service_role_key
--    Secret: pegar la clave real
-- 3. Save
-- =============================================================

-- Extensiones necesarias (deberían existir ya)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Función que elimina cuentas expiradas
CREATE OR REPLACE FUNCTION process_account_deletions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT user_id
    FROM data_deletion_requests
    WHERE status = 'pending'
      AND scheduled_at <= NOW()
      AND completed_at IS NULL
  LOOP
    BEGIN
      -- Eliminar datos del usuario
      DELETE FROM user_preferences WHERE user_id = rec.user_id;
      DELETE FROM device_tokens WHERE user_id = rec.user_id;
      DELETE FROM notifications WHERE user_id = rec.user_id;
      DELETE FROM offline_regions WHERE user_id = rec.user_id;
      DELETE FROM privacy_consents WHERE user_id = rec.user_id;
      DELETE FROM data_exports WHERE user_id = rec.user_id;
      DELETE FROM user_route_votes WHERE voter_id = rec.user_id;
      DELETE FROM user_route_reports WHERE reporter_id = rec.user_id;
      DELETE FROM user_route_views WHERE viewer_id = rec.user_id;
      -- Anonimizar user_routes: marcar author_id como null
      UPDATE user_routes SET author_id = NULL WHERE author_id = rec.user_id;
      UPDATE user_stops SET author_id = NULL WHERE author_id = rec.user_id;
      UPDATE incidents SET author_id = NULL WHERE author_id = rec.user_id;
      UPDATE route_feedback SET author_id = NULL WHERE author_id = rec.user_id;
      UPDATE route_suggestions SET author_id = NULL WHERE author_id = rec.user_id;
      UPDATE feature_requests SET author_id = NULL WHERE author_id = rec.user_id;
      -- Eliminar perfil
      DELETE FROM profiles WHERE id = rec.user_id;
      -- Marcar como completado
      UPDATE data_deletion_requests
      SET status = 'completed', completed_at = NOW()
      WHERE user_id = rec.user_id;
    EXCEPTION WHEN OTHERS THEN
      INSERT INTO audit_log (actor_id, action, target_kind, target_id, payload)
      VALUES (NULL, 'delete_account_error', 'user', rec.user_id,
              jsonb_build_object('error', SQLERRM));
    END;
  END LOOP;
END;
$$;

-- Programar cron: ejecutar cada día a las 03:00 UTC
SELECT cron.schedule(
  'process-account-deletions',
  '0 3 * * *',
  $$SELECT process_account_deletions();$$
);
