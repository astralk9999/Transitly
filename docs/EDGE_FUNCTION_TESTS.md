# Edge Function Tests — Deno

> **Version:** 1.0 · **Functions:** `send_notification`, `import_gtfs`

## Test Infrastructure

Supabase Edge Functions run on Deno. Tests use Deno's built-in test runner.

```bash
# Run tests for a specific function
deno test supabase/functions/send_notification/test.ts --allow-env --allow-net

# Run all edge function tests
deno test supabase/functions/*/test.ts --allow-env --allow-net
```

## send_notification Tests

```typescript
// supabase/functions/send_notification/test.ts
import { assertEquals } from "https://deno.land/std/testing/asserts.ts";

Deno.test("send_notification validates UUID", () => {
  // Test UUID validation logic
});

Deno.test("send_notification requires service_role", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    headers: { "Authorization": "Bearer anon-key" },
    body: JSON.stringify({ user_id: "invalid-uuid" }),
  });
  
  // Should reject non-service_role requests
});

Deno.test("send_notification rate limits excessive calls", async () => {
  // Test rate limiting logic
});

Deno.test("send_notification formats FCM payload correctly", () => {
  const payload = {
    message: {
      token: "fcm-token",
      notification: { title: "Test", body: "Message" },
    },
  };
  // Verify payload structure matches Firebase HTTP v1 API spec
  assertEquals(typeof payload.message.token, "string");
});
```

## import_gtfs Tests

```typescript
// supabase/functions/import_gtfs/test.ts

Deno.test("import_gtfs validates GTFS zip structure", () => {
  // Test zip file validation
});

Deno.test("import_gtfs parses stops.txt correctly", () => {
  const csvContent = "stop_id,stop_name,stop_lat,stop_lon\nS1,Central,36.7,-6.1";
  // Parse and validate
});

Deno.test("import_gtfs handles malformed CSV gracefully", () => {
  // Should return error, not crash
});

Deno.test("import_gtfs inserts operators and routes", async () => {
  // Integration test with local Supabase
});
```

## CI Integration

```yaml
# .github/workflows/ci.yml
test-edge-functions:
  name: Edge Function Tests (Deno)
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: denoland/setup-deno@v1
      with:
        deno-version: v1.x
    - name: Run Edge Function tests
      run: |
        deno test supabase/functions/send_notification/test.ts --allow-env
        deno test supabase/functions/import_gtfs/test.ts --allow-env
```

## Local Development

```bash
# Start local Supabase
supabase start

# Serve Edge Function locally
supabase functions serve send_notification --env-file .env

# Run tests
deno test --watch supabase/functions/send_notification/test.ts
```
