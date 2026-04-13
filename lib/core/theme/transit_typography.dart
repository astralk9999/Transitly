import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class TransitTypography {
  // ── Data / times / numbers (IBM Plex Mono) ──────────────

  static TextStyle displayTime(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c,
      );

  static TextStyle displayNumber(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle routeCode(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02 * 18,
        color: c,
      );

  static TextStyle routeCodeSmall(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: c,
      );

  static TextStyle statusBadge(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10 * 10,
        color: c,
      );

  static TextStyle stopTime(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 14,
        color: c,
      );

  static TextStyle sectionTitle(Color c) => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
        color: c,
      );

  // ── UI text (DM Sans) ──────────────────────────────────

  static TextStyle navLabel(Color c) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.08 * 11,
        color: c,
      );

  static TextStyle bodyPrimary(Color c) => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.5,
        color: c,
      );

  static TextStyle bodySecondary(Color c) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle bodySmall(Color c) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle heading(Color c) => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: c,
      );

  static TextStyle subheading(Color c) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c,
      );
}
