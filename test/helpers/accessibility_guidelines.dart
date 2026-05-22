import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AccessibilityGuidelines {
  AccessibilityGuidelines._();

  static void meetsTapTargetGuideline(Size size) {
    expect(size.width, greaterThanOrEqualTo(48),
        reason: 'Tap target width must be >= 48dp (WCAG 2.5.5 Target Size)');
    expect(size.height, greaterThanOrEqualTo(48),
        reason: 'Tap target height must be >= 48dp (WCAG 2.5.5)');
  }

  static void meetsTextContrastGuideline(Color text, Color background,
      {double minimum = 4.5}) {
    final ratio = _contrastRatio(text, background);
    expect(ratio, greaterThanOrEqualTo(minimum),
        reason: 'Contrast ratio $ratio:1 must be >= $minimum:1 for text');
  }

  static void meetsLargeTextContrastGuideline(Color text, Color background) {
    meetsTextContrastGuideline(text, background, minimum: 3.0);
  }

  static void meetsUIComponentContrastGuideline(
      Color component, Color background) {
    meetsTextContrastGuideline(component, background, minimum: 3.0);
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

extension GuidelineChecks on WidgetTester {
  Future<void> meetsAccessibilityGuidelines() async {
    // Check all tappable widgets have sufficient size
    for (final type in <Type>[
      ElevatedButton,
      TextButton,
      IconButton,
      OutlinedButton,
      InkWell,
    ]) {
      for (final widget in widgetList(find.byType(type))) {
        final rect = getRect(find.byWidget(widget));
        AccessibilityGuidelines.meetsTapTargetGuideline(rect.size);
      }
    }
  }
}
