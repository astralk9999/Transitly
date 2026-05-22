# PostHog Product Events — Transitly

> **Version:** 1.0 · **Consent:** Opt-in after GDPR consent · **Owner:** Product

## Event Catalog

### User Lifecycle

| Event | Trigger | Properties |
|-------|---------|------------|
| `signup` | User creates account | `method`: email/google/magic_link |
| `signin` | User signs in | `method`: email/google/magic_link |
| `signout` | User signs out | — |
| `account_deleted` | Right-to-be-forgotten executed | `retention_days` |

### Core Product

| Event | Trigger | Properties |
|-------|---------|------------|
| `route_viewed` | User opens route detail | `route_id`, `operator_id` |
| `stop_viewed` | User opens stop detail | `stop_id`, `route_ids` |
| `map_interaction` | User pans/zooms map | `zoom_level`, `center_lat`, `center_lng` (rounded to 2 decimals) |
| `search_performed` | User searches routes/stops | `query`, `result_count` |

### NFC

| Event | Trigger | Properties |
|-------|---------|------------|
| `nfc_read_success` | Card balance read successfully | `card_type` (no UID), `balance_eur` |
| `nfc_read_error` | Card read failed | `error_type` |

### Community

| Event | Trigger | Properties |
|-------|---------|------------|
| `incident_reported` | User reports incident | `incident_type`, `route_id`, `stop_id` |
| `suggestion_created` | User submits route suggestion | `origin`, `destination` |
| `feedback_submitted` | User submits route feedback | `feedback_type`, `route_id` |
| `vote_cast` | User votes on suggestion/feature | `target_type`, `target_id` |

### Driver

| Event | Trigger | Properties |
|-------|---------|------------|
| `driver_route_started` | Driver starts route | `route_id`, `operator_id` |
| `driver_route_completed` | Driver completes route | `route_id`, `duration_seconds`, `stop_count` |
| `invitation_claimed` | Driver claims invitation code | `operator_id` |

---

## Implementation

```dart
// In posthog_service.dart
import 'package:posthog_flutter/posthog_flutter.dart';

class PostHogAnalyticsService {
  static void track(String event, {Map<String, dynamic>? properties}) {
    if (!_consentGranted) return;
    Posthog().capture(
      eventName: event,
      properties: properties,
    );
  }
}
```

## Privacy

- **GDPR consent-gated**: events are only captured after explicit opt-in
- **No PII**: no emails, no full UUIDs, no precise locations (< 2 decimal lat/lng)
- **Config**: `optOut: true` at boot, enabled only after consent
- **Retention**: 3 years per DATA_RETENTION.md
