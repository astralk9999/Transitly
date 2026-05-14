import 'package:flutter/material.dart';

import '../transit_colors.dart';

class TransitCustomColors implements TransitColorScheme {
  const TransitCustomColors({
    required this.primary,
    required this.secondary,
    required Color bgRoot,
    required Color bgSurface,
    required Color textHi,
  })  : _bgRoot = bgRoot,
        _bgSurface = bgSurface,
        _textHi = textHi;

  final Color primary;
  final Color secondary;
  final Color _bgRoot;
  final Color _bgSurface;
  final Color _textHi;

  static Color _blend(Color base, Color overlay, double opacity) =>
      Color.alphaBlend(overlay.withValues(alpha: opacity), base);

  // ── Backgrounds ──────────────────────────────────────────

  @override
  Color get bgRoot => _bgRoot;

  @override
  Color get bgSidebar => _bgRoot;

  @override
  Color get bgSurface => _bgSurface;

  @override
  Color get bgRaised => _blend(_bgSurface, Colors.white, 0.06);

  @override
  Color get bgInput => _blend(_bgRoot, Colors.white, 0.03);

  @override
  Color get bgElevated => bgRaised;

  // ── Borders ──────────────────────────────────────────────

  @override
  Color get border => _blend(_bgSurface, Colors.white, 0.10);

  @override
  Color get borderFocus => _blend(_bgSurface, Colors.white, 0.22);

  @override
  Color get divider => _blend(_bgRoot, Colors.white, 0.06);

  // ── Accent ───────────────────────────────────────────────

  @override
  Color get accent => primary;

  @override
  Color get accentBg => _blend(_bgRoot, primary, 0.10);

  @override
  Color get accentMuted => primary.withValues(alpha: 0.20);

  // ── Neon ─────────────────────────────────────────────────

  @override
  Color get neonCyan => secondary;

  @override
  Color get neonMagenta => _shiftHue(secondary, 60);

  @override
  Color get neonPurple => secondary;

  @override
  Color get neonBlue => _shiftHue(secondary, -40);

  static Color _shiftHue(Color c, double degrees) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }

  // ── Gradients ────────────────────────────────────────────

  @override
  LinearGradient get gradientAccent => LinearGradient(
        colors: [primary, _lighter(primary, 0.20)],
      );

  @override
  LinearGradient get gradientNeon => LinearGradient(
        colors: [secondary, neonMagenta],
      );

  @override
  LinearGradient get gradientWarm => LinearGradient(
        colors: [neonMagenta, _shiftHue(neonMagenta, 40)],
      );

  @override
  LinearGradient get gradientCard => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.10),
          secondary.withValues(alpha: 0.05),
        ],
      );

  static Color _lighter(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  // ── State ────────────────────────────────────────────────

  @override
  Color get stateOnRoute => const Color(0xFF00A0FF);

  @override
  Color get stateOnTime => const Color(0xFFB0FF00);

  @override
  Color get stateDelay => const Color(0xFFFF8C00);

  @override
  Color get stateCancelled => const Color(0xFFFF3B3B);

  @override
  Color get stateIdle => border;

  // ── Text ─────────────────────────────────────────────────

  @override
  Color get textHi => _textHi;

  @override
  Color get textMid => _blend(_bgSurface, _textHi, 0.54);

  @override
  Color get textLo => _blend(_bgSurface, _textHi, 0.30);

  @override
  Color get textDisabled => _blend(_bgSurface, _textHi, 0.16);

  // ── Glass ────────────────────────────────────────────────

  @override
  Color get glassBg => const Color(0x22FFFFFF);

  @override
  Color get glassBorder => const Color(0x2DFFFFFF);
}
