# Disaster Recovery Plan — Transitly

> **Version:** 1.0 · **Owner:** Platform · **Review:** Quarterly

## Objectives

| Metric | Target |
|--------|:------:|
| **RPO** (Recovery Point Objective) | ≤ 1 hour |
| **RTO** (Recovery Time Objective) | ≤ 4 hours |
| **MTD** (Maximum Tolerable Downtime) | 24 hours |

---

## Disaster Scenarios

### 1. Supabase Region Outage

**Impact:** All authenticated features unavailable. Guest mode (mock data) works.

**RPO:** ≤ 1 hour (last Supabase Point-in-Time Recovery snapshot).
**RTO:** ≤ 4 hours (restore from PITR to a new region).

**Recovery steps:**
1. Verify outage: https://status.supabase.com + project dashboard
2. If > 30 minutes, initiate PITR restore via Supabase Dashboard
3. Select target region (e.g., eu-west-2 → eu-central-1)
4. Update `SUPABASE_URL` in `--dart-define` in CI secrets
5. Rebuild and deploy app with new URL
6. Notify users via status page

**Client fallback:** App operates in offline mode with Hive cache. Writes
are queued via `PendingActionsQueue` and replayed when restored.

### 2. Database Corruption

**Impact:** Data integrity compromised. Users see incorrect data.

**RPO:** ≤ 1 hour.
**RTO:** ≤ 4 hours.

**Recovery steps:**
1. Stop all Edge Functions and client writes
2. Identify last known good state from PITR timeline
3. Restore database to point before corruption
4. Replay `audit_log` to verify integrity
5. Resume operations
6. Run migration verification: `supabase db reset --local` + `supabase test db`

### 3. Edge Function Failure

**Impact:** `send_notification` or `import_gtfs` unavailable.

**RPO:** 0 (stateless, no data loss).
**RTO:** ≤ 1 hour.

**Recovery steps:**
1. Check function logs in Supabase Dashboard
2. Rollback to previous deployment:
   ```bash
   supabase functions deploy send_notification --source-ref <commit>
   ```
3. If Deno runtime issue, escalate to Supabase support
4. Client gracefully degrades: in-app inbox replaces push

### 4. Compromised Service Role Key

**Impact:** Unauthorized data access possible.

**RPO:** 0 (key rotation).
**RTO:** ≤ 1 hour.

**Recovery steps:**
1. Rotate `service_role` key in Supabase Dashboard → API
2. Revoke all active tokens
3. Update secrets in GitHub (`SUPABASE_SERVICE_ROLE_KEY`)
4. Deploy Edge Functions with new key
5. Audit `audit_log` for unauthorized access during compromise window

---

## Backup Strategy

| Component | Backup method | Frequency | Retention |
|-----------|:------------:|:---------:|:---------:|
| PostgreSQL | Supabase PITR | Continuous | 7 days |
| Storage objects | Supabase backups | Daily | 30 days |
| Edge Functions | Git (code) | On push | Indefinite |
| Migrations | Git (`supabase/migrations/`) | On commit | Indefinite |
| CI secrets | GitHub encrypted | On update | Last 5 versions |

---

## Testing

- **Quarterly DR drill:** Simulate Supabase outage by stopping the project and
  verifying offline mode + cache recovery.
- **Migration rollback test:** Apply + rollback each migration in local
  environment. See `docs/runbooks/migration_rollback.md`.
- **PITR restore test:** Verify the Supabase Dashboard can restore to a point
  in time.

---

## Contact

| Role | Method | Response |
|------|--------|:--------:|
| Supabase Support | Dashboard → Help | < 1 hour (Pro plan) |
| Platform Engineer | Internal | < 30 min |
