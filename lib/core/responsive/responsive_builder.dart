import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Sub P2.5-01: builder helper que devuelve un widget distinto según
/// el breakpoint actual.
///
/// Uso:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (_) => MobileLayout(),
///   tablet: (_) => TabletLayout(),
///   desktop: (_) => DesktopLayout(),
/// )
/// ```
///
/// `tablet` y `desktop` son opcionales: si faltan se cae al inmediato
/// inferior. `mobile` es obligatorio (fallback universal).
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return (desktop ?? tablet ?? mobile)(context);
    }
    if (Breakpoints.isTablet(context)) {
      return (tablet ?? mobile)(context);
    }
    return mobile(context);
  }
}

/// Sub P2.5-03: wrapper que centra el body con max-width en desktop.
/// En mobile y tablet portrait no introduce ningún constraint.
class ResponsivePageWrapper extends StatelessWidget {
  const ResponsivePageWrapper({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
