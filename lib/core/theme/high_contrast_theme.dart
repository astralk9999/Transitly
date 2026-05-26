import 'package:flutter/material.dart';

import 'transit_colors.dart';
import 'transit_spacing.dart';

class HighContrastTheme {
  HighContrastTheme._();

  static ThemeData apply(ThemeData base, TransitColorScheme scheme) {
    final isDark = base.colorScheme.brightness == Brightness.dark;
    final solidScheme = TransitColorScheme.of(isDark);

    return base.copyWith(
      scaffoldBackgroundColor: solidScheme.bgRoot,
      splashFactory: NoSplash.splashFactory,
      highlightColor: solidScheme.bgRoot,

      colorScheme: base.colorScheme.copyWith(
        surface: solidScheme.bgSurface,
        surfaceContainerHighest: solidScheme.bgRoot,
      ),

      cardTheme: base.cardTheme.copyWith(
        color: solidScheme.bgRoot,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          side: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: solidScheme.bgSurface,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: solidScheme.accent,
            width: TransitSpacing.strokeStrong,
          ),
        ),
      ),

      dividerTheme: base.dividerTheme.copyWith(
        color: solidScheme.border,
        thickness: TransitSpacing.strokeAccent,
      ),

      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: solidScheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusLg),
          side: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: solidScheme.bgSurface,
        contentTextStyle: base.snackBarTheme.contentTextStyle?.copyWith(
          color: solidScheme.textHi,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusSm),
          side: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: solidScheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TransitSpacing.radiusLg),
          ),
          side: BorderSide(
            color: solidScheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: solidScheme.bgSurface,
      ),

      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: solidScheme.bgRoot,
        foregroundColor: solidScheme.textHi,
      ),
    );
  }
}
