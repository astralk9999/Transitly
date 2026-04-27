import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/providers/theme_provider.dart';

void main() {
  test('themeModeProvider defaults to dark', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('themeModeProvider can be toggled light/dark', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    expect(container.read(themeModeProvider), ThemeMode.light);

    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}
