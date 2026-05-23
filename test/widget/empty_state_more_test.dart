import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/empty_state.dart';
import '../helpers/pump_app.dart';

void main() {
  group('EmptyState edge', () {
    testWidgets('actionLabel without onAction renders no button', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState('Title', 'Sub', actionLabel: 'Go'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Go'), findsNothing);
      await unmount(tester);
    });

    testWidgets('actionLabel with onAction renders tappable button', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        child: EmptyState(
          'Title',
          'Sub',
          actionLabel: 'Act',
          onAction: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACT'));
      expect(tapped, isTrue);
      await unmount(tester);
    });
  });
}
