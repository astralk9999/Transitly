import 'package:flutter/material.dart';

abstract final class TransitSpacing {
  // ── 4pt grid ────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space36 = 36;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // ── Radius (industrial: tight, no decorative curves) ───
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  // ── Divider ─────────────────────────────────────────────
  static const double dividerHeight = 0.5;

  // ── Tap target ─────────────────────────────────────────
  static const double minTapTarget = 48.0;

  // ── Strokes ─────────────────────────────────────────────
  static const double strokeThin = 0.5;
  static const double strokeNormal = 1.0;
  static const double strokeAccent = 2.0;
  static const double strokeStrong = 3.0;

  // ── Fixed heights ───────────────────────────────────────
  static const double heightNavBar = 56;
  static const double heightTabBar = 52;
  static const double heightInput = 44;
  static const double heightBtnPrimary = 48;
  static const double heightBtnSmall = 36;
  static const double heightRouteCard = 80;
  static const double heightStopItem = 60;

  // ── Predefined EdgeInsets ───────────────────────────────
  static const EdgeInsets paddingCard =
      EdgeInsets.symmetric(horizontal: space16, vertical: space12);

  static const EdgeInsets paddingScreen =
      EdgeInsets.symmetric(horizontal: space16, vertical: space16);

  static const EdgeInsets paddingSection =
      EdgeInsets.only(left: space16, right: space16, top: space24, bottom: space8);

  static const EdgeInsets paddingBadge =
      EdgeInsets.symmetric(horizontal: space8, vertical: space4);

  static const EdgeInsets paddingChip =
      EdgeInsets.symmetric(horizontal: space10, vertical: space6);
}
