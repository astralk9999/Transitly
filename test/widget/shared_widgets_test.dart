import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/glass_card.dart';
import 'package:transitly/shared/widgets/pressable.dart';
import 'package:transitly/shared/widgets/status_badge.dart';
import 'package:transitly/shared/widgets/transit_button.dart';
import 'package:transitly/shared/widgets/transit_chip.dart';

import '../helpers/pump_app.dart';

void main() {
  group('Shared widgets rendering', () {
    testWidgets('Pressable renders child and responds to tap', (tester) async {
      bool tapped = false;
      await pumpApp(
        tester,
        child: Center(
          child: Pressable(
            onTap: () => tapped = true,
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Pressable));
      expect(tapped, isTrue);
      await unmount(tester);
    });

    testWidgets('GlassCard renders with default parameters', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: GlassCard(
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassCard), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitChip renders label', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitChip('L1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('L1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('StatusBadge renders CANCELED in red', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('CANCELED', Colors.red),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CANCELED'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('StatusBadge renders ON TIME in green', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: StatusBadge('ON TIME', Colors.green),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ON TIME'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton disabled state renders', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(label: 'Disabled', onPressed: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DISABLED'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('TransitButton with icon renders', (tester) async {
      await pumpApp(
        tester,
        child: const Center(
          child: TransitButton(
            label: 'With Icon',
            icon: Icons.star,
            onPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('WITH ICON'), findsOneWidget);
      await unmount(tester);
    });
  });
}
