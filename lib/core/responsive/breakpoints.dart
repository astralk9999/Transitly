import 'package:flutter/widgets.dart';

/// Sub P2.5-01: sistema de breakpoints para layouts adaptativos.
///
/// Los thresholds están alineados con `ResponsiveScaffold.screenSizeOf`
/// (shared/widgets) pero expuestos con una API más simple isMobile /
/// isTablet / isDesktop para usar en condicionales.
class Breakpoints {
  Breakpoints._();

  /// Límite inferior de tablet (a partir de aquí ya no es móvil portrait).
  static const double mobile = 600;

  /// Límite inferior de desktop / web (a partir de aquí side-nav extendida).
  static const double tablet = 1024;

  /// Límite inferior de desktop ancho.
  static const double desktop = 1440;

  static bool isMobile(BuildContext c) =>
      MediaQuery.sizeOf(c).width < mobile;

  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= tablet;

  static bool isWideDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= desktop;

  /// `true` si el dispositivo está en orientación landscape.
  static bool isLandscape(BuildContext c) =>
      MediaQuery.orientationOf(c) == Orientation.landscape;

  /// Debe usar side navigation rail en lugar de bottom nav.
  /// Móvil landscape, tablet portrait, y cualquier desktop.
  static bool shouldUseSideNav(BuildContext c) {
    if (isDesktop(c)) return true;
    if (isTablet(c)) return true;
    if (isLandscape(c)) return true;
    return false;
  }
}
