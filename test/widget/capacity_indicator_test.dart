import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/widgets/capacity_indicator.dart';
import '../helpers/pump_app.dart';

void main() {
  group('CapacityIndicator', () {
    testWidgets('renders BusCapacity.empty', (tester) async {
      await pumpApp(
        tester,
        child: const CapacityIndicator(BusCapacity.empty),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CapacityIndicator), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      await pumpApp(
        tester,
        child: const CapacityIndicator(
          BusCapacity.full,
          showLabel: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lleno'), findsOneWidget);
      await unmount(tester);
    });
  });
}
