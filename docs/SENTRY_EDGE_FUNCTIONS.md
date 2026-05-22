# Sentry Deno SDK — Edge Functions

> **Version:** 1.0 · **Owner:** Platform

## Overview

Instrument Supabase Edge Functions (`send_notification`, `import_gtfs`) with
Sentry Deno SDK for error tracking and performance monitoring.

## Setup

### 1. Add Sentry to Edge Function

```typescript
// supabase/functions/send_notification/index.ts
import * as Sentry from "npm:@sentry/deno";

// IMPORTANT: Supabase Edge Functions use Deno, not Node.js.
// Use npm: specifier to pull the official Sentry Deno SDK from npm.

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN")!,
  environment: "production",
  tracesSampleRate: 0.2,
  // Deno-compatible defaults: no file I/O, no Node.js APIs
  autoSessionTracking: false,
  defaultIntegrations: [],
});

Deno.serve(async (req) => {
  return Sentry.withIsolationScope(() => {
    const transaction = Sentry.startTransaction({
      name: "send_notification",
      op: "edge_function",
    });

    return Sentry.withScope(async (scope) => {
      scope.setTransactionName("send_notification");
      try {
        // ... function logic ...
        transaction.setStatus("ok");
        return new Response(JSON.stringify({ success: true }));
      } catch (error) {
        Sentry.captureException(error);
        transaction.setStatus("internal_error");
        return new Response(
          JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
          { status: 500 },
        );
      } finally {
        transaction.finish();
      }
    });
  });
});
```


### 2. Set environment variable in Supabase

```bash
supabase secrets set SENTRY_DSN="https://xxx@sentry.io/xxx"
```

### 3. Cold start instrumentation

```typescript
// supabase/functions/import_gtfs/index.ts
import * as Sentry from "npm:@sentry/deno";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN")!,
  environment: "production",
  tracesSampleRate: 0.2,
  autoSessionTracking: false,
  defaultIntegrations: [],
});

Deno.serve(async (_req) => {
  return Sentry.withIsolationScope(() => {
    const coldStartSpan = Sentry.startTransaction({
      name: "import_gtfs.cold_start",
      op: "edge_function",
    });

    try {
      // ... import logic ...
      coldStartSpan.setStatus("ok");
      return new Response(JSON.stringify({ imported: true }));
    } catch (error) {
      Sentry.captureException(error);
      coldStartSpan.setStatus("internal_error");
      return new Response(
        JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
        { status: 500 },
      );
    } finally {
      coldStartSpan.finish();
    }
  });
});
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

---

## Required Secrets

The `SENTRY_DSN` secret must be set in Supabase for edge functions to report to Sentry. Without it, `Sentry.init()` will fail silently.

```bash
# Set the secret
supabase secrets set SENTRY_DSN="https://<key>@sentry.io/<project>"

# Verify it's set
supabase secrets list

# For local development, add to supabase/config.toml or .env.local
```

Edge functions will throw at `Deno.env.get("SENTRY_DSN")!` if the secret is missing. Consider a fallback pattern for non-critical tracing:

```typescript
const dsn = Deno.env.get("SENTRY_DSN");
const sentryEnabled = dsn != null && dsn.length > 0;
if (sentryEnabled) {
  Sentry.init({ dsn, /* ... */ });
}
```

---

## Troubleshooting

### Error: `Module not found: npm:@sentry/deno`

The `npm:` specifier requires Deno 1.28+. Supabase Edge Functions run Deno 1.46+, so this should always resolve. If it fails:
1. Verify the import uses `npm:@sentry/deno` (not a deno.land URL — those are third-party and unmaintained).
2. Run `deno cache --reload supabase/functions/<name>/index.ts` locally to confirm the module resolves.

### Error: `Sentry is not initialized`

Sentry is initialized lazily inside each edge function's top-level scope. If you see this error:
1. Ensure `Sentry.init()` is called before `Sentry.startTransaction()`.
2. Check that `SENTRY_DSN` is set and non-empty: `supabase secrets list | grep SENTRY_DSN`.
3. For local testing, set the env var manually: `SENTRY_DSN="..." supabase functions serve`.

### Transactions not appearing in Sentry dashboard

- `tracesSampleRate: 0.2` means only 20% of invocations are sampled. Increase to `1.0` during debugging.
- Transactions appear under the **Performance** tab, not **Issues**.
- Check the edge function logs: `supabase functions logs <name>`. Look for network errors to `sentry.io`.
- Sentry SDK batches events. Edge functions may terminate before the batch is flushed. Add `await Sentry.flush(2000)` before the function returns if events are missing.

### `Deno.env.get("SENTRY_DSN")!` throws on local serve

The `!` non-null assertion crashes if the env var is unset. For local dev, either:
- Set `SENTRY_DSN` in your shell before running `supabase functions serve`, or
- Use the fallback pattern shown in the Required Secrets section above.
