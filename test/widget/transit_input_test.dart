import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_input.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitInput', () {
    testWidgets('renders with hint text', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: TransitInput(hint: 'Email'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await pumpApp(
        tester,
        child: Scaffold(
          body: TransitInput(hint: 'Name', controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Test');
      expect(controller.text, 'Test');
      controller.dispose();
      await unmount(tester);
    }, skip: true);

    testWidgets('renders with validator without crashing', (tester) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: TransitInput(
            hint: 'Required',
            validator: (v) => v!.isEmpty ? 'Required field' : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransitInput), findsOneWidget);
      await unmount(tester);
    }, skip: true);
  });
}
