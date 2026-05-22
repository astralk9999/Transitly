# Sentry Deno SDK — Edge Functions

> **Version:** 1.0 · **Owner:** Platform

## Overview

Instrument Supabase Edge Functions (`send_notification`, `import_gtfs`) with
Sentry Deno SDK for error tracking and performance monitoring.

## Setup

### 1. Add Sentry to Edge Function

```typescript
// supabase/functions/send_notification/index.ts
import * as Sentry from "https://deno.land/x/sentry@8.0.0/index.mjs";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN")!,
  environment: "production",
  tracesSampleRate: 0.2,
});

Deno.serve(async (req) => {
  const transaction = Sentry.startTransaction({
    name: "send_notification",
    op: "edge_function",
  });

  try {
    // ... function logic ...
    transaction.setStatus("ok");
    return new Response(JSON.stringify({ success: true }));
  } catch (error) {
    Sentry.captureException(error);
    transaction.setStatus("internal_error");
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  } finally {
    transaction.finish();
  }
});
```

### 2. Set environment variable in Supabase

```bash
supabase secrets set SENTRY_DSN="https://xxx@sentry.io/xxx"
```

### 3. Cold start instrumentation

```typescript
const coldStartSpan = Sentry.startTransaction({
  name: "import_gtfs.cold_start",
  op: "edge_function",
});

// ... import logic ...

coldStartSpan.finish();
```

---

## Instrumented Functions

| Function | Span name | Type | Monitors |
|----------|-----------|------|----------|
| `send_notification` | `send_notification` | edge_function | SLO-5 Push delivery |
| `import_gtfs` | `import_gtfs.cold_start` | edge_function | SLO-4 Edge success |

## Rate Limiting

- Sentry sampling: `tracesSampleRate: 0.2` (20% of invocations)
- Cost: Supabase free tier includes 500K invocations/month
- Sentry events: with 20% sampling, ~100K events/month at 500K invocations

## Alerting

See [ALERT_MATRIX.md](../ALERT_MATRIX.md):
- P1: Edge function success rate < 95% for 1 hour
- P2: Push delivery p95 > 120s for 1 hour
