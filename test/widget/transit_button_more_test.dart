import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/transit_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TransitButton more', () {
    testWidgets('danger variant renders with danger styling', (tester) async {
      bool tapped = false;
      await pumpApp(
        tester,
        child: Center(
          child: TransitButton(
            label: 'Delete',
            isDanger: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DELETE'), findsOneWidget);
      expect(find.byType(TransitButton), findsOneWidget);
      await tester.tap(find.byType(TransitButton));
      expect(tapped, isTrue);
      await unmount(tester);
    });

    testWidgets('loading state shows CircularProgressIndicator instead of label', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'Save',
            isLoading: true,
            onPressed: null,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SAVE'), findsNothing);
      await unmount(tester);
    });

    testWidgets('small variant has isSmall set to true', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'Small',
            isSmall: true,
            onPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<TransitButton>(find.byType(TransitButton));
      expect(button.isSmall, isTrue);
      expect(button.label, 'Small');
      await unmount(tester);
    });
  });
}
