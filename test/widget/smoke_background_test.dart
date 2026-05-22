import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/smoke_background.dart';
import '../helpers/pump_app.dart';

void main() {
  group('SmokeBackground', () {
    testWidgets('renders with gradient fallback in dark mode', (tester) async {
      await pumpApp(
        tester,
        themeDark: true,
        child: const SmokeBackground(
          isDark: true,
          child: Text('Behind Smoke'),
        ),
      );
      await tester.pump();
      expect(find.text('Behind Smoke'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders with reduceMotion=true', (tester) async {
      await pumpApp(
        tester,
        themeDark: true,
        child: const SmokeBackground(
          isDark: true,
          reduceMotion: true,
          child: Icon(Icons.star),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
      await unmount(tester);
    });
  });
}
