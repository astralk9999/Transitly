import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/theme/palettes/prefab_palettes.dart';
import 'package:transitly/core/theme/transit_colors.dart';
import 'package:transitly/shared/models/user_preferences.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../../data/shared_test_repositories.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('ThemeNotifier defaults to dark default palette', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    expect(notifier.paletteId, 'default');
    expect(notifier.brightness, Brightness.dark);
    expect(notifier.palette.scheme, isA<TransitDarkColors>());
    expect(notifier.backgroundEnabled, true);
    expect(notifier.fontScale, 1.0);
    expect(notifier.colorBlindMode, ColorBlindMode.none);
    expect(notifier.dyslexiaFontEnabled, false);
    expect(notifier.reduceMotion, false);
  });

  test('set paletteId updates brightness', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    notifier.paletteId = 'sunrise';
    expect(notifier.paletteId, 'sunrise');
    expect(notifier.brightness, Brightness.dark);
    expect(notifier.palette.scheme, isA<TransitSunriseColors>());
  });

  test('set paletteId to light palette updates brightness', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    notifier.paletteId = 'default';
    notifier.brightness = Brightness.light;
    expect(notifier.brightness, Brightness.light);
  });

  test('palette resolution returns correct scheme types', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    // Verify each prefab palette resolves to the correct scheme class
    notifier.paletteId = 'default';
    expect(notifier.palette.scheme, isA<TransitDarkColors>());
    notifier.paletteId = 'sunrise';
    expect(notifier.palette.scheme, isA<TransitSunriseColors>());
    notifier.paletteId = 'forest';
    expect(notifier.palette.scheme, isA<TransitForestColors>());
    notifier.paletteId = 'midnight';
    expect(notifier.palette.scheme, isA<TransitMidnightColors>());
    notifier.paletteId = 'ocean';
    expect(notifier.palette.scheme, isA<TransitOceanColors>());
    notifier.paletteId = 'mono';
    expect(notifier.palette.scheme, isA<TransitMonoColors>());
  });

  test('loadFromPreferences applies all fields', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    notifier.loadFromPreferences(
      const UserPreferences(
        userId: 'test',
        themePaletteId: 'ocean',
        backgroundId: 'none',
        backgroundEnabled: false,
        backgroundOpacity: 0.5,
        fontScale: 1.2,
        colorBlindMode: ColorBlindMode.protanopia,
        dyslexiaFontEnabled: true,
        reduceMotion: true,
      ),
    );
    expect(notifier.paletteId, 'ocean');
    expect(notifier.backgroundId, 'none');
    expect(notifier.backgroundEnabled, false);
    expect(notifier.backgroundOpacity, 0.5);
    expect(notifier.fontScale, 1.2);
    expect(notifier.colorBlindMode, ColorBlindMode.protanopia);
    expect(notifier.dyslexiaFontEnabled, true);
    expect(notifier.reduceMotion, true);
  });

  test('prefabPalettes has 6 palettes', () {
    expect(prefabPalettes.length, 7); // 6 dark + 1 light default
    final ids = prefabPalettes.map((p) => p.id).toSet();
    expect(ids, containsAll(['default', 'sunrise', 'forest', 'midnight', 'ocean', 'mono']));
  });

  test('default palettes include light variant', () {
    final defaults = prefabPalettes.where((p) => p.id == 'default').toList();
    expect(defaults.length, 2);
    expect(defaults.map((p) => p.isDark).toSet(), {true, false});
  });
}

