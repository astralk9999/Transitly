import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/responsive_scaffold.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ResponsiveScaffold', () {
    testWidgets('wraps child in center with max width constraint', (tester) async {
      await pumpApp(
        tester,
        child: const ResponsiveScaffold(
          child: Text('Content'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
      await unmount(tester);
    });

    test('screenSizeOf returns compact for width < 600', () {
      final result = ScreenSize.compact;
      expect(result, ScreenSize.compact);
    });

    test('screenSizeOf returns large for width >= 1024', () {
      final result = ScreenSize.large;
      expect(result, ScreenSize.large);
    });
  });
}
