# Leak Tracker — Transitly

> **Version:** 1.0 · **Package:** `leak_tracker_flutter_testing`

## Setup

`leak_tracker_flutter_testing` detects memory leaks in widget and provider
tests by tracking object disposal.

```yaml
# pubspec.yaml (dev_dependencies)
dev_dependencies:
  leak_tracker_flutter_testing: ^3.0.0
```

## Configuration

```dart
// test/helpers/leak_tracking.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// Enable leak tracking globally
void main() {
  LeakTesting.enable();
}

// Or per-test:
testWidgets('RealtimeChannelManager does not leak', (tester) async {
  await tester.pumpWidget(...);
  
  LeakTesting.check(
    additionalCheck: (leaks) {
      expect(leaks.notDisposed, isEmpty,
          reason: 'Objects must be disposed after test');
      expect(leaks.notGCed, isEmpty,
          reason: 'Objects must be garbage-collectable');
    },
  );
});
```

## Critical Areas to Monitor

### 1. RealtimeChannelManager

The `RealtimeChannelManager` opens WebSocket channels via Supabase Realtime.
Each channel must be properly closed on dispose.

```dart
testWidgets('RealtimeChannelManager channels are disposed', (tester) async {
  final manager = RealtimeChannelManager(client: mockClient);
  
  manager.watch('bus_location');
  manager.watch('incident');
  
  manager.dispose();
  
  // Verify no active channels
  LeakTesting.check();
});
```

### 2. Stream Subscriptions

Riverpod's `.autoDispose` handles disposal when no listeners remain. Verify
with leak tracking:

```dart
test('StreamProvider disposes subscription', () {
  final container = ProviderContainer(
    overrides: [realtimeTripsProvider.overrideWith((ref) => mockStream)],
  );
  
  container.read(realtimeTripsProvider);
  container.dispose();
  
  LeakTesting.check();
});
```

### 3. Animation Controllers

```dart
testWidgets('StaggerList disposes animation controllers', (tester) async {
  await tester.pumpWidget(StaggerList(...));
  await tester.pumpWidget(const SizedBox()); // unmount
  await tester.pumpAndSettle();
  
  LeakTesting.check();
});
```

## CI Integration

```yaml
# In .github/workflows/ci.yml
- name: Run tests with leak tracking
  run: flutter test --leak-tracking
```

## Known Limitations

- `leak_tracker_flutter_testing` adds overhead (~10-20% slower tests)
- False positives possible with lazy-loaded assets
- Only checks objects created during the test scope
