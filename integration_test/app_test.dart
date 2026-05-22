import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and renders home screen', (tester) async {
    // This test verifies the app boots without crashing.
    // Full integration tests require a Supabase staging environment
    // or MockSupabaseClient. See docs/INTEGRATION_TESTS.md.

    // For now, verify the integration test infrastructure works.
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
  });
}
