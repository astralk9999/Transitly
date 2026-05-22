import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/error_card.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ErrorCard', () {
    testWidgets('renders error message', (tester) async {
      await pumpApp(tester, child: const ErrorCard('Something went wrong'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Something went wrong'), findsOneWidget);
      await unmount(tester);
    });
    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;
      await pumpApp(tester, child: ErrorCard('Error', onRetry: () => retried = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REINTENTAR'));
      expect(retried, isTrue);
      await unmount(tester);
    });
    testWidgets('renders without retry button', (tester) async {
      await pumpApp(tester, child: const ErrorCard('Fatal error'));
      await tester.pumpAndSettle();
      expect(find.text('REINTENTAR'), findsNothing);
      await unmount(tester);
    });
  });
}
