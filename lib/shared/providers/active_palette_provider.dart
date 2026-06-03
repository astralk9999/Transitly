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
    scheme = palette.lightScheme ?? _deriveLightFromDark(palette.darkScheme);
  }

  if (notifier.highContrast) {
    scheme = HighContrastSchemeWrapper(scheme, brightness == Brightness.dark,
        preserveAccent: notifier.hcPreserveAccent);
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
      scheme = palette.lightScheme ?? _deriveLightFromDark(palette.darkScheme);
    }

    if (notifier.highContrast) {
      scheme = HighContrastSchemeWrapper(scheme, isDark,
          preserveAccent: notifier.hcPreserveAccent);
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

TransitColorScheme _deriveLightFromDark(TransitColorScheme? dark) {
  if (dark == null) return const TransitLightColors();
  return _DerivedLightScheme(dark);
}

class _DerivedLightScheme implements TransitColorScheme {
  _DerivedLightScheme(this._dark);
  final TransitColorScheme _dark;

  Color _invert(Color c) {
    final hsl = HSLColor.fromColor(c);
    final newL = 0.95 - hsl.lightness;
    return hsl.withLightness(newL.clamp(0.05, 0.95)).toColor();
  }

  @override Color get bgRoot => _invert(_dark.bgRoot);
  @override Color get bgSidebar => _invert(_dark.bgSidebar);
  @override Color get bgSurface => _invert(_dark.bgSurface);
  @override Color get bgRaised => _invert(_dark.bgRaised);
  @override Color get bgInput => _invert(_dark.bgInput);
  @override Color get bgElevated => _invert(_dark.bgElevated);
  @override Color get border => _invert(_dark.border);
  @override Color get borderFocus => _invert(_dark.borderFocus);
  @override Color get divider => _invert(_dark.divider);
  @override Color get accent => _dark.accent;
  @override Color get accentBg => _invert(_dark.accentBg);
  @override Color get accentMuted => _dark.accent.withValues(alpha: 0.3);
  @override Color get neonCyan => _dark.neonCyan;
  @override Color get neonMagenta => _dark.neonMagenta;
  @override Color get neonPurple => _dark.neonPurple;
  @override Color get neonBlue => _dark.neonBlue;
  @override LinearGradient get gradientAccent => _dark.gradientAccent;
  @override LinearGradient get gradientNeon => _dark.gradientNeon;
  @override LinearGradient get gradientWarm => _dark.gradientWarm;
  @override LinearGradient get gradientCard => _dark.gradientCard;
  @override Color get stateOnRoute => _dark.stateOnRoute;
  @override Color get stateOnTime => _dark.stateOnTime;
  @override Color get stateDelay => _dark.stateDelay;
  @override Color get stateCancelled => _dark.stateCancelled;
  @override Color get stateIdle => _dark.stateIdle;
  @override Color get textHi => _invert(_dark.textHi);
  @override Color get textMid => _invert(_dark.textMid);
  @override Color get textLo => _invert(_dark.textLo);
  @override Color get textDisabled => _invert(_dark.textDisabled);
  @override Color get glassBg => _invert(_dark.glassBg);
  @override Color get glassBorder => _invert(_dark.glassBorder);
}
