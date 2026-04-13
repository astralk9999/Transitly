import 'package:flutter/material.dart';

abstract final class TransitColors {
  // Primary palette
  static const Color signalGreen = Color(0xFF00C896);
  static const Color background = Color(0xFF0C0C0C);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color card = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textOnGreen = Color(0xFF0C0C0C);

  // Semantic
  static const Color error = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF42A5F5);
  static const Color success = Color(0xFF66BB6A);

  // Status
  static const Color onTime = signalGreen;
  static const Color delayed = warning;
  static const Color cancelled = error;

  // Capacity
  static const Color seatsAvailable = signalGreen;
  static const Color halfFull = warning;
  static const Color full = error;

  // Divider
  static const Color divider = Color(0xFF2A2A2A);
  static const Color shimmerBase = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);
}
