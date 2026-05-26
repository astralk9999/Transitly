import 'package:flutter/material.dart';

import 'transit_colors.dart';

class HighContrastSchemeWrapper implements TransitColorScheme {
  HighContrastSchemeWrapper(this._base);

  final TransitColorScheme _base;

  @override Color get bgRoot => _base.bgRoot;
  @override Color get bgSidebar => _base.bgSidebar;
  @override Color get bgSurface => _base.bgSurface;
  @override Color get bgRaised => _base.bgRaised;
  @override Color get bgInput => _base.bgInput;
  @override Color get bgElevated => _base.bgElevated;

  @override
  Color get border => const Color(0xFFFFFFFF);

  @override
  Color get borderFocus => const Color(0xFFFFFFFF);

  @override Color get divider => const Color(0xFFFFFFFF);

  @override Color get accent => _base.accent;

  @override Color get accentBg => _base.accentBg;

  @override Color get accentMuted => _base.accent.withValues(alpha: 0.3);

  @override Color get neonCyan => _base.neonCyan;
  @override Color get neonMagenta => _base.neonMagenta;
  @override Color get neonPurple => _base.neonPurple;
  @override Color get neonBlue => _base.neonBlue;

  @override LinearGradient get gradientAccent => _base.gradientAccent;
  @override LinearGradient get gradientNeon => _base.gradientNeon;
  @override LinearGradient get gradientWarm => _base.gradientWarm;
  @override LinearGradient get gradientCard => _base.gradientCard;

  @override Color get stateOnRoute => _base.stateOnRoute;
  @override Color get stateOnTime => _base.stateOnTime;
  @override Color get stateDelay => _base.stateDelay;
  @override Color get stateCancelled => _base.stateCancelled;
  @override Color get stateIdle => _base.stateIdle;

  @override
  Color get textHi => const Color(0xFFFFFFFF);

  @override
  Color get textMid => const Color(0xFFEEEEEE);

  @override
  Color get textLo => const Color(0xFFCCCCCC);

  @override
  Color get textDisabled => const Color(0xFF888888);

  @override
  Color get glassBg => const Color(0x44FFFFFF);

  @override
  Color get glassBorder => const Color(0x66FFFFFF);
}
