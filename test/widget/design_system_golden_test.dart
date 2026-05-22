import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/status_badge.dart';
import 'package:transitly/shared/widgets/transit_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('Design system rendering tests', () {
    testWidgets('StatusBadge renders in dark theme', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('ACTIVE', Colors.green),
        ),
        themeDark: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('StatusBadge renders in light theme', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('DELAYED', Colors.orange),
        ),
        themeDark: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('DELAYED'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton primary renders in dark theme', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(label: 'Primary', onPressed: null),
        ),
        themeDark: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('PRIMARY'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton secondary renders in light theme', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'Secondary',
            isPrimary: false,
            onPressed: null,
          ),
        ),
        themeDark: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('SECONDARY'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton danger renders in dark', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'Danger',
            isDanger: true,
            onPressed: null,
          ),
        ),
        themeDark: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('DANGER'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton small renders', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'Small',
            isSmall: true,
            onPressed: null,
          ),
        ),
        themeDark: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('SMALL'), findsOneWidget);
      await unmount(tester);
    });
  });
}
