import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/data_freshness_indicator.dart';
import '../helpers/pump_app.dart';

void main() {
  group('DataFreshnessIndicator', () {
    testWidgets('renders updated today text', (tester) async {
      await pumpApp(
        tester,
        child: DataFreshnessIndicator(DateTime.now()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Actualizado hoy'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('shows pending feedback count when > 0', (tester) async {
      await pumpApp(
        tester,
        child: DataFreshnessIndicator(
          DateTime.now(),
          pendingFeedback: 5,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('5 pendientes'), findsOneWidget);
      await unmount(tester);
    });
  });
}
