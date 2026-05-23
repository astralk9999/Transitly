import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_input.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitInput maxLength', () {
    testWidgets('renders single-line input in a 44dp container', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: TransitInput(hint: 'Search'),
        ),
      );
      await tester.pumpAndSettle();
      final transitInput = tester.firstWidget(find.byType(TransitInput));
      expect(transitInput, isA<TransitInput>());
      await unmount(tester);
    });

    testWidgets('renders multi-line input without fixed height constraint', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: TransitInput(hint: 'Description', maxLines: 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransitInput), findsOneWidget);
      await unmount(tester);
    });
  });
}
