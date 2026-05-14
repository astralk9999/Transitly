import 'package:flutter/material.dart';

import 'transit_colors.dart';
import 'transit_spacing.dart';

class HighContrastTheme {
  HighContrastTheme._();

  static ThemeData apply(ThemeData base, TransitColorScheme scheme) {
    return base.copyWith(
      scaffoldBackgroundColor: scheme.bgRoot,

      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          side: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: scheme.accent,
            width: TransitSpacing.strokeStrong,
          ),
        ),
      ),

      dividerTheme: base.dividerTheme.copyWith(
        thickness: TransitSpacing.strokeAccent,
      ),

      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusLg),
          side: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusSm),
          side: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),

      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TransitSpacing.radiusLg),
          ),
          side: BorderSide(
            color: scheme.border,
            width: TransitSpacing.strokeAccent,
          ),
        ),
      ),
    );
  }
}
