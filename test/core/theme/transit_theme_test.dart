import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/core/theme/transit_colors.dart';

void main() {
  group('TransitColorScheme', () {
    test('TransitColorScheme.of returns dark for isDark=true', () {
      final scheme = TransitColorScheme.of(true);
      expect(scheme, isA<TransitDarkColors>());
    });

    test('TransitColorScheme.of returns light for isDark=false', () {
      final scheme = TransitColorScheme.of(false);
      expect(scheme, isA<TransitLightColors>());
    });

    test('dark and light schemes differ', () {
      final dark = TransitColorScheme.of(true);
      final light = TransitColorScheme.of(false);
      expect(dark.bgRoot, isNot(light.bgRoot));
      expect(dark.textHi, isNot(light.textHi));
      expect(dark.accent, isNot(light.accent));
    });
  });
}
