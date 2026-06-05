import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/features/home/widgets/profile_accessibility_section.dart';
import 'package:transitly/shared/models/user_preferences.dart';

void main() {
  group('buildAccessibilitySummary', () {
    test('all defaults → "Sin ajustes activos"', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: false,
        highContrast: false,
      );
      expect(s, equals('Sin ajustes activos'));
    });

    test('only dyslexia ON', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: true,
        highContrast: false,
      );
      expect(s, equals('Dislexia activa'));
    });

    test('only color blind mode', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.deuteranopia,
        dyslexiaEnabled: false,
        highContrast: false,
      );
      expect(s, equals('Daltonismo: deuteranopia'));
    });

    test('only high contrast', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: false,
        highContrast: true,
      );
      expect(s, equals('Contraste alto'));
    });

    test('combo of all three is joined with " · "', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.tritanopia,
        dyslexiaEnabled: true,
        highContrast: true,
      );
      expect(s, equals(
          'Daltonismo: tritanopia · Dislexia activa · Contraste alto'));
    });
  });
}
