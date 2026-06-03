import 'package:flutter/material.dart';

import '../../shared/providers/active_palette_provider.dart';

abstract final class TransitTypography {
  static String _activeFontFamily({bool monospace = false}) {
    // OpenDyslexic: fuente clasica para dislexia con peso inferior pesado.
    // Si por cualquier razon no carga, fontFamilyFallback lo sustituye por
    // Atkinson Hyperlegible (tambien para a11y) o DM Sans/IBM Plex Mono.
    if (isDyslexiaEnabled()) return 'OpenDyslexic';
    return monospace ? 'IBM Plex Mono' : 'DM Sans';
  }

  // Familias de respaldo si la principal falla al cargar. Asegura que
  // activar dislexia produce SIEMPRE un cambio visible (al menos a
  // Atkinson Hyperlegible, que ya esta empaquetada).
  static List<String>? _fallback() {
    if (isDyslexiaEnabled()) {
      return const ['Atkinson Hyperlegible', 'DM Sans'];
    }
    return null;
  }

  // ── Data / times / numbers (default: IBM Plex Mono) ──────

  static TextStyle displayTime(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c,
      );

  static TextStyle displayNumber(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle routeCode(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02 * 18,
        color: c,
      );

  static TextStyle routeCodeSmall(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: c,
      );

  static TextStyle statusBadge(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10 * 10,
        color: c,
      );

  static TextStyle stopTime(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 14,
        color: c,
      );

  static TextStyle sectionTitle(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
        color: c,
      );

  static TextStyle sectionLabel(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: c,
      );

  static TextStyle inboxTypeTag(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle timeEstimate(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c,
      );

  static TextStyle badgeNumber(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: c,
      );

  static TextStyle errorText(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 13,
        color: c,
      );

  static TextStyle tabLabel(Color c) => TextStyle(
        fontFamily: _activeFontFamily(monospace: true),
        fontFamilyFallback: _fallback(),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle routeName(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c,
      );

  // ── UI text (default: DM Sans / Atkinson Hyperlegible) ────

  static TextStyle navLabel(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.08 * 11,
        color: c,
      );

  static TextStyle bodyPrimary(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.5,
        color: c,
      );

  static TextStyle bodySecondary(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle bodySmall(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle heading(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: c,
      );

  /// Saludo destacado del home ("👋 Buenos días, Itziar"). Más grande
  /// que `heading` para que cumpla rol de contenido principal sin
  /// competir con el título "TRANSITLY" en mono.
  static TextStyle greeting(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: c,
      );

  static TextStyle subheading(Color c) => TextStyle(
        fontFamily: _activeFontFamily(),
        fontFamilyFallback: _fallback(),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c,
      );
}
