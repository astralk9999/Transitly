import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/core/theme/transit_colors.dart';

void main() {
  group('TransitColorScheme edge', () {
    test('all four neon colors differ from accent', () {
      final dark = TransitColorScheme.of(true);
      final neons = [dark.neonCyan, dark.neonMagenta, dark.neonPurple, dark.neonBlue];
      for (final n in neons) {
        expect(n, isNot(dark.accent));
      }
    });

    test('gradientAccent has exactly two stops', () {
      final dark = TransitColorScheme.of(true);
      expect(dark.gradientAccent.colors.length, 2);
    });

    test('dark and light schemes have different bgRoot', () {
      final dark = TransitColorScheme.of(true);
      final light = TransitColorScheme.of(false);
      expect(dark.bgRoot, isNot(light.bgRoot));
    });
  });
}
