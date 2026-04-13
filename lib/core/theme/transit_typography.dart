import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transit_colors.dart';

abstract final class TransitTypography {
  // Data/times font
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = TransitColors.textPrimary,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // UI font
  static TextStyle ui({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = TransitColors.textPrimary,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Predefined styles
  static TextStyle get displayLarge => mono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: TransitColors.signalGreen,
      );

  static TextStyle get headlineMedium => ui(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => ui(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => ui(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => ui(fontSize: 16);

  static TextStyle get bodyMedium => ui(fontSize: 14);

  static TextStyle get bodySmall => ui(
        fontSize: 12,
        color: TransitColors.textSecondary,
      );

  static TextStyle get labelLarge => ui(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelSmall => mono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: TransitColors.textSecondary,
      );

  static TextStyle get scheduleTime => mono(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get lineBadge => mono(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: TransitColors.textOnGreen,
      );
}
