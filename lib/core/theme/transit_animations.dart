import 'package:flutter/widgets.dart';

abstract final class TransitAnimations {
  // ── Durations ───────────────────────────────────────────
  static const Duration flash = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration feedback = Duration(milliseconds: 800);

  // ── Durations by element type ───────────────────────────
  static const Duration durationButton = Duration(milliseconds: 120);
  static const Duration durationCard = Duration(milliseconds: 180);
  static const Duration durationTooltip = Duration(milliseconds: 150);
  static const Duration durationDropdown = Duration(milliseconds: 200);
  static const Duration durationModal = Duration(milliseconds: 300);

  // ── Custom curves (professional, no defaults) ──────────
  static const Curve transitEaseOut = Cubic(0.23, 1, 0.32, 1);
  static const Curve transitEaseInOut = Cubic(0.77, 0, 0.175, 1);

  // ── Legacy curves (kept for backward compat) ───────────
  static const Curve primary = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;

  // ── Accessibility ──────────────────────────────────────
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  static Duration adaptiveDuration(BuildContext context, Duration duration) {
    return shouldAnimate(context) ? duration : Duration.zero;
  }
}
