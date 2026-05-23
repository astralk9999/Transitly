import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/core/theme/transit_colors.dart';

void main() {
  group('TransitColorScheme', () {
    test('dark scheme has correct values', () {
      const scheme = TransitDarkColors();

      expect(scheme, isA<TransitColorScheme>());

      expect(scheme.bgRoot, const Color(0xFF08081A));
      expect(scheme.bgSurface, const Color(0xFF10102A));
      expect(scheme.bgRaised, const Color(0xFF181838));

      expect(scheme.accent, const Color(0xFF977DDF));
      expect(scheme.neonCyan, const Color(0xFF00D4FF));
      expect(scheme.neonMagenta, const Color(0xFFFF006E));

      expect(scheme.textHi, const Color(0xFFF0F0FA));
      expect(scheme.textMid, const Color(0xFF8888A8));
      expect(scheme.textLo, const Color(0xFF8A87A5));

      expect(scheme.stateOnTime, const Color(0xFFB0FF00));
      expect(scheme.stateDelay, const Color(0xFFFF8C00));
      expect(scheme.stateCancelled, const Color(0xFFFF3B3B));

      expect(scheme.bgInput, const Color(0xFF0C0C1E));
      expect(scheme.border, const Color(0xFF1E1E3A));
    });

    test('light scheme has correct values', () {
      const scheme = TransitLightColors();

      expect(scheme, isA<TransitColorScheme>());

      expect(scheme.bgRoot, const Color(0xFFF4F4FB));
      expect(scheme.bgSurface, const Color(0xFFFFFEFF));
      expect(scheme.bgRaised, const Color(0xFFEBEBF5));

      expect(scheme.accent, const Color(0xFF7B64C0));
      expect(scheme.neonCyan, const Color(0xFF0099CC));
      expect(scheme.neonMagenta, const Color(0xFFCC0058));

      expect(scheme.textHi, const Color(0xFF111118));
      expect(scheme.textMid, const Color(0xFF555568));
      expect(scheme.textLo, const Color(0xFF8888A0));

      expect(scheme.stateOnTime, const Color(0xFF6DAA00));
      expect(scheme.stateDelay, const Color(0xFFD97700));
      expect(scheme.stateCancelled, const Color(0xFFDD2B2B));

      expect(scheme.bgInput, const Color(0xFFFFFEFF));
      expect(scheme.border, const Color(0xFFCCCCDD));
    });
  });

  group('TransitColorScheme.of', () {
    test('returns dark scheme when isDark is true', () {
      final scheme = TransitColorScheme.of(true);
      expect(scheme, isA<TransitDarkColors>());
    });

    test('returns light scheme when isDark is false', () {
      final scheme = TransitColorScheme.of(false);
      expect(scheme, isA<TransitLightColors>());
    });
  });
}
