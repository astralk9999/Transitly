-- Migration: audit_log table for admin actions
-- Reference: PRO-Ops-28 / Mega Plan Refinamiento
-- Supabase migration #014

BEGIN;

CREATE TABLE public.audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action      text        NOT NULL,
    actor_id    uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
    target_id   uuid,
    details     jsonb       DEFAULT '{}'::jsonb,
    created_at  timestamptz NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_action    ON public.audit_log (action);
CREATE INDEX idx_audit_log_actor     ON public.audit_log (actor_id);
CREATE INDEX idx_audit_log_created   ON public.audit_log (created_at DESC);

-- RLS: only admins can read; inserts via service_role only
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read audit log"
    ON public.audit_log
    FOR SELECT
    TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND 'admin' = ANY(roles)
    ));

CREATE POLICY "Service role can insert audit entries"
    ON public.audit_log
    FOR INSERT
    TO service_role
    WITH CHECK (true);

COMMENT ON TABLE public.audit_log IS
    'Immutable audit trail for administrative actions. '
    'Written by service_role (Edge Functions, RPC). Read by admins.';

-- Helper function to insert audit entry
CREATE OR REPLACE FUNCTION public.log_audit_event(
    p_action    text,
    p_actor_id  uuid DEFAULT NULL,
    p_target_id uuid DEFAULT NULL,
    p_details   jsonb DEFAULT '{}'::jsonb
) RETURNS bigint AS $$
DECLARE
    v_id bigint;
BEGIN
    INSERT INTO public.audit_log (action, actor_id, target_id, details)
    VALUES (p_action, p_actor_id, p_target_id, p_details)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
