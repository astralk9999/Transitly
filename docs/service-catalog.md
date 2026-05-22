# Service Catalog — Transitly

> **Version:** 1.0 · **Owner:** Platform team

## External Services

| Service | Purpose | Dependency level | Fallback |
|---------|---------|:---:|----------|
| **Supabase PostgREST** | REST API for all CRUD operations | Critical | Hive cache (read), offline queue (write) |
| **Supabase GoTrue** | User authentication (email, magic link, JWT) | Critical | Guest mode (mock data) |
| **Supabase Realtime** | WebSocket subscriptions (bus positions, incidents) | High | MockRealtimeService (simulated data) |
| **Supabase Edge Functions** | Serverless logic (push notifications, GTFS import) | Medium | No push; manual GTFS upload |
| **Supabase Storage** | File storage (avatars, GTFS files) | Medium | Local-only (no upload) |
| **Firebase FCM** | Push notification delivery | Medium | In-app inbox (`AppNotification`) |
| **Sentry** | Crash reporting + performance tracing | Medium | Silent failure (AppLogger local) |
| **PostHog** | Product analytics (opt-in, consent-gated) | Low | No analytics |
| **MapTiler** | Map tile server | High | Cached tiles (flutter_map_tile_caching) |

## Internal Services (Dart packages)

| Service | File | Responsibility |
|---------|------|---------------|
| **AppLogger** | `lib/core/utils/app_logger.dart` | Structured logging with 4 levels |
| **ErrorBoundary** | `lib/core/utils/error_boundary.dart` | Global error handlers → Sentry |
| **TransitProviderObserver** | `lib/core/utils/transit_provider_observer.dart` | Riverpod error capture → Sentry |
| **SentrySetup** | `lib/core/utils/sentry_setup.dart` | Sentry init + PII scrubbing |
| **HiveInit** | `lib/data/cache/hive_init.dart` | Box initialization with corruption recovery |
| **MockDataService** | `lib/data/mock/mock_data_service.dart` | JSON asset loading + typed error handling |
| **MockRealtimeService** | `lib/data/mock/mock_realtime_service.dart` | Simulated bus positions + lifecycle pause/resume |
| **NfcCardService** | `lib/data/nfc/nfc_card_service.dart` | Mifare Classic NFC reading |
| **OfflineSyncService** | `lib/data/sync/offline_sync_service.dart` | FIFO queue drain with exponential backoff |
| **RealtimeChannelManager** | `lib/data/sync/realtime_channel_manager.dart` | Multiplexed Supabase Realtime subscriptions |
| **PendingActionsQueue** | `lib/data/sync/pending_actions_queue.dart` | Offline write queue + dead letter |
| **LocationService** | `lib/data/location/location_service.dart` | GPS permissions + streaming |
| **OperatorRepo** | `lib/data/operator/` | 5-file pattern: abstract, remote, local, mock, provider |

## Dependencies Between Services

```
AppLogger ← ErrorBoundary, TransitProviderObserver, repositories
SentrySetup ← ErrorBoundary, TransitProviderObserver
HiveInit → Hive boxes → Local repositories
MockDataService ← Mock repositories (guest mode)
SupabaseClient ← Remote repositories
RealtimeChannelManager ← BusLocationRepository, NotificationRepository
OfflineSyncService ← PendingActionsQueue ← Repositories with writes
```

## Service Health Checks

| Check | Method | Healthy if |
|-------|--------|-----------|
| Supabase connectivity | `Supabase.instance.client.from('operators').select().limit(1)` | Returns in < 2s |
| Hive integrity | `Hive.boxExists(boxName)` for all 9 boxes | All return true |
| NFC hardware | `NfcManager.instance.isAvailable()` | Returns true |
| Firebase token | `FirebaseMessaging.instance.getToken()` | Returns non-null string |
| Sentry DSN | `Env.sentryDsn` env var | Non-null, non-empty |
| Location permission | `Geolocator.checkPermission()` | `whileInUse` or `always` |
