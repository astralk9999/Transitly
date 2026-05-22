# Data Retention Policy — Transitly

> **Version:** 1.0 · **Effective:** 2026-05-22 · **Owner:** Platform team

## Scope

This policy defines how long Transitly retains user data and when it is purged.
It applies to all data stored in Supabase (PostgreSQL + Storage).

---

## Retention by Data Type

| Data type | Table / Bucket | Retention | Notes |
|-----------|---------------|:---------:|-------|
| User profiles | `profiles` | Until account deletion | Deleted on right-to-be-forgotten request |
| Authentication logs | Supabase GoTrue | 90 days | Managed by Supabase |
| Bus positions | `bus_positions` | **30 days** | Historical positions for analytics only |
| Incidents | `incidents` | 2 years | Anonymized after 2 years (user_id → NULL) |
| Route feedback | `route_feedback` | 2 years | Anonymized after 2 years |
| Route suggestions | `route_suggestions` | Indefinite | Public contribution; anonymized after 2 years |
| Feature requests | `feature_requests` | Indefinite | Public contribution; anonymized after 2 years |
| Notifications | `app_notifications` | 90 days | Auto-purged after 90 days |
| User preferences | `user_preferences` | Until account deletion | Deleted with user |
| Offline regions | `offline_regions` | Until account deletion | Deleted with user |
| Crash reports | Sentry | 90 days | Managed by Sentry retention settings |
| Analytics events | PostHog | 3 years | Aggregated, not individual |

---

## Purge Procedures

### Bus positions (30 days)

```sql
-- Purge bus_positions older than 30 days
-- Run monthly via pg_cron or Supabase scheduled function
DELETE FROM public.bus_positions
WHERE recorded_at < NOW() - INTERVAL '30 days';
```

Create an RPC function:

```sql
CREATE OR REPLACE FUNCTION public.purge_old_bus_positions()
RETURNS integer AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.bus_positions
  WHERE recorded_at < NOW() - INTERVAL '30 days';
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Notifications (90 days)

```sql
CREATE OR REPLACE FUNCTION public.purge_old_notifications()
RETURNS integer AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.app_notifications
  WHERE created_at < NOW() - INTERVAL '90 days';
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Anonymization (2 years)

```sql
-- Anonymize old contributions
UPDATE public.incidents
SET user_id = NULL
WHERE created_at < NOW() - INTERVAL '2 years' AND user_id IS NOT NULL;

UPDATE public.route_feedback
SET author_id = NULL
WHERE created_at < NOW() - INTERVAL '2 years' AND author_id IS NOT NULL;

UPDATE public.route_suggestions
SET author_id = NULL
WHERE created_at < NOW() - INTERVAL '2 years' AND author_id IS NOT NULL;
```

---

## Automated Purge Schedule

| Purge job | Frequency | RPC function |
|-----------|:---------:|-------------|
| Bus positions >30d | Daily | `purge_old_bus_positions()` |
| Notifications >90d | Weekly | `purge_old_notifications()` |
| Anonymization >2y | Monthly | Manual SQL script |
