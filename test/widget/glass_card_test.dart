import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/glass_card.dart';
import '../helpers/pump_app.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child widget', (tester) async {
      await pumpApp(
        tester,
        child: const GlassCard(
          child: Text('Hello Glass'),
        ),
      );
      await tester.pump();
      expect(find.text('Hello Glass'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders with custom borderRadius', (tester) async {
      await pumpApp(
        tester,
        child: const GlassCard(
          borderRadius: 24.0,
          child: SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(SizedBox), findsOneWidget);
      await unmount(tester);
    });
  });
}
