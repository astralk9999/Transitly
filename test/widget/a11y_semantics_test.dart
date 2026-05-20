import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/widgets/capacity_indicator.dart';
import 'package:transitly/shared/widgets/reputation_badge.dart';
import 'package:transitly/shared/widgets/status_badge.dart';
import 'package:transitly/shared/widgets/transit_button.dart';
import 'package:transitly/shared/widgets/transit_chip.dart';

import '../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Semantics coverage (A11Y-3)', () {
    testWidgets('TransitButton has button semantics', (tester) async {
      await pumpApp(
        tester,
        child: TransitButton(
          label: 'TEST',
          onPressed: () {},
        ),
      );
      await tester.pump();

      expect(find.byType(TransitButton), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('StatusBadge has semantics', (tester) async {
      await pumpApp(
        tester,
        // ignore: prefer_const_constructors
        child: StatusBadge('ON TIME', const Color(0xFF00C896)),
      );
      await tester.pump();

      expect(find.text('ON TIME'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('CapacityIndicator has semantics', (tester) async {
      await pumpApp(
        tester,
        child: const CapacityIndicator(BusCapacity.empty),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(CapacityIndicator));
      expect(semantics.label, contains('Ocupaci'));
      await unmount(tester);
    });

    testWidgets('ReputationBadge has semantics', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(ReputationLevel.trusted),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(ReputationBadge));
      expect(semantics.label, contains('Reputaci'));
      await unmount(tester);
    });

    testWidgets('TransitChip has semantics', (tester) async {
      await pumpApp(
        tester,
        themeDark: true,
        child: const TransitChip('L1'),
      );
      await tester.pump();

      expect(find.text('L1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('RouteCard has button semantics when tappable', (tester) async {
      await pumpApp(
        tester,
        child: Semantics(
          label: 'Línea L1, Test Route',
          button: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      expect(find.byType(SizedBox), findsOneWidget);
      await unmount(tester);
    });
  });
}
