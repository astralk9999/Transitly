import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_input.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitInput validation', () {
    testWidgets('shows error when validator fails', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpApp(
        tester,
        child: Scaffold(
          body: Form(
            key: formKey,
            child: TransitInput(
              hint: 'Email',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no error when validator returns null', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'hello');
      await pumpApp(
        tester,
        child: Scaffold(
          body: Form(
            key: formKey,
            child: TransitInput(
              hint: 'Name',
              controller: controller,
              validator: (v) => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.textContaining('Required'), findsNothing);
      controller.dispose();
      await unmount(tester);
    });

    testWidgets('supports maxLines > 1', (tester) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: TransitInput(
            hint: 'Description',
            maxLines: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransitInput), findsOneWidget);
      await unmount(tester);
    });
  });
}
