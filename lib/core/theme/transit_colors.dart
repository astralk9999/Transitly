import 'package:flutter/material.dart';

abstract class TransitColorScheme {
  // Backgrounds
  Color get bgRoot;
  Color get bgSidebar;
  Color get bgSurface;
  Color get bgRaised;
  Color get bgInput;

  // Borders
  Color get border;
  Color get borderFocus;

  // Accent
  Color get accent;
  Color get accentBg;

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

  factory TransitColorScheme.of(bool isDark) =>
      isDark ? const TransitDarkColors() : const TransitLightColors();
}

class TransitDarkColors implements TransitColorScheme {
  const TransitDarkColors();

  @override Color get bgRoot => const Color(0xFF0C0C0C);
  @override Color get bgSidebar => const Color(0xFF0A0A0A);
  @override Color get bgSurface => const Color(0xFF131313);
  @override Color get bgRaised => const Color(0xFF1A1A1A);
  @override Color get bgInput => const Color(0xFF131313);

  @override Color get border => const Color(0xFF252525);
  @override Color get borderFocus => const Color(0xFF3A3A3A);

  @override Color get accent => const Color(0xFF00C896);
  @override Color get accentBg => const Color(0xFF001E15);

  @override Color get stateOnRoute => const Color(0xFF00A0FF);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFF8C00);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF3A3A3A);

  @override Color get textHi => const Color(0xFFF0F0F0);
  @override Color get textMid => const Color(0xFF7A7A7A);
  @override Color get textLo => const Color(0xFF3A3A3A);
}

class TransitLightColors implements TransitColorScheme {
  const TransitLightColors();

  @override Color get bgRoot => const Color(0xFFF9F9F7);
  @override Color get bgSidebar => const Color(0xFFF5F4F0);
  @override Color get bgSurface => const Color(0xFFFFFFFF);
  @override Color get bgRaised => const Color(0xFFF0EFEB);
  @override Color get bgInput => const Color(0xFFFFFFFF);

  @override Color get border => const Color(0xFFE0DFD9);
  @override Color get borderFocus => const Color(0xFFC8C7C1);

  @override Color get accent => const Color(0xFF00A87A);
  @override Color get accentBg => const Color(0xFFE6F9F3);

  @override Color get stateOnRoute => const Color(0xFF00A0FF);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFF8C00);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF3A3A3A);

  @override Color get textHi => const Color(0xFF111111);
  @override Color get textMid => const Color(0xFF666660);
  @override Color get textLo => const Color(0xFFAAAAAA);
}
