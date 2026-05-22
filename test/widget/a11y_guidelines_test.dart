import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A11y programmatic checks', () {
    testWidgets('tap target minimum 48x48 dp check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
        ),
      );

      final constraints = tester.getSize(find.byType(ElevatedButton));

      expect(constraints.width, greaterThanOrEqualTo(48),
          reason: 'Tap target width must be >= 48dp (WCAG 2.5.5)');
      expect(constraints.height, greaterThanOrEqualTo(48),
          reason: 'Tap target height must be >= 48dp (WCAG 2.5.5)');
    });

    testWidgets('icon button tap target is at least 48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
                iconSize: 24,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
          ),
        ),
      );

      final iconBtn = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconBtn.constraints?.minWidth, greaterThanOrEqualTo(48),
          reason: 'IconButton minWidth must be >= 48dp');
      expect(iconBtn.constraints?.minHeight, greaterThanOrEqualTo(48),
          reason: 'IconButton minHeight must be >= 48dp');
    });

    testWidgets('contrast ratio between text and background is sufficient',
        (tester) async {
      const bgColor = Color(0xFF0B0E17);
      const textColor = Color(0xFFFFFFFF);

      final bgLuminance = bgColor.computeLuminance();
      final textLuminance = textColor.computeLuminance();

      final lighter =
          bgLuminance > textLuminance ? bgLuminance : textLuminance;
      final darker =
          bgLuminance > textLuminance ? textLuminance : bgLuminance;
      final ratio = (lighter + 0.05) / (darker + 0.05);

      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Contrast ratio must be >= 4.5:1 for normal text (WCAG AA)');
    });

    testWidgets('color is not the only visual indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline),
                  SizedBox(width: 8),
                  Text('Error: connection lost'),
                ],
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final text = tester.widget<Text>(find.byType(Text));

      expect(icon.icon, isNotNull,
          reason: 'Status indicator must use icon, not color alone');
      expect(text.data, isNotEmpty,
          reason: 'Status indicator must use text, not color alone');
    });
  });
}
