import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/user_preferences.dart';

import '../shared_test_repositories.dart';

void main() {
  group('UserPreferencesRepository mock', () {
    test('getMine returns default guest prefs', () async {
      final repo = mockUserPreferencesRepo();
      final prefs = await repo.getMine();
      expect(prefs.userId, 'test');
      expect(prefs.themePaletteId, 'default');
    });

    test('update persists and returns new prefs', () async {
      final repo = mockUserPreferencesRepo();
      final updated = await repo.update(
        const UserPreferences(userId: 'test', themePaletteId: 'ocean'),
      );
      expect(updated.themePaletteId, 'ocean');
      final cached = await repo.getMine();
      expect(cached.themePaletteId, 'ocean');
    });

    test('update overrides all fields', () async {
      final repo = mockUserPreferencesRepo();
      const newPrefs = UserPreferences(
        userId: 'test',
        backgroundEnabled: false,
        fontScale: 1.5,
        reduceMotion: true,
        highContrast: true,
      );
      final result = await repo.update(newPrefs);
      expect(result.backgroundEnabled, false);
      expect(result.fontScale, 1.5);
      expect(result.reduceMotion, true);
      expect(result.highContrast, true);
    });
  });
}
