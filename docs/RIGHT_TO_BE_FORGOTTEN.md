# Right to be Forgotten — Transitly

> **Version:** 1.0 · **Compliance:** GDPR Art. 17 / LOPDGDD · **Owner:** Platform

## Legal Basis

Under GDPR Article 17, users have the right to request deletion of their
personal data. Transitly complies by providing a documented, auditable
procedure for data erasure.

---

## Request Flow

1. **User submits request** via email to `privacy@transitly.app` with subject
   "Right to be Forgotten — [user email]".
2. **Identity verification**: operator confirms the email matches the
   requesting user's registered email.
3. **Data deletion**: execute the SQL script below.
4. **Confirmation**: reply to user within 30 days confirming deletion.
5. **Audit log**: record the deletion in `audit_log` table with timestamp.

---

## Deletion Procedure

### SQL Script

```sql
-- Right to be Forgotten for user_id = <UUID>
-- Execute as Supabase service_role

BEGIN;

-- 1. Anonymize contributions (keep for community integrity)
UPDATE public.incidents SET user_id = NULL WHERE user_id = '<UUID>';
UPDATE public.route_feedback SET author_id = NULL WHERE author_id = '<UUID>';
UPDATE public.route_suggestions SET author_id = NULL WHERE author_id = '<UUID>';
UPDATE public.feature_requests SET author_id = NULL WHERE author_id = '<UUID>';

-- 2. Delete personal data
DELETE FROM public.user_preferences WHERE user_id = '<UUID>';
DELETE FROM public.offline_regions WHERE user_id = '<UUID>';
DELETE FROM public.app_notifications WHERE user_id = '<UUID>';
DELETE FROM public.user_favorites WHERE user_id = '<UUID>';
DELETE FROM public.user_achievements WHERE user_id = '<UUID>';
DELETE FROM public.trip_history WHERE user_id = '<UUID>';
DELETE FROM public.habitual_trips WHERE user_id = '<UUID>';
DELETE FROM public.driver_operators WHERE user_id = '<UUID>';
DELETE FROM public.driver_invitation_codes WHERE created_by = '<UUID>';

-- 3. Delete profile
DELETE FROM public.profiles WHERE id = '<UUID>';

-- 4. Delete auth account
-- Via Supabase Dashboard → Authentication → Users → Delete
-- Or: SELECT auth.admin_delete_user('<UUID>');

-- 5. Record audit entry
INSERT INTO public.audit_log (action, actor_id, target_id, details, created_at)
VALUES ('right_to_be_forgotten', '<UUID>', '<UUID>',
        jsonb_build_object('reason', 'GDPR Art. 17 user request'),
        NOW());

COMMIT;
```

### Storage Cleanup

- Delete user avatars: `DELETE FROM storage.objects WHERE bucket_id='avatars' AND name LIKE '<UUID>%'`
- Delete user uploaded images from `incident_photos` bucket

---

## RPC Function

```sql
CREATE OR REPLACE FUNCTION public.execute_right_to_be_forgotten(
  p_user_id uuid
) RETURNS text AS $$
DECLARE
  result text;
BEGIN
  -- Check caller is service_role
  IF NOT (SELECT auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'Only service_role can execute this';
  END IF;

  -- Anonymize
  UPDATE public.incidents SET user_id = NULL WHERE user_id = p_user_id;
  UPDATE public.route_feedback SET author_id = NULL WHERE author_id = p_user_id;
  UPDATE public.route_suggestions SET author_id = NULL WHERE author_id = p_user_id;
  UPDATE public.feature_requests SET author_id = NULL WHERE author_id = p_user_id;

  -- Delete
  DELETE FROM public.user_preferences WHERE user_id = p_user_id;
  DELETE FROM public.offline_regions WHERE user_id = p_user_id;
  DELETE FROM public.app_notifications WHERE user_id = p_user_id;
  DELETE FROM public.user_favorites WHERE user_id = p_user_id;
  DELETE FROM public.user_achievements WHERE user_id = p_user_id;
  DELETE FROM public.trip_history WHERE user_id = p_user_id;
  DELETE FROM public.habitual_trips WHERE user_id = p_user_id;
  DELETE FROM public.driver_operators WHERE user_id = p_user_id;
  DELETE FROM public.driver_invitation_codes WHERE created_by = p_user_id;
  DELETE FROM public.profiles WHERE id = p_user_id;

  -- Audit
  INSERT INTO public.audit_log (action, actor_id, target_id, details, created_at)
  VALUES ('right_to_be_forgotten', p_user_id, p_user_id,
          jsonb_build_object('timestamp', NOW()),
          NOW());

  RETURN 'User data deleted: ' || p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Response Template

```
Subject: Re: Right to be Forgotten — [email]

Dear [User],

We have processed your request under GDPR Article 17.
Your personal data has been deleted from Transitly as of [date].

The following data was deleted:
- Profile and account information
- Preferences and settings
- Trip history and favorites
- Driver associations

Contributions you made to the community (incident reports, route
suggestions) have been anonymized — they remain visible to other
users without any link to your identity.

If you have any questions, contact privacy@transitly.app.

— Transitly Team
```

## Timestamping

Each deletion is recorded in the `audit_log` table:

| Field | Value |
|-------|-------|
| `action` | `right_to_be_forgotten` |
| `actor_id` | User UUID |
| `target_id` | User UUID |
| `details` | `{"timestamp": "2026-05-22T..."}` |
| `created_at` | Server timestamp |
