import 'package:flutter/animation.dart';

abstract final class TransitAnimations {
  // ── Durations ───────────────────────────────────────────
  static const Duration flash = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration feedback = Duration(milliseconds: 800);

  // ── Curves (functional only — no bounce, no elastic) ───
  static const Curve primary = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}
