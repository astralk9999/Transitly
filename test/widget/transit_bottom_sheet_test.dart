import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/transit_bottom_sheet.dart';
import '../helpers/pump_app.dart';

void main() {
  group('TransitBottomSheet', () {
    testWidgets('shows content via builder', (tester) async {
      await pumpApp(
        tester,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTransitBottomSheet<dynamic>(
              context: context,
              builder: (_) => const Text('Sheet Content'),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Sheet Content'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders handle bar', (tester) async {
      await pumpApp(
        tester,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTransitBottomSheet<dynamic>(
              context: context,
              builder: (_) => const SizedBox(height: 100),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.close), findsOneWidget);
      await unmount(tester);
    });
  });
}
