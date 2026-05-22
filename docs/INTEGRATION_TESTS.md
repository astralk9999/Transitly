# Integration Tests — Transitly

> **Version:** 1.0 · **Framework:** `integration_test` package · **Reference:** PRO-Snr-14, PRO-QA-07

## Setup

```yaml
# pubspec.yaml (dev_dependencies)
dev_dependencies:
  integration_test:
    sdk: flutter
```

## Test Structure

```
integration_test/
├── happy_path_test.dart       # 3 critical user journeys
├── auth_flow_test.dart        # Sign in → home → sign out
├── incident_report_test.dart  # Report incident end-to-end
└── helpers/
    └── integration_helpers.dart
```

## Happy Path Tests

### 1. Guest browses routes and stops

```dart
// integration_test/happy_path_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest browses home → route detail → stop detail', (tester) async {
    await tester.pumpWidget(const TransitlyApp());
    await tester.pumpAndSettle();

    // Home tab shows routes
    expect(find.text('TRANSITLY'), findsOneWidget);

    // Tap on a route
    await tester.tap(find.text('L1').first);
    await tester.pumpAndSettle();

    // Route detail shows stops
    expect(find.byType(ListView), findsWidgets);
  });
}
```

### 2. User signs in and views profile

```dart
testWidgets('User signs in with email', (tester) async {
  // Navigate to sign-in
  // Enter credentials
  // Verify authenticated state
  // Navigate to profile
});
```

### 3. User reports an incident

```dart
testWidgets('User reports incident from stop detail', (tester) async {
  // Navigate to a stop
  // Tap "Report"
  // Select incident type
  // Submit
  // Verify success message
});
```

## Running

```bash
# On connected device/emulator
flutter test integration_test/

# Specific test
flutter test integration_test/happy_path_test.dart

# With screenshot on failure
flutter test --update-goldens integration_test/
```

## CI Integration

```yaml
# .github/workflows/ci.yml
integration-test:
  name: Integration Tests (Android)
  runs-on: macos-latest
  timeout-minutes: 30
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: "3.35.x"
    - name: Run integration tests
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 34
        script: flutter test integration_test/
```

## Notes

- Integration tests require a device/emulator (not headless)
- Mock Supabase responses using `MockSupabaseClient` or real staging environment
- Each test should be independent (setup and teardown)
- Use `pumpAndSettle()` to wait for animations
- Target: 3 happy path tests covering critical user journeys
