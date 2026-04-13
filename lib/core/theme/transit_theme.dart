import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transit_colors.dart';
import 'transit_spacing.dart';

ThemeData buildTransitTheme(bool isDark) {
  final c = TransitColorScheme.of(isDark);
  final brightness = isDark ? Brightness.dark : Brightness.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bgRoot,
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.bgRaised,

    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFFFFFF),
      secondary: c.accent,
      onSecondary: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFFFFFF),
      error: c.stateCancelled,
      onError: const Color(0xFFFFFFFF),
      surface: c.bgSurface,
      onSurface: c.textHi,
      outline: c.border,
      outlineVariant: c.borderFocus,
      surfaceContainerHighest: c.bgRaised,
    ),

    textTheme: GoogleFonts.dmSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(
      bodyColor: c.textHi,
      displayColor: c.textHi,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: c.bgRoot,
      foregroundColor: c.textHi,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: c.bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusMd),
        side: BorderSide(color: c.border, width: TransitSpacing.strokeThin),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgInput,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TransitSpacing.space12,
        vertical: TransitSpacing.space10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusMd),
        borderSide: BorderSide(color: c.border, width: TransitSpacing.strokeThin),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusMd),
        borderSide: BorderSide(color: c.border, width: TransitSpacing.strokeThin),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusMd),
        borderSide: BorderSide(color: c.accent, width: TransitSpacing.strokeNormal),
      ),
      hintStyle: TextStyle(color: c.textLo),
    ),

    dividerTheme: DividerThemeData(
      color: c.border,
      thickness: TransitSpacing.strokeThin,
      space: 0,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.bgSurface,
      selectedItemColor: c.accent,
      unselectedItemColor: c.textLo,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bgSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TransitSpacing.radiusLg),
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: c.bgSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusLg),
        side: BorderSide(color: c.border, width: TransitSpacing.strokeThin),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.bgRaised,
      contentTextStyle: GoogleFonts.dmSans(color: c.textHi, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );
}
