# Migration Rollback Scripts — Transitly

> **Version:** 1.1 · **Last audited:** 2026-05-22

## Overview

Each migration has a corresponding rollback script to restore the previous
state in case of failed deployment. These are manual (not automated in CI)
because Supabase migrations are append-only.

## Migrations and Rollbacks

### 001_init.sql — Core schema
```sql
-- ROLLBACK: Drop all core tables
BEGIN;
DROP TABLE IF EXISTS public.feature_request_votes CASCADE;
DROP TABLE IF EXISTS public.suggestion_votes CASCADE;
DROP TABLE IF EXISTS public.user_favorites CASCADE;
DROP TABLE IF EXISTS public.user_achievements CASCADE;
DROP TABLE IF EXISTS public.achievements CASCADE;
DROP TABLE IF EXISTS public.app_notifications CASCADE;
DROP TABLE IF EXISTS public.trip_history CASCADE;
DROP TABLE IF EXISTS public.habitual_trips CASCADE;
DROP TABLE IF EXISTS public.bus_positions CASCADE;
DROP TABLE IF EXISTS public.schedules CASCADE;
DROP TABLE IF EXISTS public.route_stops CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.stops CASCADE;
DROP TABLE IF EXISTS public.operators CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
COMMIT;
```

### 002_rls.sql — RLS policies
```sql
-- ROLLBACK: Disable RLS on all tables (policies are dropped automatically)
ALTER TABLE operators                DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles                 DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_assignments       DISABLE ROW LEVEL SECURITY;
ALTER TABLE invitation_codes         DISABLE ROW LEVEL SECURITY;
ALTER TABLE stops                    DISABLE ROW LEVEL SECURITY;
ALTER TABLE routes                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops              DISABLE ROW LEVEL SECURITY;
ALTER TABLE schedules                DISABLE ROW LEVEL SECURITY;
ALTER TABLE bus_positions            DISABLE ROW LEVEL SECURITY;
ALTER TABLE incidents                DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_feedback           DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_suggestions        DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_suggestion_votes   DISABLE ROW LEVEL SECURITY;
ALTER TABLE feature_requests         DISABLE ROW LEVEL SECURITY;
ALTER TABLE feature_request_votes    DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_shares             DISABLE ROW LEVEL SECURITY;
ALTER TABLE route_public_links       DISABLE ROW LEVEL SECURITY;
ALTER TABLE offline_regions          DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences         DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications            DISABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log                DISABLE ROW LEVEL SECURITY;
ALTER TABLE gtfs_imports             DISABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_consents         DISABLE ROW LEVEL SECURITY;
ALTER TABLE data_exports             DISABLE ROW LEVEL SECURITY;
ALTER TABLE data_deletion_requests   DISABLE ROW LEVEL SECURITY;

DROP FUNCTION IF EXISTS public.is_admin();
DROP FUNCTION IF EXISTS public.is_moderator_or_admin();
DROP FUNCTION IF EXISTS public.is_driver_of(UUID);
DROP FUNCTION IF EXISTS public.is_operator_admin_of(UUID);
```

### 003_rls_fixes.sql — RLS linter fixes
```sql
-- ROLLBACK: Re-grant EXECUTE on handle_new_user (undo revokes)
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO PUBLIC, anon, authenticated;

-- touch_updated_at and cleanup_expired_bus_positions search_path change
-- is additive (does not break existing behavior). No structural rollback
-- needed; the previous definitions without SET search_path were equivalent
-- in practice. Restore original definitions:
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_expired_bus_positions()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM bus_positions
  WHERE expires_at IS NOT NULL
    AND expires_at < NOW() - INTERVAL '1 hour';
END;
$$;
```

### 007_invitation_helpers.sql — Driver invite helpers
```sql
-- ROLLBACK
BEGIN;
DROP FUNCTION IF EXISTS public.create_invitation_code(UUID, INT, TIMESTAMPTZ, invitation_kind);
DROP FUNCTION IF EXISTS public.revoke_driver(UUID, UUID);
COMMIT;
```

### 007_notification_triggers.sql — Notification triggers
```sql
-- ROLLBACK: Drop notification-related triggers and functions
-- (triggers for incident/feedback/suggestion notifications to recipients)
-- Check the actual trigger names in the migration file before running.
-- Common pattern:
--   DROP TRIGGER IF EXISTS <trigger_name> ON <table>;
--   DROP FUNCTION IF EXISTS <function_name>;
```

### 012_reputation.sql — Reputation system
```sql
-- ROLLBACK: Drop reputation triggers and function
BEGIN;
DROP TRIGGER IF EXISTS trg_incident_reputation_after ON incidents;
DROP TRIGGER IF EXISTS trg_feedback_reputation_after ON route_feedback;
DROP TRIGGER IF EXISTS trg_suggestion_reputation_after ON route_suggestions;
DROP FUNCTION IF EXISTS trg_incident_reputation();
DROP FUNCTION IF EXISTS trg_feedback_reputation();
DROP FUNCTION IF EXISTS trg_suggestion_reputation();
DROP FUNCTION IF EXISTS recompute_reputation(UUID);
COMMIT;
```

### 013_offline_export.sql — Offline region export RPC
```sql
-- ROLLBACK
BEGIN;
DROP FUNCTION IF EXISTS public.export_region_data(
  DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION,
  DOUBLE PRECISION, INT, INT
);
COMMIT;
```

### 014_audit_log.sql — Audit log table
```sql
-- ROLLBACK
BEGIN;
DROP FUNCTION IF EXISTS public.log_audit_event(TEXT, UUID, UUID, JSONB);
DROP TABLE IF EXISTS public.audit_log CASCADE;
COMMIT;
```

### 014_push_tokens.sql — Device push tokens
```sql
-- ROLLBACK
BEGIN;
DROP TABLE IF EXISTS device_tokens CASCADE;
COMMIT;
```

### 015_privacy_consents.sql — GDPR consent tracking
```sql
-- ROLLBACK: Table created in 001_init.sql but policies and constraints
-- are managed here. If the table needs removal, drop via 001 rollback.
-- To only undo this migration's policies:
ALTER TABLE public.privacy_consents DISABLE ROW LEVEL SECURITY;
```

### 015_push_triggers.sql — Push notification triggers (pg_net)
```sql
-- ROLLBACK
BEGIN;
DROP TRIGGER IF EXISTS trg_incident_resolved_push_upd ON incidents;
DROP TRIGGER IF EXISTS trg_route_share_push_ins ON route_shares;
DROP TRIGGER IF EXISTS trg_route_official_push_upd ON routes;
DROP FUNCTION IF EXISTS trg_incident_resolved_push();
DROP FUNCTION IF EXISTS trg_route_share_push();
DROP FUNCTION IF EXISTS trg_route_official_push();
DROP FUNCTION IF EXISTS invoke_send_notification(UUID, TEXT, TEXT, TEXT, JSONB, TEXT);
DROP FUNCTION IF EXISTS get_supabase_functions_url();
DROP FUNCTION IF EXISTS get_supabase_service_key();
COMMIT;
```

### 016_data_exports.sql — GDPR export/deletion functions
```sql
-- ROLLBACK
BEGIN;
DROP FUNCTION IF EXISTS public.request_data_export();
DROP FUNCTION IF EXISTS public.request_data_deletion();
DROP INDEX IF EXISTS idx_data_exports_user_status;
DROP INDEX IF EXISTS idx_data_deletion_requests_user_status;
COMMIT;
```

---

## Rollback Procedure

1. **Identify the migration to roll back**: check `supabase/migrations/` for the
   file name.
2. **Execute the rollback SQL** via Supabase SQL Editor or `supabase db push`
   with the rollback script.
3. **Verify**: run `supabase db reset --local` and verify the local DB matches
   the expected state before the migration.
4. **Commit**: `git revert` the migration commit if it was already pushed.

## Seed Data Reset

> **Nota:** No hay `seed.sql` en las migraciones — los datos mock se cargan
> desde `assets/mock/comujesa_data.json` vía `MockDataService` en cliente.

```bash
# Reset local Supabase to clean state
supabase db reset --local

# Re-apply migrations
supabase db push
```
