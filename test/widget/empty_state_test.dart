import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/empty_state.dart';
import '../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title and subtitle', (tester) async {
      await pumpApp(tester, child: const EmptyState('No data', 'Try again later'));
      await tester.pumpAndSettle();
      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      await unmount(tester);
    });
    testWidgets('renders with custom icon', (tester) async {
      await pumpApp(tester, child: const EmptyState('Empty', '', icon: Icons.inbox));
      await tester.pumpAndSettle();
      expect(find.text('Empty'), findsOneWidget);
      await unmount(tester);
    });
  });
}
