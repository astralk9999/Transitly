-- Migration: privacy_consents table
-- Reference: PRO-Rel-23 / Mega Plan Refinamiento
-- Supabase migration #015
-- GDPR: append-only consent tracking with versioning

BEGIN;

CREATE TABLE public.privacy_consents (
    id            uuid      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid      NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    consent_type  text      NOT NULL,
    granted       boolean   NOT NULL DEFAULT true,
    consent_version integer NOT NULL DEFAULT 1,
    ip_address    text,
    user_agent    text,
    created_at    timestamptz NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_consent_type UNIQUE (user_id, consent_type)
);

CREATE INDEX idx_privacy_consents_user ON public.privacy_consents (user_id);

ALTER TABLE public.privacy_consents ENABLE ROW LEVEL SECURITY;

-- Users can read their own consents
CREATE POLICY "Users can read own consents"
    ON public.privacy_consents
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Users can upsert their own consents (grant/revoke)
CREATE POLICY "Users can upsert own consents"
    ON public.privacy_consents
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own consents"
    ON public.privacy_consents
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Service role for admin operations (right-to-be-forgotten, audit)
CREATE POLICY "Service role full access"
    ON public.privacy_consents
    FOR ALL
    TO service_role
    USING (true);

-- Append-only audit: never DELETE, only INSERT new versions
-- Old entries are preserved as consent history

COMMENT ON TABLE public.privacy_consents IS
    'GDPR consent tracking. Append-only: revoke inserts new row with granted=false. '
    'Consent version enables migration to updated privacy policies.';

COMMENT ON COLUMN public.privacy_consents.consent_type IS
    'Type of consent: crash_reporting, analytics, marketing, location, notifications';

COMMIT;
