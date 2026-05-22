# Runbook: Supabase Outage

> **Severity:** P1 · **Owner:** Platform · **Version:** 1.0

## Symptoms

- Users report "Sin conexión" or blank screens on authenticated features
- `supabase_flutter` throws `SocketException` or timeout errors
- Supabase status page (https://status.supabase.com) shows degradation
- Sentry spike in `network` errors

## Immediate actions (first 5 minutes)

1. **Verify the outage:**
   ```bash
   curl -s https://mmzahxtiaurkgtmtehxk.supabase.co/rest/v1/ > /dev/null
   ```
2. **Check Supabase status:** https://status.supabase.com
3. **Check our project health:** Supabase Dashboard → project `mmzahxtiaurkgtmtehxk` → Reports

## If Supabase is up but our project is down

1. Check RLS policies: no recent migration could have locked out users
2. Verify `anon_key` is still valid → `_granted_roles` in JWT
3. Check rate limits: `429 Too Many Requests` → review query patterns
4. Restart the project from Supabase Dashboard if unresponsive

## If Supabase itself is down

1. **Activate incident banner** in-app (see `docs/architecture/` → incident banner)
2. **Post to status page** (if configured)
3. **Communicate to users:** the app operates in offline mode with Hive cache
4. **No action needed on client:** offline-first architecture handles this

## Rollback / Mitigation

- The app already falls back to Hive cache when Supabase is unreachable
- Offline queue preserves pending writes for replay when restored
- Mock data is available for guest/unauthenticated users

## Postmortem

After resolution (within 48h):
1. Timeline of events
2. Root cause
3. Impact: users affected, duration, data loss
4. Action items to prevent recurrence
