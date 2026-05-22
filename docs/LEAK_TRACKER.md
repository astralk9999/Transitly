# Leak Tracker — Transitly

> **Version:** 2.0 · **Package:** `leak_tracker_flutter_testing` · **Status:** not yet integrated

## Overview

`leak_tracker_flutter_testing` detects memory leaks in widget and provider
tests by tracking object allocation and verifying disposal. Objects tracked
include: widgets, change notifiers, animation controllers, timer handles,
stream subscriptions, and focus nodes.

Leak tracking is **not yet added to this project's dev dependencies**.
This document describes the integration plan.

## Setup

### 1. Add dependency

```yaml
# pubspec.yaml (dev_dependencies)
dev_dependencies:
  leak_tracker_flutter_testing: ^3.3.0
```

Then run:
```bash
flutter pub get
```

### 2. Create test/helpers/leak_tracking.dart

```dart
// test/helpers/leak_tracking.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

final _enabled = ValueNotifier<bool>(false);

/// Enable leak tracking globally before any tests run.
/// Call once from a `setUpAll` in the test suite root or
/// from `flutter_test_config.dart`.
void enableLeakTracking() {
  if (_enabled.value) return;
  _enabled.value = true;
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      .withIgnored(ignoredLeaks: _defaultIgnored);
}

/// Ignored leak categories (false positives inherent to the stack).
const _defaultIgnored = <IgnoredLeaks>{
  // Riverpod ProviderContainer holds onto providers until dispose().
  // Tests that call container.dispose() should not see these.
  IgnoredLeaks(createdByTestHelpers: true),
};

/// Per-test leak check. Place at the end of tearDown().
void verifyNoLeaks() {
  LeakTesting.check(
    additionalCheck: (leaks) {
      if (leaks.notDisposed.isNotEmpty) {
        throw TestFailure(
          'Leaked objects not disposed: ${leaks.notDisposed.length}\n'
          '${leaks.notDisposed.map((l) => '  - ${l.type} (${l.identityHashCode})').join('\n')}',
        );
      }
    },
  );
}
```

### 3. Create test/flutter_test_config.dart

```dart
// test/flutter_test_config.dart
import 'helpers/leak_tracking.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  enableLeakTracking();
  await testMain();
}
```

This runs before every test file, enabling leak tracking globally without
modifying individual test files.

### 4. Integrate with existing test/helpers/pump_app.dart

Add a `leakTracking` parameter to the existing `pumpApp` helper:

```dart
// Inside pump_app(), add to tearDown or expose a helper:
Future<void> pumpAppWithLeakCheck(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  bool themeDark = true,
  bool disableAnimations = true,
  Locale locale = const Locale('es'),
}) async {
  await pumpApp(tester,
    child: child,
    overrides: overrides,
    themeDark: themeDark,
    disableAnimations: disableAnimations,
    locale: locale,
  );

  // Register leak check to run after test finishes.
  addTearDown(() => verifyNoLeaks());
}
```

## Critical Areas to Monitor

### 1. RealtimeChannelManager

Four remote repositories instantiate `RealtimeChannelManager`, which opens
WebSocket channels via Supabase Realtime:

| Repository | File | Lines |
|------------|------|-------|
| `RouteRemoteRepository` | `lib/data/route/remote/route_remote_repository.dart` | 15, 18 |
| `StopRemoteRepository` | `lib/data/stop/remote/stop_remote_repository.dart` | 17, 20 |
| `IncidentRemoteRepository` | `lib/data/incident/remote/incident_remote_repository.dart` | 26, 30 |
| `RouteFeedbackRemoteRepository` | `lib/data/route_feedback/remote/route_feedback_remote_repository.dart` | 20, 24 |

Each channel must be properly closed on dispose. The current implementation
(`lib/data/sync/realtime_channel_manager.dart:12`) uses a shared
`_reconnectTimer` and global `_reconnectAttempts` without verified
cancelation in dispose.

```dart
testWidgets('RealtimeChannelManager channels are disposed', (tester) async {
  final container = ProviderContainer(
    overrides: [routeRepositoryProvider.overrideWith(...)],
  );

  // Trigger a repository read that opens channels.
  container.read(routeRepositoryProvider);

  // Dispose removes listeners and closes channels.
  container.dispose();

  // Leak tracking should find no undisposed objects.
  LeakTesting.check();
});
```

### 2. Stream Subscriptions (Riverpod providers)

Riverpod's `.autoDispose` handles disposal when no listeners remain.
However, only **9 of 56 providers** (~16%) currently use `autoDispose`.
The remaining providers may leak stream subscriptions.

Key providers to verify:

```dart
test('autoDispose providers do not leak subscriptions', () {
  final container = ProviderContainer();

  // Read a provider that creates a stream subscription.
  container.read(realtimeTripsProvider);

  // Dispose should cancel the underlying subscription.
  container.dispose();

  LeakTesting.check();
});
```

Providers without autoDispose (risk of leak):
- `realtimeTripsProvider`
- `realtimeIncidentsProvider`
- `realtimeRouteUpdatesProvider`
- `mapDataCacheProvider`
- Repository providers with `RealtimeChannelManager`

### 3. Animation Controllers

`StaggerList` and other animated widgets create `AnimationController`
instances. These must be disposed when the widget is unmounted.

```dart
testWidgets('StaggerList disposes animation controllers', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: StaggerList(children: [Text('a'), Text('b')])),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  LeakTesting.check();
});
```

Also verify:
- `SmokeBackground` (shader ticker)
- `GradientText` (animated gradient)
- `TransitBottomSheet` (slide animation)
- `DataFreshnessIndicator` (pulse animation)

### 4. Map Resources

MapController in `lib/features/map/map_tab.dart:35-45` is not currently
disposed, which leaks the root WebSocket connection. Isolate-intensive.

```dart
testWidgets('MapController is disposed on unmount', (tester) async {
  await tester.pumpWidget(MaterialApp(home: TransitMap()));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  LeakTesting.check();
});
```

### 5. Focus Nodes and TextEditingControllers

Search bars, input fields, and dialogs that create `FocusNode` or
`TextEditingController` must dispose them:

- `lib/shared/widgets/transit_input.dart`
- `lib/shared/widgets/route_search_bar.dart`
- `lib/shared/widgets/single_field_dialog.dart`
- `lib/features/search/search_tab.dart`

## CI Integration

### GitHub Actions workflow

```yaml
# In .github/workflows/ci.yml, modify the test job:
- name: Run tests with leak tracking
  run: |
    flutter test --leak-tracking
  env:
    LEAK_TRACKING: 'true'
```

If `--leak-tracking` flag is not directly supported by `flutter test`, use
the `flutter_test_config.dart` approach (section 3 above) which runs before
every test file automatically.

### Make leak failures block CI

By default, `LeakTesting.check()` throws `TestFailure` on leak detection,
which makes `flutter test` exit non-zero. No additional configuration
needed — leaks become test failures.

### Gradual rollout

To avoid blocking CI with pre-existing leaks during initial rollout:

1. Enable `LeakTesting.enable()` globally via `test/flutter_test_config.dart`.
2. Set `LeakTesting.settings = LeakTesting.settings.withIgnored(...)` to
   suppress known leaks with issue tracker references.
3. Create a `leak_baseline.yaml` tracking known leak categories.
4. In CI, run `flutter test --leak-tracking --leak-baseline=leak_baseline.yaml`.
5. Reduce the baseline to zero over successive PRs.

## Known Limitations

- `leak_tracker_flutter_testing` adds 10-20% overhead to test execution time.
- False positives possible with lazy-loaded assets and `FutureBuilder` widgets
  that hold references until the future completes.
- Only checks objects created during the test scope; pre-existing objects
  from `setUp` or test infrastructure are not tracked.
- Does not detect logical leaks (e.g., steadily growing Hive box or FMTC
  cache with no eviction policy). These require separate monitoring.
- The package is **not yet in `pubspec.yaml`** — add it before
  any of the steps above can be executed.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-20 | Initial doc with basic snippets |
| 2.0 | 2026-05-22 | **F6.7:** actual setup instructions for this project: pubspec add, flutter_test_config.dart, test/helpers/leak_tracking.dart, pumpApp integration, inventory of 4 repos using RealtimeChannelManager, CI rollout plan |
