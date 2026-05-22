import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_checkbox.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitCheckbox', () {
    testWidgets('renders label', (tester) async {
      await pumpApp(
        tester,
        child: TransitCheckbox(false, (_) {}, 'Accept terms'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accept terms'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('toggles value', (tester) async {
      bool checked = false;
      await pumpApp(
        tester,
        child: StatefulBuilder(
          builder: (ctx, setState) => TransitCheckbox(
            checked,
            (v) => setState(() => checked = v),
            'Toggle',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      expect(checked, isTrue);
      await unmount(tester);
    });
  });
}
