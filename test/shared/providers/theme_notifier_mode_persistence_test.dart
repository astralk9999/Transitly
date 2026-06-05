import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../../data/shared_test_repositories.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_themeMode_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    if (await Hive.boxExists('guest_theme_prefs')) {
      await Hive.deleteBoxFromDisk('guest_theme_prefs');
    }
  });

  test('themeMode defaults to system on first launch', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    expect(notifier.themeMode, ThemeMode.system);
  });

  test('themeMode setter persists to guest box', () async {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await notifier.loadGuest();
    notifier.themeMode = ThemeMode.light;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.themeMode, ThemeMode.light);

    final notifier2 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await notifier2.loadGuest();
    expect(notifier2.themeMode, ThemeMode.light);
  });

  test('themeMode dark survives full round-trip', () async {
    final n1 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await n1.loadGuest();
    n1.themeMode = ThemeMode.dark;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final n2 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await n2.loadGuest();
    expect(n2.themeMode, ThemeMode.dark);
  });
}
