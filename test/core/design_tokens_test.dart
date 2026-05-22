import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/theme/accessibility_matrix.dart';
import 'package:transitly/core/theme/transit_spacing.dart';

void main() {
  group('Design tokens validation', () {
    test('TransitSpacing.minTapTarget is 48dp', () {
      expect(TransitSpacing.minTapTarget, greaterThanOrEqualTo(48.0),
          reason: 'WCAG 2.5.5 requires minimum 48dp tap target');
    });

    test('AccessibilityMatrix returns identity for unknown mode', () {
      final matrix = AccessibilityMatrix.forMode('unknown_mode');
      // Identity matrix: diagonal is 1, rest are 0
      expect(matrix[0], 1.0);
      expect(matrix[6], 1.0); // row 1, col 1
      expect(matrix[12], 1.0); // row 2, col 2
      expect(matrix[18], 1.0); // row 3, col 3
      expect(matrix[1], 0.0); // off-diagonal should be 0
    });

    test('AccessibilityMatrix protanopia matrix is valid', () {
      final matrix = AccessibilityMatrix.forMode('protanopia');
      expect(matrix.length, 20);
      // Should not be identity (has modifications)
      expect(matrix[0], isNot(1.0));
    });

    test('AccessibilityMatrix deuteranopia matrix is valid', () {
      final matrix = AccessibilityMatrix.forMode('deuteranopia');
      expect(matrix.length, 20);
      expect(matrix[0], isNot(1.0));
    });

    test('AccessibilityMatrix tritanopia matrix is valid', () {
      final matrix = AccessibilityMatrix.forMode('tritanopia');
      expect(matrix.length, 20);
      expect(matrix[0], isNot(1.0));
    });

    test('AccessibilityMatrix anomaly matrices are valid', () {
      for (final mode in [
        'protanomaly',
        'deuteranomaly',
        'tritanomaly',
        'achromatopsia',
        'achromatomaly',
      ]) {
        final matrix = AccessibilityMatrix.forMode(mode);
        expect(matrix.length, 20, reason: '$mode matrix must have 20 values');
        expect(matrix[0], isNot(1.0),
            reason: '$mode matrix should not be identity');
      }
    });

    test('AccessibilityMatrix achromatopsia is grayscale', () {
      final matrix = AccessibilityMatrix.forMode('achromatopsia');
      // RGB rows should have same luminance weights
      expect(matrix[0], matrix[5]);
      expect(matrix[0], matrix[10]);
    });

    test('TransitSpacing constants are positive', () {
      expect(TransitSpacing.space2, greaterThan(0));
      expect(TransitSpacing.space4, greaterThan(0));
      expect(TransitSpacing.space8, greaterThan(0));
      expect(TransitSpacing.space16, greaterThan(0));
    });
  });
}
