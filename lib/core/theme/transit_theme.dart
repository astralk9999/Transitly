import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transit_colors.dart';
import 'transit_spacing.dart';

abstract final class TransitTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TransitColors.background,
      colorScheme: const ColorScheme.dark(
        primary: TransitColors.signalGreen,
        onPrimary: TransitColors.textOnGreen,
        surface: TransitColors.surface,
        onSurface: TransitColors.textPrimary,
        error: TransitColors.error,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TransitColors.background,
        foregroundColor: TransitColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: TransitColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TransitSpacing.radiusMd),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TransitColors.divider,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TransitColors.surface,
        selectedItemColor: TransitColors.signalGreen,
        unselectedItemColor: TransitColors.textTertiary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TransitColors.surface,
        contentTextStyle: GoogleFonts.dmSans(
          color: TransitColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
