import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/user_preferences.dart';

void main() {
  group('UserPreferences', () {
    test('defaults are correct', () {
      final prefs = const UserPreferences(userId: 'u1');
      expect(prefs.userId, 'u1');
      expect(prefs.themePaletteId, 'default');
      expect(prefs.backgroundId, 'smoke');
      expect(prefs.backgroundEnabled, true);
      expect(prefs.backgroundOpacity, 1.0);
      expect(prefs.fontScale, 1.0);
      expect(prefs.colorBlindMode, ColorBlindMode.none);
      expect(prefs.dyslexiaFontEnabled, false);
      expect(prefs.reduceMotion, false);
      expect(prefs.highContrast, false);
      expect(prefs.mapStyle, 'streets');
      expect(prefs.notifIncidentResolved, true);
      expect(prefs.notifRoutePromoted, true);
      expect(prefs.notifBusApproaching, true);
      expect(prefs.notifFeatureRequestReplied, true);
      expect(prefs.quietHoursEnabled, false);
      expect(prefs.extendedTimers, false);
    });

    test('colorBlindMode enum has all values', () {
      expect(ColorBlindMode.values, [
        ColorBlindMode.none,
        ColorBlindMode.protanopia,
        ColorBlindMode.deuteranopia,
        ColorBlindMode.tritanopia,
        ColorBlindMode.protanomaly,
        ColorBlindMode.deuteranomaly,
        ColorBlindMode.tritanomaly,
        ColorBlindMode.achromatopsia,
        ColorBlindMode.achromatomaly,
      ]);
    });

    test('extendedTimers can be set and persisted', () {
      final prefs = const UserPreferences(userId: 'u1');
      final updated = prefs.copyWith(extendedTimers: true);
      expect(updated.extendedTimers, true);
      expect(updated.userId, 'u1');
      final reverted = updated.copyWith(extendedTimers: false);
      expect(reverted.extendedTimers, false);
    });
  });
}
