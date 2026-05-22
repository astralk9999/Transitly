# Database Reset in CI — Transitly

> **Version:** 1.0 · **Reference:** PRO-QA-15

## Overview

Run `supabase db reset` in CI to verify migrations are idempotent and the
database can be rebuilt from scratch.

## CI Job

```yaml
# .github/workflows/ci.yml
db-reset:
  name: Supabase DB Reset
  runs-on: ubuntu-latest
  timeout-minutes: 10
  services:
    postgres:
      image: supabase/postgres:15.6.1.143
      env:
        POSTGRES_PASSWORD: postgres
      ports:
        - 5432:5432
  steps:
    - uses: actions/checkout@v4
    - uses: supabase/setup-cli@v1
      with:
        version: latest
    - name: Start Supabase
      run: supabase start
    - name: Reset and apply migrations
      run: supabase db reset
    - name: Verify tables exist
      run: |
        supabase db diff --local -f verify_schema
        echo "All migrations applied successfully"
```

## Local Verification

```bash
# Reset local Supabase to clean state
supabase db reset --local

# Apply all migrations
supabase db push

# Generate types (verifies schema is valid)
supabase gen types typescript --local > lib/types/supabase.ts

# Verify RLS policies
supabase db diff --local
```

## Idempotency Check

Each migration must be idempotent — running it twice should not error.

```sql
-- Pattern: use IF NOT EXISTS / IF EXISTS
CREATE TABLE IF NOT EXISTS public.audit_log (...);
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS details jsonb;
DROP POLICY IF EXISTS "Admins can read" ON public.audit_log;
CREATE POLICY "Admins can read" ON public.audit_log ...;
```

## Seed Data

```sql
-- supabase/seed.sql
-- Insert test data for CI verification
INSERT INTO public.operators (slug, name, region)
VALUES ('test-op', 'Test Operator', 'Test Region')
ON CONFLICT (slug) DO NOTHING;
```

Run with:
```bash
supabase db reset --local && supabase db seed
```
