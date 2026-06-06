import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/route_model.dart';
import 'glass_card.dart';

/// Banner flotante que aparece arriba del mapa cuando el usuario
/// selecciona una línea (tap sobre una polyline).
///
/// Diseño: glass-card horizontal con badge cuadrado (código + color
/// de la línea) a la izquierda + nombre a la derecha. Aparece con un
/// AnimatedSwitcher que combina fade + slide desde arriba.
///
/// Reemplaza el SnackBar anterior — el SnackBar quedaba abajo, encima
/// del desplegable de líneas, tapándolo y sin transmitir la identidad
/// de la línea (color + código).
class RouteSelectionBanner extends StatelessWidget {
  const RouteSelectionBanner({
    super.key,
    required this.route,
    this.onClose,
  });

  /// `null` = banner oculto.
  final RouteModel? route;

  /// Callback opcional para el botón de cerrar.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: route == null
            ? const SizedBox.shrink(key: ValueKey('hidden'))
            : Padding(
                key: ValueKey('banner-${route!.id}'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GlassCard(
                  blur: 16,
                  fillOpacity: 0.08,
                  borderRadius: 14,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    children: [
                      // Badge cuadrado con código + color de la línea.
                      Container(
                        constraints:
                            const BoxConstraints(minWidth: 52, maxWidth: 72),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: route!.routeColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: route!.routeColor.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              route!.code,
                              style: TransitTypography.routeCode(
                                  route!.routeColor),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nombre de la línea.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              route!.name.toUpperCase(),
                              style: TransitTypography.routeName(c.textHi),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Línea seleccionada · toca para deseleccionar',
                              style: TransitTypography.bodySmall(c.textLo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Botón cerrar.
                      if (onClose != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onClose,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Icon(Icons.close,
                                  size: 18, color: c.textMid),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
