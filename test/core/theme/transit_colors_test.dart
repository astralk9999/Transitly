import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/theme/transit_colors.dart';

void main() {
  group('TransitColorScheme', () {
    test('dark theme textHi has high contrast on bgRoot', () {
      final dark = TransitColorScheme.of(true);
      final ratio = _contrast(dark.textHi, dark.bgRoot);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('dark theme accent has sufficient contrast', () {
      final dark = TransitColorScheme.of(true);
      final ratio = _contrast(dark.accent, dark.bgRoot);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('light theme textHi on bgRoot meets AA', () {
      final light = TransitColorScheme.of(false);
      final ratio = _contrast(light.textHi, light.bgRoot);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('state tokens exist for both themes', () {
      final dark = TransitColorScheme.of(true);
      final light = TransitColorScheme.of(false);
      expect(dark.stateDelay, isNotNull);
      expect(light.stateDelay, isNotNull);
    });
  });
}

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
