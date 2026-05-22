import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_chip.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitChip', () {
    testWidgets('renders label text', (tester) async {
      await pumpApp(
        tester,
        child: const TransitChip('L1'),
      );
      await tester.pumpAndSettle();
      expect(find.text('L1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders with color and onTap without crash', (tester) async {
      bool tapped = false;
      await pumpApp(
        tester,
        child: TransitChip(
          '42',
          color: Colors.amber,
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
      await tester.tap(find.text('42'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      await unmount(tester);
    });
  });
}
