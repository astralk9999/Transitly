import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/status_badge.dart';

import '../helpers/pump_app.dart';

void main() {
  group('StatusBadge more', () {
    testWidgets('renders text in uppercase regardless of input case', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('delayed', Colors.orange),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DELAYED'), findsOneWidget);
      expect(find.text('delayed'), findsNothing);
      await unmount(tester);
    });

    testWidgets('applies container decoration with border', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('BOARDING', Colors.blue),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('BOARDING'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, BorderRadius.circular(6));
      await unmount(tester);
    });

    testWidgets('uses stateColor with alpha for background and border', (tester) async {
      const color = Color(0xFF00FF00);
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('ACTIVE', color),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('ACTIVE'), matching: find.byType(Container)).first,
      );
      final bg = (container.decoration! as BoxDecoration).color!;
      expect(bg.a, lessThan(255));
      await unmount(tester);
    });
  });
}
