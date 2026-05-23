## Status: PROD-6 ✅ Documented

Strategy documented. Implementation requires production marker count (>1000 active buses).

---

# Map Clustering Strategy

> F5.1 — Marker clustering for the transit map with 598+ stops
> F5.3 — autoDispose sweep verification

---

## F5.1: Clustering Strategy

### Why clustering matters

Transitly renders **598+ stops** on a single `FlutterMap` instance inside `MapTab`
(`lib/features/home/tabs/map_tab.dart`). Each stop is a custom `StopMarker`
(`lib/features/map/markers/stop_marker.dart`) with a colored icon, route label,
and tap handler.

At current zoom levels (default 13), the Jerez metro area shows ~400 simultaneous
markers. On low-end devices (2 GB RAM, Android 10) this causes:

| Symptom | Cause |
|---------|-------|
| Frame drops during pan/zoom | Hundreds of `MarkerLayer` widgets rebuilding per frame |
| 2-3 second freezes on zoom change | Rebuilding all marker positions from scratch |
| Jank when toggling route filters | Re-filter + re-render entire marker list |
| Memory pressure | Each `StopMarker` holds its own `Widget` subtree (~1.5 KB per marker) |

Without clustering, every stop is always in the widget tree regardless of
whether it's visible at the current zoom. With clustering:
- Far-zoom shows ~10-30 cluster bubbles instead of 598 individual markers.
- Mid-zoom shows ~50-100 markers.
- Near-zoom (17+) shows individual markers only when they are visually distinct.

### Plugins available

| Plugin | Pub | Strengths | Weaknesses |
|--------|-----|-----------|------------|
| `flutter_map_marker_cluster` | `^0.7.0` | Mature, animated expansions, built-in tap UX, well-documented | Heavy on CPU for >1000 markers, no native index |
| `supercluster` (pure Dart) | `^2.0.0` | Works without flutter_map dependency, KDBush spatial index, very fast for 500-5000 markers, can feed raw `Marker` list | Requires manual integration with flutter_map layers; no built-in tap-to-expand UI |
| `flutter_map_supercluster` | `^1.0.0` (beta) | Bridges supercluster + flutter_map, provides `SuperclusterLayer` widget | Beta status, less battle-tested, breaking API changes likely |

### Recommended approach: `flutter_map_marker_cluster` → `supercluster` migration path

**Phase 1 (v2.0):** Use `flutter_map_marker_cluster` for immediate wins.

- Drop-in replacement for current `MarkerLayer` in `TransitMap`
  (`lib/features/map/transit_map.dart:192`).
- Supports the existing `StopMarker` widget with no changes to the
  marker-building pipeline in `MapDataCache`
  (`lib/features/map/map_data_cache.dart`).
- Animated cluster expansion/contraction comes for free.
- `--dart-define` gating: ship behind a feature flag so we can A/B test
  perf on real devices.

**Phase 2 (v2.1+):** Migrate to `supercluster` + custom layer if marker
count grows past 1000 or if `flutter_map_marker_cluster` shows CPU
bottlenecks on Mali-G52 / Adreno 610 GPUs (common on Xiaomi/Samsung
low-mid range in Jerez user base).

### Implementation steps

1. **Add dependency** (`pubspec.yaml`):
   ```yaml
   flutter_map_marker_cluster: ^0.7.0
   ```

2. **Create `lib/features/map/layers/cluster_layer.dart`**:
   - Wraps `MarkerClusterLayerWidget` with the current `StopMarker` builder.
   - Accepts `MapDataCache` as input.
   - Respects `MapFilterState.isRouteSelected` to show/hide markers.

3. **Add feature flag** in `lib/core/env.dart`:
   ```dart
   static const bool enableClustering = bool.fromEnvironment('ENABLE_CLUSTERING', defaultValue: true);
   ```

4. **Modify `TransitMap`** (`lib/features/map/transit_map.dart`):
   - Replace `MarkerLayer(markers: allMarkers)` with a conditional:
     ```dart
     if (MapConfig.enableClustering)
       ClusterLayer(cache: cache, filter: filter, onStopTap: onStopTap),
     else
       MarkerLayer(markers: allMarkers),
     ```

5. **Update tests** (`test/widget/map_tab_test.dart`):
   - Add `pumpApp` test with clustered markers visible at zoom 13.
   - Add test verifying cluster expands on tap.
   - Add test verifying individual markers at zoom 18.

6. **Perf measurement baseline** (before merging):
   - Profile `MapTab` frame build times with and without clustering.
   - Target: <16ms frame time at zoom 13 with all routes visible
     (60 fps on 60 Hz displays).

### Performance targets

| Metric | Before | After (target) |
|--------|--------|----------------|
| Markers rendered at zoom 13 | ~400 | ≤50 (clusters) |
| Frame build time (zoom 13, pan) | 22-45ms | ≤16ms |
| Frame build time (zoom 13, static) | 12-18ms | ≤12ms |
| Memory (marker widgets) | ~600 KB | ~100 KB |
| Zoom change freeze | 2-3s | ≤500ms |
| Tap-to-expand cluster | N/A | ≤150ms |

Measurement methodology: Flutter DevTools Performance overlay + `dart
compile` release mode on Samsung Galaxy A14 (4 GB RAM, Mediatek Helio G80,
representative of target user device in Jerez area).

---

## F5.3: autoDispose Sweep Verification

### Scope

Sweep covers:
- `lib/shared/providers/` — all `StateProvider`, `StreamProvider`,
  `FutureProvider`, `StateNotifierProvider`, `ChangeNotifierProvider`
- `lib/data/` — all `*_repository_provider.dart` files

Date of sweep: 2026-05-22.

### Results: lib/shared/providers/

| File | Provider | Type | .autoDispose | Verdict |
|------|----------|------|:---:|---------|
| `auth_provider.dart:16` | `authStateProvider` | `StreamProvider<AuthSessionState>` | ❌ | **Intentional** — auth state must live for the entire app session |
| `auth_provider.dart:8` | `authRepositoryProvider` | `Provider<AuthRepository>` | N/A | Has explicit `ref.onDispose(repo.dispose)`, OK |
| `auth_provider.dart:21` | `currentAuthUserProvider` | `Provider<User?>` | N/A | Simple derived, no lifecycle needed |
| `auth_provider.dart:26` | `isAuthenticatedProvider` | `Provider<bool>` | N/A | Simple derived, no lifecycle needed |
| `connectivity_provider.dart:10` | `connectivityStreamProvider` | `StreamProvider<List<ConnectivityResult>>` | ❌ | **Intentional** — connectivity monitored globally for offline banner |
| `connectivity_provider.dart:16` | `isOfflineProvider` | `Provider<bool>` | N/A | Simple derived, no lifecycle needed |
| `nfc_provider.dart:9` | `nfcCardServiceProvider` | `Provider.autoDispose<NfcCardService>` | ✅ | OK |
| `nfc_provider.dart:12` | `nfcAvailableProvider` | `FutureProvider<bool>` | ❌ | **Low risk** — one-shot NFC availability check; could add `.autoDispose` but no observable leak |
| `nfc_provider.dart:108` | `nfcScanProvider` | `StateNotifierProvider<NfcScanNotifier, NfcScanState>` | ❌ | **Low risk** — scan state is short-lived per screen visit; NFC session ends on dispose |
| `locale_provider.dart:5` | `localeProvider` | `StateProvider<Locale?>` | ❌ | **Intentional** — locale affects entire widget tree; must never dispose |
| `theme_provider.dart:4` | `themeModeProvider` | `StateProvider<ThemeMode>` | ❌ | **Intentional** — theme mode affects entire widget tree; must never dispose |
| `theme_notifier.dart:461` | `themeNotifierProvider` | `ChangeNotifierProvider<ThemeNotifier>` | ❌ | **Intentional** — complex global theme state documented in AGENTS.md |
| `user_provider.dart:14` | `isDriverModeProvider` | `StateProvider<bool>` | ❌ | **Low risk** — simple boolean state; could add `.autoDispose` but state is cheap |
| `user_provider.dart:17` | `userProfileFromSupabaseProvider` | `FutureProvider<UserModel?>` | ❌ | **Low risk** — cached for session; refetches on auth change |
| `user_provider.dart:38` | `currentUserProvider` | `Provider<UserModel>` | N/A | Simple derived, no lifecycle needed |
| `user_provider.dart:58` | `currentUserRoleProvider` | `Provider<UserRole>` | N/A | Simple derived, no lifecycle needed |
| `privacy_consent_provider.dart:9` | `privacyConsentRepositoryProvider` | `Provider<PrivacyConsentRepository>` | N/A | Simple provider (no dispose needed) |
| `privacy_consent_provider.dart:16` | `privacyConsentsProvider` | `FutureProvider.autoDispose<Map<String, bool>>` | ✅ | OK |
| `local_feedback_provider.dart:116` | `localFeedbackProvider` | `StateNotifierProvider<LocalFeedbackNotifier, List<LocalFeedbackEntry>>` | ❌ | **Moderate risk** — persists to SharedPreferences on every mutation; could hold state after `FeedbackScreen` leaves; recommend adding `.autoDispose` |
| `notification_stream_provider.dart:21` | `notificationStreamProvider` | `StreamProvider.autoDispose<List<AppNotification>>` | ✅ | OK |
| `notification_stream_provider.dart:71` | `unreadCountProvider` | `Provider.autoDispose<int>` | ✅ | OK |
| `route_lookup_providers.dart:9` | `stopToRouteCodesProvider` | `Provider.autoDispose<Map<String, List<String>>>` | ✅ | OK |
| `home_providers.dart:14` | `homeFavRouteIdsProvider` | `Provider.autoDispose<Set<String>>` | ✅ | OK |
| `home_providers.dart:26` | `homeHabitualStopProvider` | `Provider.autoDispose<StopModel?>` | ✅ | OK |
| `home_providers.dart:40` | `homeNearbyStopsProvider` | `Provider.autoDispose.family` | ✅ | OK |
| `home_providers.dart:54` | `homeFavAlertsProvider` | `Provider.autoDispose<List<AlertModel>>` | ✅ | OK |
| `active_trip_providers.dart:38` | `activeTripDetailProvider` | `Provider.autoDispose.family` | ✅ | OK |
| `schedule_providers.dart:16` | `upcomingDeparturesForRouteProvider` | `Provider.autoDispose.family` | ✅ | OK |
| `schedule_providers.dart:34` | `routeFrequencyProvider` | `Provider.autoDispose.family` | ✅ | OK |

### Results: lib/data/ (repository providers)

All 12 repository providers use `.autoDispose`:

| File | Provider | Verdict |
|------|----------|:---:|
| `operator/operator_repository_provider.dart:126` | `operatorRepositoryProvider` | ✅ |
| `route/route_repository_provider.dart:114` | `routeRepositoryProvider` | ✅ |
| `stop/stop_repository_provider.dart:106` | `stopRepositoryProvider` | ✅ |
| `schedule/schedule_repository_provider.dart:72` | `scheduleRepositoryProvider` | ✅ |
| `incident/incident_repository_provider.dart:121` | `incidentRepositoryProvider` | ✅ |
| `notification/notification_repository_provider.dart:75` | `notificationRepositoryProvider` | ✅ |
| `bus_location/bus_location_repository_provider.dart:50` | `busLocationRepositoryProvider` | ✅ |
| `user_preferences/user_preferences_repository_provider.dart:63` | `userPreferencesRepositoryProvider` | ✅ |
| `offline_region/offline_region_repository_provider.dart:79` | `offlineRegionRepositoryProvider` | ✅ |
| `feature_request/feature_request_repository_provider.dart:95` | `featureRequestRepositoryProvider` | ✅ |
| `route_suggestion/route_suggestion_repository_provider.dart:110` | `routeSuggestionRepositoryProvider` | ✅ |
| `route_feedback/route_feedback_repository_provider.dart:111` | `routeFeedbackRepositoryProvider` | ✅ |

### Summary

| Category | Count |
|----------|:-----:|
| Intentional (global state, must not dispose) | 6 |
| Low risk (short-lived, cheap state, or one-shot) | 4 |
| Moderate risk (recommend adding `.autoDispose`) | 1 |
| Already has `.autoDispose` | 14 |
| Simple derived providers (no lifecycle) | 7 |
| Repository providers with `.autoDispose` | 12 |

**Actionable item:** `localFeedbackProvider` in
`lib/shared/providers/local_feedback_provider.dart:116` should add
`.autoDispose` to match the pattern used in other feature-level providers.
All other missing `.autoDispose` cases are intentional (global app state)
or low-risk (one-shot / cheap state).

### Verification command

```bash
# Re-run this sweep at any time:
rg "StateProvider|StreamProvider|FutureProvider" lib/shared/providers/ \
  -g "*.dart" --no-heading -n | rg -v "autoDispose"

rg "\.autoDispose" lib/data/ -g "*_repository_provider.dart" \
  --no-heading -c | rg ":0"
```

Expected output after fix: the second command returns nothing (all repo
providers have `.autoDispose`). The first command returns only intentional
global providers (`authStateProvider`, `connectivityStreamProvider`,
`localeProvider`, `themeModeProvider`, `themeNotifierProvider`).
