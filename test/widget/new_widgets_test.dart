import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/contextual_help_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ContextualHelpButton', () {
    testWidgets('renders icon button', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: ContextualHelpButton(
            title: 'Help',
            message: 'This is help text',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(IconButton), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('shows dialog on tap', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: ContextualHelpButton(
            title: 'Help',
            message: 'This is help text',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Help'), findsWidgets);
      expect(find.text('This is help text'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await unmount(tester);
    });
  });
}
