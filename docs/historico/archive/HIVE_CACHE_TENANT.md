## Status: PROD-9 ✅ Documented

Current Hive cache architecture documented. Multi-tenant encryption strategy defined.

---

# Hive Cache — Multi-Tenant Architecture

> PROD-9: Cache encryption and tenant isolation plan for the 16-box Hive architecture.

## Current Architecture (v2.0)

### Box inventory (16 boxes)

| # | Box name | Type | Encrypted | Purpose |
|:--:|----------|------|:---------:|---------|
| 1 | `routes` | `RouteModel` | No | Route definitions (cached from Supabase) |
| 2 | `stops` | `StopModel` | No | Stop definitions (cached from Supabase) |
| 3 | `schedules` | `ScheduleModel` | No | Schedule entries (cached from Supabase) |
| 4 | `operators` | `OperatorModel` | No | Operator profiles (cached from Supabase) |
| 5 | `user_preferences` | `UserPreferences` | No | Per-user preferences singleton |
| 6 | `offline_regions` | `OfflineRegion` | No | Bounding-box region payloads for offline mode |
| 7 | `alerts` | `AlertModel` | No | Transit alerts (incidents, detours) |
| 8 | `incidents` | `IncidentModel` | No | User-reported incidents |
| 9 | `route_feedback` | `RouteFeedbackModel` | No | Route feedback submitted by users |
| 10 | `route_suggestions` | `RouteSuggestionModel` | No | Route improvement suggestions |
| 11 | `feature_requests` | `FeatureRequest` | No | Feature requests from users |
| 12 | `notifications` | `AppNotification` | No | Push / in-app notifications |
| 13 | `editor_drafts` | `Map<dyn,dyn>` | No | Route editor unsaved drafts |
| 14 | `pending_actions` | `Map<dyn,dyn>` | **Yes** (`HiveAesCipher`) | Offline mutation queue |
| 15 | `dead_letter_actions` | `Map<dyn,dyn>` | No | Failed mutations after 10 retries |
| 16 | `auth_session_meta` | `Map<dyn,dyn>` | **Yes** (`HiveAesCipher`) | Last session uid, token expiration metadata |

### Encryption key management

- Key derivation: `Hive.generateSecureKey()` via `HiveAesCipher`.
- Key storage: `FlutterSecureStorage` under key `hive_key` (base64-encoded).
- Lifetime: first app launch generates key, subsequent launches read from `FlutterSecureStorage`.
- Scope: shared across `pending_actions` and `auth_session_meta` only. 14/16 boxes are cleartext.

### Key format convention

Keys in all boxes follow the pattern `<scope>:<id>`:

```
op:comujesa:route:L1          — Route L1 of operator COMUJESA
op:comujesa:stop:JER-001      — Stop with officialCode JER-001
user:<uid>:fav:<stopId>       — User favorite stop
user:<uid>:pref               — User preferences singleton
```

This prefix convention enables filtering/deleting by scope without iterating the entire box.

### Repository pattern

Each entity in `lib/data/<entity>/` has a `*_local_repository.dart` that reads/writes the associated Hive box. Cache policies:

- **SWR (stale-while-revalidate):** repository providers return cached data immediately, then refresh from Supabase in the background.
- **Eviction:** manual only (no LRU/TTL). Boxes grow with session duration and are cleared on logout via `deleteAllBoxes()`.
- **Corruption handling:** if `Hive.openBox()` throws, the box is deleted from disk and recreated (`hive_init.dart:107-111`).

---

## Planned: Multi-Tenant Encryption (PROD-9 target)

### Partition by operator_id

When a single device serves multiple operators (driver mode or operator admin), data from different operators must not mix:

```
Current:  routes['op:comujesa:route:L1'] = RouteModel(...)
Planned: routes['<operator_id>:op:comujesa:route:L1'] = RouteModel(...)
```

Keys are prefixed with the owning `operator_id` (UUID) so that switching operator contexts only exposes that operator's cached data.

### LRU eviction

- Adopt the pattern from FMTC: LRU eviction based on last-read timestamp.
- Each box tracks `lastTouched` per key in a companion `_meta` box.
- When box size exceeds `maxEntries` (default 500), evict least-recently-touched entries.
- Eviction only applies to data boxes (1–13). Queues (14–16) are size-bounded by operational limits.

### AES encryption for all sensitive boxes

Extend `HiveAesCipher` from 2 boxes to all 16 boxes that may contain PII:

| Tier | Boxes | Rationale |
|------|-------|-----------|
| **Tier 1 (PII)** | `auth_session_meta`, `user_preferences`, `notifications` | Contains uid, token metadata, user settings, push token |
| **Tier 2 (operational)** | `pending_actions`, `dead_letter_actions`, `route_feedback`, `route_suggestions`, `feature_requests`, `incidents`, `editor_drafts` | Contains user-generated content with optional PII (free-text fields) |
| **Tier 3 (public data)** | `routes`, `stops`, `schedules`, `operators`, `alerts`, `offline_regions` | Public transit data; encryption is defense-in-depth, not PII-driven |

Implementation:
1. Use the same `hive_key` from `FlutterSecureStorage` for all boxes (single key, AES-256).
2. Boxes in Tier 1 open with `encryptionCipher: cipher` (mandatory).
3. Boxes in Tier 2 open with `encryptionCipher: cipher` (mandatory).
4. Boxes in Tier 3 open with `encryptionCipher: cipher` (optional via `--dart-define` feature flag: `ENABLE_FULL_HIVE_ENCRYPTION`).

### Migration path

1. Add `operator_id` column to `UserPreferences` Hive adapter (backward-compatible: null = single-tenant).
2. Ship new `_meta` box with LRU metadata.
3. Add encryption flag; existing cleartext boxes are deleted on first encrypted open.
4. Grace period: dual-read (try encrypted, fallback cleartext) for one release cycle.

---

## References

- `lib/data/cache/hive_init.dart` — bootstrap + encryption key management
- `lib/data/cache/hive_box_provider.dart` — Riverpod providers for each box
- `lib/data/cache/hive_adapters.dart` — Hive TypeAdapter registrations
- `lib/data/cache/secure_storage.dart` — `FlutterSecureStorage` wrapper
- `lib/data/sync/pending_action.dart` — offline mutation model (stored in `pending_actions`)
