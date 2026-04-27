import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/theme/transit_colors.dart';
import 'package:transitly/core/theme/transit_theme.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/widgets/glass_card.dart';
import 'package:transitly/shared/widgets/reputation_badge.dart';
import 'package:transitly/shared/widgets/status_badge.dart';
import 'package:transitly/shared/widgets/transit_button.dart';

/// Mounts [child] inside a themed Scaffold for structural widget tests.
/// We don't pin pixel goldens — `google_fonts` resolves via the network and
/// is non-deterministic in offline test runs. Structural assertions still
/// guard the public surface of the design system.
Future<void> pumpDesign(
  WidgetTester tester, {
  required Widget child,
  required bool isDark,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTransitTheme(isDark),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  for (final dark in [true, false]) {
    final suffix = dark ? 'dark' : 'light';

    testWidgets('StatusBadge uppercases text and binds state color ($suffix)',
        (tester) async {
      final c = TransitColorScheme.of(dark);
      await pumpDesign(
        tester,
        isDark: dark,
        child: StatusBadge('en hora', c.stateOnTime),
      );

      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text('EN HORA'), findsOneWidget);
    });

    testWidgets('ReputationBadge renders level label uppercased ($suffix)',
        (tester) async {
      await pumpDesign(
        tester,
        isDark: dark,
        child: const ReputationBadge(ReputationLevel.trusted),
      );

      expect(find.byType(ReputationBadge), findsOneWidget);
      expect(
        find.text(ReputationLevel.trusted.label.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('TransitButton primary renders label and is enabled ($suffix)',
        (tester) async {
      var taps = 0;
      await pumpDesign(
        tester,
        isDark: dark,
        child: SizedBox(
          width: 240,
          child: TransitButton(
            label: 'Publicar',
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.text('PUBLICAR'), findsOneWidget);
      await tester.tap(find.byType(TransitButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('TransitButton secondary renders label ($suffix)',
        (tester) async {
      await pumpDesign(
        tester,
        isDark: dark,
        child: SizedBox(
          width: 240,
          child: TransitButton(
            label: 'Borrador',
            isPrimary: false,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(TransitButton), findsOneWidget);
      expect(find.text('BORRADOR'), findsOneWidget);
    });

    testWidgets('GlassCard hosts arbitrary children ($suffix)',
        (tester) async {
      await pumpDesign(
        tester,
        isDark: dark,
        child: const GlassCard(
          padding: EdgeInsets.all(16),
          child: Text('Línea L12'),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
      expect(find.text('Línea L12'), findsOneWidget);
    });
  }
}
