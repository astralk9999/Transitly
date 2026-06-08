import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/route_model.dart';

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
    this.onTap,
    this.isCommunity = false,
    this.onOpenCommunity,
  });

  /// `null` = banner oculto.
  final RouteModel? route;

  /// Callback opcional para el botón de cerrar.
  final VoidCallback? onClose;

  /// Callback opcional al tocar el cuerpo del banner (badge + nombre).
  /// El botón de cerrar mantiene su propio handler independiente.
  final VoidCallback? onTap;

  /// Si la línea seleccionada es de la comunidad (muestra badge + botón).
  final bool isCommunity;

  /// Abre la pantalla de comunidad de esta ruta.
  final VoidCallback? onOpenCommunity;

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
                // Padding top 76 deja libre la fila de FABs (search/
                // filter) que viven en top: 16, height 48. Padding
                // horizontal 80 evita que las esquinas pisen los FABs
                // si la pantalla es estrecha (FAB izq + 16 margen).
                padding: const EdgeInsets.fromLTRB(80, 16, 80, 0),
                child: Container(
                  decoration: BoxDecoration(
                    // bgSurface opaco para legibilidad clara en tema
                    // light (el GlassCard translúcido sobre mapa claro
                    // perdía contraste).
                    color: c.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: route!.routeColor.withValues(alpha: 0.55),
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
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    children: [
                      // Badge + nombre = zona tapable que abre detalle.
                      // El botón cerrar queda fuera para no canibalizar
                      // su propio gesto.
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTap,
                          child: Row(
                            children: [
                              // Badge cuadrado con código + color.
                              Container(
                                constraints: const BoxConstraints(
                                    minWidth: 52, maxWidth: 72),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: route!.routeColor
                                      .withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: route!.routeColor
                                        .withValues(alpha: 0.65),
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
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            route!.name.toUpperCase(),
                                            style: TransitTypography.routeName(
                                                c.textHi),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCommunity) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50)
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text('COMUNIDAD',
                                                style: TransitTypography
                                                        .bodySmall(
                                                            const Color(
                                                                0xFF4CAF50))
                                                    .copyWith(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      onTap != null
                                          ? 'Toca para ver detalles'
                                          : 'Línea seleccionada',
                                      style: TransitTypography.bodySmall(
                                          c.textLo),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón "ir a comunidad" para rutas de comunidad.
                      if (isCommunity && onOpenCommunity != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onOpenCommunity,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Icon(Icons.groups_outlined,
                                  size: 20, color: const Color(0xFF4CAF50)),
                            ),
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

