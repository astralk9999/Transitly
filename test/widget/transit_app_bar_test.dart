import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/transit_app_bar.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitAppBar', () {
    testWidgets('renders title and back button by default', (tester) async {
      await pumpApp(
        tester,
        child: const TransitAppBar(title: 'Settings'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('hides back button when showBack is false', (tester) async {
      await pumpApp(
        tester,
        child: const TransitAppBar(title: 'Home', showBack: false),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      await unmount(tester);
    });
  });
}
