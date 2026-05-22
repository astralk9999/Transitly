## Status: PROD-10 ✅ Documented

Backend scalability strategy documented. FORCE RLS, pooling, idempotency, GTFS streaming, and multi-region plans defined.

---

# Backend Scalability Plan — Transitly v2

> Supabase-hosted backend for Transitly. Project: `mmzahxtiaurkgtmtehxk`.

---

## 1. FORCE RLS Status

**Current: default-deny with RLS enabled on all public tables.**

- Migration `002_rls.sql` (F2.3) enables RLS on every table in `public` schema.
- Default behavior is DENY: every read/write operation requires an explicit policy.
- Policies are named `<table>_<action>_<who_or_when>` with `COMMENT ON POLICY` documenting intent.
- Helper functions (`is_admin()`, `is_driver()`, `is_operator_admin()`, `owns_*()`, `can_view_*()`) use `SECURITY DEFINER` and are NULL-safe (`auth.uid() IS NULL → false`).
- **FORCE RLS is NOT enabled on Supabase projects.** The Supabase platform's `service_role` key bypasses RLS by default. Tables rely on policy deny-by-default but `service_role` operations from Edge Functions have unrestricted access.
- If Supabase introduces FORCE RLS in the future, the migration would be additive: add `ALTER TABLE ... FORCE ROW LEVEL SECURITY` to `002_rls.sql` and restrict Edge Functions to use `authenticated` role with delegated headers.

### RLS role matrix (current)

| Role | `routes` read | `routes` write | `stops` read | `incidents` insert | `audit_log` read |
|------|:---:|:---:|:---:|:---:|:---:|
| `anon` | Public routes only | No | Public stops only | Yes (rate-limited) | No |
| `authenticated` (passenger) | All | No | All | Yes | Own only |
| `authenticated` (driver) | Assigned routes | Status updates | All | Yes | Own assignments |
| `authenticated` (operator_admin) | Own operator | Own operator | All | Yes | Own operator |
| `authenticated` (moderator) | All | Limited | All | Yes | All |
| `authenticated` (admin) | All | All | All | Yes | All |
| `service_role` | All (bypasses RLS) | All (bypasses RLS) | All | Yes | All |

---

## 2. Connection Pooling

### Supabase PgBouncer

Supabase projects use PgBouncer for connection pooling by default. Transitly uses:

- **Pool mode:** `transaction` (recommended by Supabase for serverless workloads).
- **Pool size:** default Supabase plan (15 direct connections + 200 pooled connections on Pro tier).
- **Client-side:** each Flutter client connects to Supabase REST API (PostgREST), not directly to PostgreSQL. The REST API layer pools internally.
- **Edge Functions:** use `supabase-js` service client, which creates short-lived connections per invocation.

### Dart/Flutter client behavior

- `SupabaseClient` in Flutter maintains a single persistent HTTP connection to PostgREST.
- No client-side connection pooling needed — the mobile app is single-user, single-connection.
- Stream subscriptions (`channel()`) use WebSocket connections, which Supabase's Realtime server multiplexes.

### Scaling thresholds

| Metric | Current | When to upgrade |
|--------|---------|-----------------|
| Concurrent users | <100 (testing) | >500 → Pro plan (more PgBouncer connections) |
| Realtime channels | ~5 per user | >100 per user → dedicated Realtime instance |
| REST requests/sec | <10 peak | >100 → consider read replicas |
| Edge Function invocations | <100/day | >10K/day → Supabase Team/Enterprise plan |

---

## 3. Edge Function Idempotency

### Patterns used

Supabase Edge Functions (Deno runtime) must handle retries from the Flutter client's offline queue (`OfflineSyncService`). Two idempotency strategies:

**A. Upsert-based (natural idempotency)**

Operations that use PostgreSQL `UPSERT` are inherently idempotent:

```sql
INSERT INTO public.route_feedback (id, user_id, route_id, feedback_type, body)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (id) DO NOTHING;
```

The `id` is a client-generated UUID, so re-submission after a timeout/no-response is safe.

**B. Idempotency key (explicit)**

For operations without natural upsert semantics (e.g., email sends, push notifications):

1. Client generates `x-idempotency-key` header (UUID v4).
2. Edge Function checks `public.idempotency_keys` table:
   ```sql
   SELECT 1 FROM public.idempotency_keys
   WHERE key = $1 AND created_at > NOW() - INTERVAL '24 hours';
   ```
3. If found → return cached response (200 with `x-idempotency-replay: true`).
4. If not found → execute, store key + response hash, return result.

The `idempotency_keys` table has a daily cron cleanup (`pg_cron`) to prevent unbounded growth.

### Queue drain idempotency

The `OfflineSyncService` (`lib/data/sync/offline_sync_service.dart`) drens the `pending_actions` box FIFO with exponential backoff (1s, 2s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 512s). After 10 retries → dead letter. Each action carries its UUID, which serves as the idempotency key on the server side.

---

## 4. GTFS Streaming Plan

### Current state: point-in-time schedules

Schedules are stored as rows in `public.schedules` with `departure_time` and `arrival_time` columns. The Flutter client fetches schedules via REST (with SWR caching in Hive).

### Planned: GTFS-RT streaming

When real-time feed ingestion is needed (operator partnerships):

1. **Ingestion service** (Edge Function or external worker):
   - Polls operator GTFS-RT endpoints (Protocol Buffers) every 30s.
   - Decodes `TripUpdate`, `VehiclePosition`, and `Alert` entities.
   - Writes to `public.live_vehicle_positions` table (partitioned by hour).
   - Broadcasts changes via Supabase Realtime channels.

2. **Client consumption:**
   - `BusLocationRepository` already supports `RealtimeChannel` (`bus_location_remote_repository.dart`).
   - Subscribe to `live_vehicle_positions` with `postgres_changes` filter.
   - Merge with static GTFS schedule data for ETA computation.

3. **Scaling considerations:**
   - Partition `live_vehicle_positions` by day (range partition on `recorded_at`).
   - TTL cleanup: `pg_cron` deletes partitions older than 7 days.
   - Rate limit: operator-specific `INSERT` policy prevents flooding.

### GTFS static import

- `supabase/migrations/011_audit_log_extras.sql` and `016_data_exports.sql` already define export functions.
- Static GTFS data (routes, stops, schedules) is seeded via `tool/seed_data.sh` and migrations.
- Future: scheduled `gtfs_import` Edge Function that fetches operator GTFS static zips, validates, and upserts into the schema.

---

## 5. Multi-Region Plan

### Current: single region

Supabase project is hosted in a single region (eu-central-1, Frankfurt).

### Target: read replicas + multi-region Edge Functions

| Phase | What | When trigger |
|-------|------|--------------|
| **Phase 1** | Read replicas in `eu-west-1` (Ireland) | >500 concurrent users or >100ms p95 latency from Spain |
| **Phase 2** | Edge Functions deployed to `eu-west-1` + `eu-central-1` | >1000 concurrent users |
| **Phase 3** | Realtime server in `eu-south-1` (Milan) | LatAm expansion or >5000 concurrent users |

### Latency budget

| Path | Current (ms) | Target (ms) |
|------|:---:|:---:|
| Flutter → PostgREST → PostgreSQL | 80-120 | ≤100 |
| Flutter → Realtime WebSocket | 60-100 | ≤100 |
| Edge Function invocation (cold) | 200-400 | ≤300 |
| Edge Function invocation (warm) | 30-60 | ≤50 |

### Infrastructure as code

All Supabase configuration is in `supabase/migrations/` (SQL) and `supabase/functions/` (TypeScript). Read replicas and multi-region deployment are Supabase dashboard operations (not yet automated).

---

## 6. Monitoring & Alerting

### Current

- **Sentry:** error tracking + performance spans (`SENTRY_SPANS.md`).
- **PostHog:** 17 analytics events for product metrics.
- **Supabase dashboard:** database CPU, memory, connections, Realtime channels.

### Planned

- **SLO dashboards:** Grafana (Sentry integration) for `SLO_CATALOG.md` metrics.
- **PagerDuty:** on-call for SLO breach on `auth.signIn` success rate <99.5% or `map.initial_render` p95 >2000ms.
- **Supabase log drains:** stream PostgreSQL logs to external observability platform (Datadog/Logtail).

---

## References

- `supabase/migrations/001_init.sql` — schema foundation
- `supabase/migrations/002_rls.sql` — RLS policies (707 lines, default-deny)
- `supabase/migrations/003_rls_fixes.sql` — Supabase linter patches
- `supabase/migrations/004_storage.sql` — Storage buckets + policies
- `supabase/migrations/005_functions.sql` — PostgreSQL functions (SECURITY INVOKER)
- `lib/data/sync/offline_sync_service.dart` — Queue drain with exponential backoff
- `lib/data/bus_location/bus_location_remote_repository.dart` — RealtimeChannel subscription
- `docs/SLO_CATALOG.md` — SLO definitions
- `docs/SENTRY_SPANS.md` — Performance instrumentation
