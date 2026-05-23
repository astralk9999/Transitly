import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_checkbox.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitCheckbox more', () {
    testWidgets('renders checkmark when value is true', (tester) async {
      await pumpApp(
        tester,
        child: TransitCheckbox(true, (_) {}, 'Active'),
      );
      await tester.pumpAndSettle();

      final checkbox = find.byType(TransitCheckbox);
      expect(checkbox, findsOneWidget);

      final icon = find.byIcon(Icons.check);
      expect(icon, findsOneWidget,
          reason: 'Checkmark should be visible when value is true');

      await unmount(tester);
    });

    testWidgets('toggles from true to false when tapped', (tester) async {
      bool checked = true;
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
      expect(checked, isFalse,
          reason: 'Should toggle from true to false on tap');

      await unmount(tester);
    });
  });
}
