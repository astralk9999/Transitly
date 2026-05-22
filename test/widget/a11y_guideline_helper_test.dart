import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/accessibility_guidelines.dart';

void main() {
  group('AccessibilityGuidelines helper', () {
    testWidgets('meetsTapTargetGuideline passes for 48x48', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: null,
                  child: Text('OK'),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(ElevatedButton));
      AccessibilityGuidelines.meetsTapTargetGuideline(size);
    });

    testWidgets('meetsTextContrastGuideline passes for dark theme tokens',
        (tester) async {
      const bgColor = Color(0xFF08081A);
      const textHi = Color(0xFFFFFFFF);
      const textMid = Color(0xFF9B97C2);
      const accent = Color(0xFF977DDF);

      AccessibilityGuidelines.meetsTextContrastGuideline(textHi, bgColor);
      AccessibilityGuidelines.meetsTextContrastGuideline(textMid, bgColor);
      AccessibilityGuidelines.meetsTextContrastGuideline(accent, bgColor);
    });

    testWidgets('meetsLargeTextContrastGuideline passes for dark theme',
        (tester) async {
      const bgRoot = Color(0xFF08081A);
      const textLo = Color(0xFF5B5890);

      AccessibilityGuidelines.meetsLargeTextContrastGuideline(textLo, bgRoot);
    });

    testWidgets('meetsUIComponentContrastGuideline passes for state tokens',
        (tester) async {
      const bgRoot = Color(0xFF08081A);
      const stateDelay = Color(0xFFFF8C42);
      const stateCancelled = Color(0xFFFF4545);

      AccessibilityGuidelines.meetsUIComponentContrastGuideline(
          stateDelay, bgRoot);
      AccessibilityGuidelines.meetsUIComponentContrastGuideline(
          stateCancelled, bgRoot);
    });

    test('contrast ratio calculation produces expected values', () {
      // White on black = 21:1
      final l1 = const Color(0xFFFFFFFF).computeLuminance();
      final l2 = const Color(0xFF000000).computeLuminance();
      final ratio = (l1 + 0.05) / (l2 + 0.05);
      expect(ratio, closeTo(21.0, 0.1));
    });
  });
}
