import 'package:flutter/material.dart';
import 'transit_colors.dart';
import 'transit_spacing.dart';

TextStyle _dmSansStyle({Color? color, double? fontSize}) => TextStyle(
      fontFamily: 'DM Sans',
      color: color,
      fontSize: fontSize ?? 14,
      package: null,
    );

ThemeData buildTransitTheme(
  TransitColorScheme c, {
  double fontScale = 1.0,
  bool dyslexiaFontEnabled = false,
}) {
  final brightness = switch (c) {
    TransitLightColors() => Brightness.light,
    _ => Brightness.dark,
  };

  final baseTextTheme = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;

  final textTheme = dyslexiaFontEnabled
      ? baseTextTheme.apply(
          fontFamily: 'Atkinson Hyperlegible',
          bodyColor: c.textHi,
          displayColor: c.textHi,
          fontSizeFactor: fontScale,
        )
      : baseTextTheme.apply(
          fontFamily: 'DM Sans',
          bodyColor: c.textHi,
          displayColor: c.textHi,
          fontSizeFactor: fontScale,
        );

  final bodyFont = _dmSansStyle;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bgRoot,
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.bgRaised,
    focusColor: c.accentMuted,
    hoverColor: c.accentMuted,

    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.bgRoot,
      secondary: c.accent,
      onSecondary: c.bgRoot,
      error: c.stateCancelled,
      onError: c.bgSurface,
      surface: c.bgSurface,
      onSurface: c.textHi,
      outline: c.border,
      outlineVariant: c.borderFocus,
      surfaceContainerHighest: c.bgRaised,
    ),

    textTheme: textTheme,

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
      contentTextStyle: bodyFont(color: c.textHi, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );
}
