import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/high_contrast_scheme.dart';
import '../../core/theme/transit_colors.dart';
import 'theme_notifier.dart';
import 'theme_provider.dart';

ProviderContainer? _appContainer;

void registerAppContainer(ProviderContainer c) {
  _appContainer = c;
}

ProviderContainer? get globalAppContainer => _appContainer;

final activePaletteSchemeProvider = Provider<TransitColorScheme>((ref) {
  final notifier = ref.watch(themeNotifierProvider);
  final themeMode = ref.watch(themeModeProvider);
  final brightness = _resolveBrightness(themeMode);
  final palette = notifier.palette;

  TransitColorScheme scheme;
  if (brightness == Brightness.dark) {
    scheme = palette.darkScheme ?? const TransitDarkColors();
  } else {
    scheme = palette.lightScheme ?? const TransitLightColors();
  }

  if (notifier.highContrast) {
    scheme = HighContrastSchemeWrapper(scheme);
  }

  return scheme;
});

Brightness _resolveBrightness(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.system:
      final platform = WidgetsBinding.instance.platformDispatcher;
      return platform.platformBrightness;
  }
}

TransitColorScheme resolveActiveScheme(bool isDark) {
  final container = _appContainer;
  if (container == null) {
    return isDark ? const TransitDarkColors() : const TransitLightColors();
  }
  try {
    final notifier = container.read(themeNotifierProvider);
    final palette = notifier.palette;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    TransitColorScheme scheme;
    if (brightness == Brightness.dark) {
      scheme = palette.darkScheme ?? const TransitDarkColors();
    } else {
      scheme = palette.lightScheme ?? const TransitLightColors();
    }

    if (notifier.highContrast) {
      scheme = HighContrastSchemeWrapper(scheme);
    }

    return scheme;
  } catch (_) {
    return isDark ? const TransitDarkColors() : const TransitLightColors();
  }
}

bool isDyslexiaEnabled() {
  final container = _appContainer;
  if (container == null) return false;
  try {
    return container.read(themeNotifierProvider).dyslexiaFontEnabled;
  } catch (_) {
    return false;
  }
}
