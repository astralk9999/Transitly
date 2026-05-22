import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/stagger_list.dart';
import '../helpers/pump_app.dart';

void main() {
  group('StaggerList', () {
    testWidgets('renders children', (tester) async {
      await pumpApp(
        tester,
        disableAnimations: true,
        child: const StaggerList(
          children: [
            Text('Item A'),
            Text('Item B'),
            Text('Item C'),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('shows all children with disableAnimations', (tester) async {
      await pumpApp(
        tester,
        disableAnimations: true,
        child: StaggerList(
          children: List.generate(
            5,
            (i) => Text('Child $i'),
          ),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        expect(find.text('Child $i'), findsOneWidget);
      }
      await unmount(tester);
    });
  });
}
