import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/pressable.dart';
import '../helpers/pump_app.dart';

void main() {
  group('Pressable', () {
    testWidgets('has minimum 48dp tap target via ConstrainedBox', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: Pressable(
            child: Text('Tap me'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final pressableBox = boxes.firstWhere(
        (b) => b.constraints.minWidth == 48.0 && b.constraints.minHeight == 48.0,
      );
      expect(pressableBox.constraints.minWidth, 48.0);
      expect(pressableBox.constraints.minHeight, 48.0);
      await unmount(tester);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        child: Scaffold(
          body: Pressable(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Pressable));
      await tester.pump();
      expect(tapped, isTrue);
      await unmount(tester);
    });
  });
}
