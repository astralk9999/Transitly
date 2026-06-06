import 'package:flutter/material.dart';

import 'transit_spacing.dart';

class HighContrastTheme {
  HighContrastTheme._();

  /// [preserveAccent] = true mantiene el accent de la paleta original
  /// (compromiso entre contraste extremo y branding). Si false, fuerza
  /// amarillo (dark) o azul (light), que son los colores con mejor ratio
  /// sobre fondo negro/blanco respectivamente.
  /// [originalAccent] solo se usa cuando preserveAccent es true.
  static ThemeData apply(
    ThemeData base,
    dynamic scheme, {
    bool preserveAccent = false,
    Color? originalAccent,
  }) {
    final isDark = base.colorScheme.brightness == Brightness.dark;
    final hcText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final hcBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final hcAccent = preserveAccent && originalAccent != null
        ? originalAccent
        : (isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000FF));
    final hcBorder = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return base.copyWith(
      scaffoldBackgroundColor: hcBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: hcBg,

      textTheme: base.textTheme.apply(
        bodyColor: hcText,
        displayColor: hcText,
      ),

      colorScheme: base.colorScheme.copyWith(
        surface: hcBg,
        surfaceContainerHighest: hcBg,
        onSurface: hcText,
        onBackground: hcText,
        primary: hcAccent,
        onPrimary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      ),

      cardTheme: base.cardTheme.copyWith(
        color: hcBg,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          side: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
      ),

      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: hcBg,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusMd),
          borderSide: BorderSide(
            color: hcAccent,
            width: 2.5,
          ),
        ),
      ),

      dividerTheme: base.dividerTheme.copyWith(
        color: hcBorder,
        thickness: 2.0,
      ),

      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: hcBg,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusLg),
          side: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: hcBg,
        contentTextStyle: base.snackBarTheme.contentTextStyle?.copyWith(
          color: hcText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TransitSpacing.radiusSm),
          side: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
      ),

      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: hcBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TransitSpacing.radiusLg),
          ),
          side: BorderSide(
            color: hcBorder,
            width: 2.0,
          ),
        ),
      ),

      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: hcBg,
        selectedItemColor: hcAccent,
        unselectedItemColor: hcText.withValues(alpha: 0.6),
      ),

      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: hcBg,
        foregroundColor: hcText,
      ),
    );
  }
}
