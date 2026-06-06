import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/route_model.dart';
import 'glass_card.dart';

/// Toast flotante arriba de la pantalla cuando se añade/quita una línea
/// de favoritos. Reemplaza el SnackBar simple que aparecía abajo y no
/// reflejaba qué línea era.
///
/// Diseño igual que RouteSelectionBanner: glass-card con badge de
/// color/código + nombre. Anima slide desde arriba + fade, auto-dismiss
/// a los 2.2 s.
void showRouteFavoriteToast(
  BuildContext context, {
  required RouteModel route,
  required bool added,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final entry = _RouteFavoriteToastEntry(route: route, added: added);
  overlay.insert(entry.overlayEntry);

  Timer(const Duration(milliseconds: 2200), entry.dismiss);
}

class _RouteFavoriteToastEntry {
  _RouteFavoriteToastEntry({required this.route, required this.added}) {
    overlayEntry = OverlayEntry(
      builder: (_) => _RouteFavoriteToast(
        route: route,
        added: added,
        onDismiss: dismiss,
      ),
    );
  }

  final RouteModel route;
  final bool added;
  late final OverlayEntry overlayEntry;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    overlayEntry.remove();
  }
}

class _RouteFavoriteToast extends StatefulWidget {
  const _RouteFavoriteToast({
    required this.route,
    required this.added,
    required this.onDismiss,
  });
  final RouteModel route;
  final bool added;
  final VoidCallback onDismiss;

  @override
  State<_RouteFavoriteToast> createState() => _RouteFavoriteToastState();
}

class _RouteFavoriteToastState extends State<_RouteFavoriteToast>
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: GlassCard(
                    blur: 16,
                    fillOpacity: 0.08,
                    borderRadius: 14,
                    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                    child: Row(
                      children: [
                        // Badge cuadrado con código + color de línea.
                        Container(
                          constraints: const BoxConstraints(
                              minWidth: 52, maxWidth: 72),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.route.routeColor
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.route.routeColor
                                  .withValues(alpha: 0.65),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.route.code,
                                style: TransitTypography.routeCode(
                                    widget.route.routeColor),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.route.name.toUpperCase(),
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
