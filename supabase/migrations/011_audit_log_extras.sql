-- Migration: audit_log extras (indexes + helper)
-- Reference: PRO-Ops-28 / Mega Plan Refinamiento
-- Supabase migration #011
-- Table audit_log created in 001_init.sql; RLS in 002_rls.sql.
-- This migration adds performance indexes and the log_audit_event()
-- helper (adapted to 001 schema: payload + target_kind).

BEGIN;

-- Additional indexes (idx_audit_actor_time exists already in 001).
CREATE INDEX IF NOT EXISTS idx_audit_log_action  ON public.audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor   ON public.audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON public.audit_log (created_at DESC);

COMMENT ON TABLE public.audit_log IS
    'Immutable audit trail for administrative actions. '
    'Written by SECURITY DEFINER functions and service_role. Read by admins.';

-- Helper function to insert audit entry.
-- Adapted to 001_init.sql schema: uses payload (not details) + target_kind.
CREATE OR REPLACE FUNCTION public.log_audit_event(
    p_action      text,
    p_actor_id    uuid DEFAULT NULL,
    p_target_kind text DEFAULT NULL,
    p_target_id   uuid DEFAULT NULL,
    p_payload     jsonb DEFAULT '{}'::jsonb
) RETURNS void AS $$
BEGIN
    INSERT INTO public.audit_log (action, actor_id, target_kind, target_id, payload)
    VALUES (p_action, p_actor_id, p_target_kind, p_target_id, p_payload);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.log_audit_event(text, uuid, text, uuid, jsonb) IS
    'Inserts an audit log entry. Written by SECURITY DEFINER functions and service_role.';

COMMIT;
