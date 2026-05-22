# Migration Rollback Scripts — Transitly

> **Version:** 1.0 · **Last audited:** 2026-05-22

## Overview

Each migration has a corresponding rollback script to restore the previous
state in case of failed deployment. These are manual (not automated in CI)
because Supabase migrations are append-only.

---

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

### 002_rls_policies.sql — RLS policies
```sql
-- ROLLBACK: Drop RLS policies (tables remain)
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.operators DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops DISABLE ROW LEVEL SECURITY;
```

### 007_create_invitation_code.sql — Driver invites
```sql
-- ROLLBACK
BEGIN;
DROP FUNCTION IF EXISTS public.create_invitation_code(text, int);
DROP FUNCTION IF EXISTS public.revoke_driver(uuid);
DROP TABLE IF EXISTS public.driver_invitation_codes CASCADE;
DROP TABLE IF EXISTS public.driver_operators CASCADE;
COMMIT;
```

### 008_gtfs_seed.sql — GTFS seed data
```sql
-- ROLLBACK: Delete seed operators
DELETE FROM public.operators WHERE slug IN ('comujesa', 'tussam', 'emt-madrid', 'tmb', 'bilbobus');
DELETE FROM public.stops WHERE operator_id IN (SELECT id FROM public.operators WHERE slug IN ('comujesa', 'tussam', 'emt-madrid', 'tmb', 'bilbobus'));
DELETE FROM public.routes WHERE operator_id IN (SELECT id FROM public.operators WHERE slug IN ('comujesa', 'tussam', 'emt-madrid', 'tmb', 'bilbobus'));
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

```bash
# Reset local Supabase to clean state
supabase db reset --local

# Re-apply migrations
supabase db push
```
