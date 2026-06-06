import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';

/// Toast flotante arriba de la pantalla cuando se añade/quita una
/// línea o parada de favoritos. Mismo widget para ambas — solo cambia
/// el "leading" (badge de línea vs icono de parada).
///
/// Mantiene la estética de la app (bgSurface opaco + borde de color
/// + sombra), idéntica al RouteSelectionBanner para coherencia.
/// Anima slide desde arriba + fade, auto-dismiss a los 2.2 s.
void showRouteFavoriteToast(
  BuildContext context, {
  required RouteModel route,
  required bool added,
}) {
  _show(
    context,
    title: route.name.toUpperCase(),
    added: added,
    accentColor: route.routeColor,
    leading: _RouteBadge(route: route),
  );
}

void showStopFavoriteToast(
  BuildContext context, {
  required StopModel stop,
  required bool added,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  _show(
    context,
    title: stop.name.toUpperCase(),
    added: added,
    accentColor: c.accent,
    leading: _StopBadge(color: c.accent),
  );
}

void _show(
  BuildContext context, {
  required String title,
  required bool added,
  required Color accentColor,
  required Widget leading,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final entry = _FavoriteToastEntry(
    title: title,
    added: added,
    accentColor: accentColor,
    leading: leading,
  );
  overlay.insert(entry.overlayEntry);
  Timer(const Duration(milliseconds: 2200), entry.dismiss);
}

class _FavoriteToastEntry {
  _FavoriteToastEntry({
    required this.title,
    required this.added,
    required this.accentColor,
    required this.leading,
  }) {
    overlayEntry = OverlayEntry(
      builder: (_) => _FavoriteToast(
        title: title,
        added: added,
        accentColor: accentColor,
        leading: leading,
        onDismiss: dismiss,
      ),
    );
  }

  final String title;
  final bool added;
  final Color accentColor;
  final Widget leading;
  late final OverlayEntry overlayEntry;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    overlayEntry.remove();
  }
}

class _FavoriteToast extends StatefulWidget {
  const _FavoriteToast({
    required this.title,
    required this.added,
    required this.accentColor,
    required this.leading,
    required this.onDismiss,
  });
  final String title;
  final bool added;
  final Color accentColor;
  final Widget leading;
  final VoidCallback onDismiss;

  @override
  State<_FavoriteToast> createState() => _FavoriteToastState();
}

class _FavoriteToastState extends State<_FavoriteToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(_opacity);
    _ctrl.forward();
    // Reverse animation ~200ms before final dismiss.
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _opacity,
            child: Padding(
              // Idéntico al banner de línea seleccionada (B3) para que
              // ambos elementos compartan posición y no choquen con los
              // FABs de búsqueda/filtro.
              padding: const EdgeInsets.fromLTRB(80, 16, 80, 0),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                    child: Row(
                      children: [
                        widget.leading,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: TransitTypography.routeName(c.textHi),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    widget.added
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 14,
                                    color: widget.added
                                        ? Colors.amber
                                        : c.textLo,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.added
                                        ? 'Añadida a favoritas'
                                        : 'Quitada de favoritas',
                                    style:
                                        TransitTypography.bodySmall(c.textLo),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.route});
  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52, maxWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: route.routeColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: route.routeColor.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            route.code,
            style: TransitTypography.routeCode(route.routeColor),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
      child: Icon(Icons.location_on, color: color, size: 22),
    );
  }
}
