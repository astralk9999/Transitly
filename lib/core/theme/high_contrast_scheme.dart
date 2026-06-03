import 'package:flutter/material.dart';

import 'transit_colors.dart';

class HighContrastSchemeWrapper implements TransitColorScheme {
  HighContrastSchemeWrapper(this._base, this._isDark, {bool preserveAccent = false})
      : _preserveAccent = preserveAccent;

  final TransitColorScheme _base;
  final bool _isDark;
  final bool _preserveAccent;

  @override Color get bgRoot => _isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  @override Color get bgSidebar => _isDark ? const Color(0xFF050505) : const Color(0xFFF5F5F5);
  @override Color get bgSurface => _isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA);
  @override Color get bgRaised => _isDark ? const Color(0xFF111111) : const Color(0xFFEEEEEE);
  @override Color get bgInput => _isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF8F8F8);
  @override Color get bgElevated => _isDark ? const Color(0xFF141414) : const Color(0xFFF0F0F0);

  @override
  Color get border => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  @override
  Color get borderFocus => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  @override Color get divider => _isDark ? const Color(0x44FFFFFF) : const Color(0x44000000);

  @override
  Color get accent => _preserveAccent
      ? _base.accent
      : (_isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000FF));

  @override
  Color get accentBg => _preserveAccent
      ? _base.accent.withValues(alpha: 0.15)
      : (_isDark ? const Color(0x22FFFF00) : const Color(0x220000FF));

  @override
  Color get accentMuted => _preserveAccent
      ? _base.accent.withValues(alpha: 0.30)
      : (_isDark ? const Color(0x44FFFF00) : const Color(0x440000FF));

  @override Color get neonCyan => _isDark ? const Color(0xFF00FFFF) : const Color(0xFF0055AA);
  @override Color get neonMagenta => _isDark ? const Color(0xFFFF00FF) : const Color(0xFFAA0055);
  @override Color get neonPurple => _isDark ? const Color(0xFF8888FF) : const Color(0xFF5500FF);
  @override Color get neonBlue => _isDark ? const Color(0xFF4488FF) : const Color(0xFF0033CC);

  @override LinearGradient get gradientAccent => _base.gradientAccent;
  @override LinearGradient get gradientNeon => LinearGradient(colors: [neonPurple, neonMagenta]);
  @override LinearGradient get gradientWarm => LinearGradient(colors: [neonMagenta, neonCyan]);
  @override LinearGradient get gradientCard => const LinearGradient(colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)]);

  @override Color get stateOnRoute => _isDark ? const Color(0xFF00FF00) : const Color(0xFF005500);
  @override Color get stateOnTime => _isDark ? const Color(0xFF88FF00) : const Color(0xFF448800);
  @override Color get stateDelay => _isDark ? const Color(0xFFFF8800) : const Color(0xFF884400);
  @override Color get stateCancelled => _isDark ? const Color(0xFFFF0000) : const Color(0xFFAA0000);
  @override Color get stateIdle => _isDark ? const Color(0xFF444444) : const Color(0xFF888888);

  @override Color get textHi => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  @override Color get textMid => _isDark ? const Color(0xFFCCCCCC) : const Color(0xFF222222);
  @override Color get textLo => _isDark ? const Color(0xFF888888) : const Color(0xFF444444);
  @override Color get textDisabled => _isDark ? const Color(0xFF444444) : const Color(0xFFAAAAAA);

  @override Color get glassBg => _isDark ? const Color(0x44FFFFFF) : const Color(0x44000000);
  @override Color get glassBorder => _isDark ? const Color(0x66FFFFFF) : const Color(0x66000000);
}
