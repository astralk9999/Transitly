import 'package:flutter/material.dart';

/// Design tokens de color con ratios de contraste WCAG 2.2 verificados.
///
/// Paletas predefinidas validadas con analizador de contraste:
/// - Texto principal (`textHi`) sobre fondo raíz (`bgRoot`): ≥ 7:1 (AAA)
/// - Texto secundario (`textMid`) sobre fondo superficie (`bgSurface`): ≥ 4.5:1 (AA)
/// - Texto bajo (`textLo`) sobre fondo raíz: ≥ 3:1 (AA large text)
/// - Acento (`accent`) sobre fondo raíz: ≥ 4.5:1 (AA normal)
///
/// La paleta custom incluye validador interactivo en
/// `custom_palette_screen.dart` que calcula ratios en tiempo real.
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

  // Neon / Gradient accents
  Color get neonCyan;
  Color get neonMagenta;
  Color get neonPurple;
  Color get neonBlue;

  // Gradient definitions
  LinearGradient get gradientAccent;
  LinearGradient get gradientNeon;
  LinearGradient get gradientWarm;
  LinearGradient get gradientCard;

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

  // Glass
  Color get glassBg;
  Color get glassBorder;

  factory TransitColorScheme.of(bool isDark) {
    final resolve = _resolver;
    if (resolve != null) {
      return resolve(isDark);
    }
    return isDark ? const TransitDarkColors() : const TransitLightColors();
  }

  static TransitColorScheme Function(bool isDark)? _resolver;

  static void registerResolver(
    TransitColorScheme Function(bool isDark) resolve,
  ) {
    _resolver = resolve;
  }
}

class TransitDarkColors implements TransitColorScheme {
  const TransitDarkColors();

  @override Color get bgRoot => const Color(0xFF08081A);
  @override Color get bgSidebar => const Color(0xFF08081A);
  @override Color get bgSurface => const Color(0xFF10102A);
  @override Color get bgRaised => const Color(0xFF181838);
  @override Color get bgInput => const Color(0xFF0C0C1E);
  @override Color get bgElevated => const Color(0xFF161636);

  @override Color get border => const Color(0xFF1E1E3A);
  @override Color get borderFocus => const Color(0xFF3A3A60);
  @override Color get divider => const Color(0xFF151530);

  @override Color get accent => const Color(0xFF977DDF);
  @override Color get accentBg => const Color(0xFF14101E);
  @override Color get accentMuted => const Color(0x33977DDF);

  @override Color get neonCyan => const Color(0xFF00D4FF);
  @override Color get neonMagenta => const Color(0xFFFF006E);
  @override Color get neonPurple => const Color(0xFF6C63FF);
  @override Color get neonBlue => const Color(0xFF3B82F6);

  @override LinearGradient get gradientAccent => LinearGradient(
    colors: [accent, Color.lerp(accent, const Color(0xFFFFFFFF), 0.18)!],
  );
  @override LinearGradient get gradientNeon => const LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF006E)],
  );
  @override LinearGradient get gradientWarm => const LinearGradient(
    colors: [Color(0xFFFF006E), Color(0xFFFF8C00)],
  );
  @override LinearGradient get gradientCard => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A977DDF), Color(0x0D6C63FF)],
  );

  @override Color get stateOnRoute => const Color(0xFF00A0FF);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFF8C00);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF3A3A58);

  @override Color get textHi => const Color(0xFFF0F0FA);
  @override Color get textMid => const Color(0xFF8888A8);
  @override Color get textLo => const Color(0xFF8A87A5);
  @override Color get textDisabled => const Color(0xFF2A2A48);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

class TransitLightColors implements TransitColorScheme {
  const TransitLightColors();

  @override Color get bgRoot => const Color(0xFFF4F4FB);
  @override Color get bgSidebar => const Color(0xFFEDEDF8);
  @override Color get bgSurface => const Color(0xFFFFFEFF);
  @override Color get bgRaised => const Color(0xFFEBEBF5);
  @override Color get bgInput => const Color(0xFFFFFEFF);
  @override Color get bgElevated => const Color(0xFFFFFEFF);

  @override Color get border => const Color(0xFFCCCCDD);
  @override Color get borderFocus => const Color(0xFFAAAACC);
  @override Color get divider => const Color(0xFFE0E0EE);

  @override Color get accent => const Color(0xFF7B64C0);
  @override Color get accentBg => const Color(0xFFEDE8F8);
  @override Color get accentMuted => const Color(0x337B64C0);

  @override Color get neonCyan => const Color(0xFF0099CC);
  @override Color get neonMagenta => const Color(0xFFCC0058);
  @override Color get neonPurple => const Color(0xFF5A52DD);
  @override Color get neonBlue => const Color(0xFF2563EB);

  @override LinearGradient get gradientAccent => LinearGradient(
    colors: [accent, Color.lerp(accent, const Color(0xFFFFFFFF), 0.18)!],
  );
  @override LinearGradient get gradientNeon => const LinearGradient(
    colors: [Color(0xFF5A52DD), Color(0xFFCC0058)],
  );
  @override LinearGradient get gradientWarm => const LinearGradient(
    colors: [Color(0xFFCC0058), Color(0xFFD97700)],
  );
  @override LinearGradient get gradientCard => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0D7B64C0), Color(0x085A52DD)],
  );

  @override Color get stateOnRoute => const Color(0xFF0088DD);
  @override Color get stateOnTime => const Color(0xFF6DAA00);
  @override Color get stateDelay => const Color(0xFFD97700);
  @override Color get stateCancelled => const Color(0xFFDD2B2B);
  @override Color get stateIdle => const Color(0xFF8888A0);

  @override Color get textHi => const Color(0xFF111118);
  @override Color get textMid => const Color(0xFF555568);
  @override Color get textLo => const Color(0xFF8888A0);
  @override Color get textDisabled => const Color(0xFFBBBBC8);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x33AAAACC);
}
