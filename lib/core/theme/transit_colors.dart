import 'package:flutter/material.dart';

abstract class TransitColorScheme {
  // Backgrounds
  Color get bgRoot;
  Color get bgSidebar;
  Color get bgSurface;
  Color get bgRaised;
  Color get bgInput;
  Color get bgElevated;

  // Borders
  Color get border;
  Color get borderFocus;
  Color get divider;

  // Accent
  Color get accent;
  Color get accentBg;
  Color get accentMuted;

  // State
  Color get stateOnRoute;
  Color get stateOnTime;
  Color get stateDelay;
  Color get stateCancelled;
  Color get stateIdle;

  // Text
  Color get textHi;
  Color get textMid;
  Color get textLo;
  Color get textDisabled;

  factory TransitColorScheme.of(bool isDark) =>
      isDark ? const TransitDarkColors() : const TransitLightColors();
}

class TransitDarkColors implements TransitColorScheme {
  const TransitDarkColors();

  @override Color get bgRoot => const Color(0xFF0C0C0B);
  @override Color get bgSidebar => const Color(0xFF0A0A09);
  @override Color get bgSurface => const Color(0xFF141413);
  @override Color get bgRaised => const Color(0xFF1A1A18);
  @override Color get bgInput => const Color(0xFF141413);
  @override Color get bgElevated => const Color(0xFF1E1E1C);

  @override Color get border => const Color(0xFF252523);
  @override Color get borderFocus => const Color(0xFF3A3A38);
  @override Color get divider => const Color(0xFF1F1F1E);

  @override Color get accent => const Color(0xFF00C896);
  @override Color get accentBg => const Color(0xFF001E15);
  @override Color get accentMuted => const Color(0x3300C896);

  @override Color get stateOnRoute => const Color(0xFF00A0FF);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFF8C00);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF3A3A38);

  @override Color get textHi => const Color(0xFFF0F0EE);
  @override Color get textMid => const Color(0xFF7A7A78);
  @override Color get textLo => const Color(0xFF3A3A38);
  @override Color get textDisabled => const Color(0xFF2A2A28);
}

class TransitLightColors implements TransitColorScheme {
  const TransitLightColors();

  @override Color get bgRoot => const Color(0xFFF9F9F7);
  @override Color get bgSidebar => const Color(0xFFF5F4F0);
  @override Color get bgSurface => const Color(0xFFFFFFFE);
  @override Color get bgRaised => const Color(0xFFF0EFEB);
  @override Color get bgInput => const Color(0xFFFFFFFE);
  @override Color get bgElevated => const Color(0xFFFFFFFE);

  @override Color get border => const Color(0xFFD0D0C8);
  @override Color get borderFocus => const Color(0xFFC0C0B8);
  @override Color get divider => const Color(0xFFE8E8E4);

  @override Color get accent => const Color(0xFF00A87A);
  @override Color get accentBg => const Color(0xFFE6F9F3);
  @override Color get accentMuted => const Color(0x3300A87A);

  @override Color get stateOnRoute => const Color(0xFF0088DD);
  @override Color get stateOnTime => const Color(0xFF6DAA00);
  @override Color get stateDelay => const Color(0xFFD97700);
  @override Color get stateCancelled => const Color(0xFFDD2B2B);
  @override Color get stateIdle => const Color(0xFF888880);

  @override Color get textHi => const Color(0xFF111110);
  @override Color get textMid => const Color(0xFF555550);
  @override Color get textLo => const Color(0xFF888880);
  @override Color get textDisabled => const Color(0xFFBBBBB4);
}
