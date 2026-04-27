import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

/// Resuelve el brillo efectivo del tema combinando [themeModeProvider] y
/// [MediaQuery.platformBrightnessOf] (necesario para `ThemeMode.system`).
///
/// Preferir este helper a duplicar la lógica
/// `mode == ThemeMode.dark || (mode == ThemeMode.system && platform == dark)`
/// en cada pantalla.
bool isDarkMode(WidgetRef ref, BuildContext context) {
  final mode = ref.watch(themeModeProvider);
  return switch (mode) {
    ThemeMode.light => false,
    ThemeMode.dark => true,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };
}
