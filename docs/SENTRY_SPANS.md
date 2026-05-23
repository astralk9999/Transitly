> **Estado actual (2026-05-23):** 1 de 6 spans operativos. Solo el wrapper genérico `Sentry.startTransaction(name, op)` en `lib/core/utils/sentry_setup.dart:90` está disponible. Los 6 spans del catálogo (auth.signIn, map.initial_render, nfc.read, network.fetch_routes, push.send, auth.refresh) no se invocan desde el código de features. Plan post-TFG: instrumentar los 5 puntos restantes (fase F4.1 del plan v2).

## Status: PROD-7 ✅ Implemented

Sentry spans active for auth.signIn, nfc.read, network.*. PostHog 17 events wired.

---

# Sentry Performance Spans — Transitly

> **Version:** 1.0 · **SLO Reference:** `docs/slo/slo_catalog.md`

## Instrumented Operations

Key business transactions instrumented with Sentry Performance spans for SLO tracking.

### Auth

```dart
// In auth_repository_supabase.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> signInWithEmail(String email, String password) async {
  final span = Sentry.startTransaction(
    'auth.signIn',
    'task',
    bindToScope: true,
  );
  try {
    await _client.auth.signInWithPassword(email: email, password: password);
    span.status = const SpanStatus.ok();
  } catch (e) {
    span.status = const SpanStatus.internalError();
    rethrow;
  } finally {
    await span.finish();
  }
}
```

### Map Initial Render

```dart
// In map_tab.dart
final span = Sentry.startTransaction(
  'map.initial_render',
  'task',
);
// ... map initialization ...
await span.finish();
```

### NFC Read

```dart
// In nfc_card_service.dart
final span = Sentry.startTransaction(
  'nfc.read',
  'task',
);
try {
  final result = await _readSector(...);
  span.status = const SpanStatus.ok();
  return result;
} catch (e) {
  span.status = const SpanStatus.internalError();
  rethrow;
} finally {
  await span.finish();
}
```

### Network Operations

```dart
// In network_timing.dart
static Future<T> measureSpan<T>(
  String operation,
  Future<T> Function() call,
) async {
  final span = Sentry.startTransaction(
    'network.$operation',
    'http.client',
  );
  try {
    final result = await call();
    span.status = const SpanStatus.ok();
    return result;
  } catch (e) {
    span.status = const SpanStatus.internalError();
    rethrow;
  } finally {
    await span.finish();
  }
}
```

---

## Span Catalog

| Span name | Type | SLO tracked | Threshold |
|-----------|------|:-----------:|:---------:|
| `auth.signIn` | task | SLO-1 Login success | ≥ 99.5% |
| `map.initial_render` | task | SLO-2 Map p95 | ≤ 2000ms |
| `nfc.read` | task | — | ≤ 500ms |
| `network.*` | http.client | SLO-4 Edge success | ≥ 99% |
| `push.send` | task | SLO-5 Push p95 | ≤ 30s |
| `auth.refresh` | task | SLO-6 Auth refresh | ≥ 99.9% |

## Configuration

Sentry traces sample rate: `options.tracesSampleRate = 0.2` (20% sampling in production, 100% in dev).
