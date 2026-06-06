import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/providers/search_selection_provider.dart';

/// Sub B1.1: marcador "Google Maps style" para la selección activa del
/// buscador. Pin grande con sombra, animado, opcionalmente con tarjeta
/// flotante con el título encima.
class SearchPinLayer extends StatelessWidget {
  const SearchPinLayer({
    super.key,
    required this.selection,
    required this.isDark,
    required this.onClose,
    required this.onOpenDetail,
  });

  final SearchSelection selection;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);
    final color = selection.color ?? c.accent;
    final hasDetail = selection.pushPath != null;

    // Stack con Positioned absoluto: el pin queda anclado al bottom
    // del marker (= LatLng) y la tarjeta a 52px exactos por encima.
    // Antes era Column con MainAxisAlignment.end y el rendering tenía
    // jitter durante zoom in/out (el contenido no llenaba el marker y
    // flutter_map redondea las posiciones de forma inconsistente).
    const pinHeight = 50.0;
    const gap = 2.0;
    return MarkerLayer(
      markers: [
        Marker(
          point: selection.position,
          width: 280,
          height: 180,
          alignment: Alignment.bottomCenter,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Pin pegado al bottom: su punta coincide con el LatLng.
              Positioned(
                bottom: 0,
                child: _AnimatedPin(
                    color: color, icon: selection.icon),
              ),
              // Tarjeta a distancia fija (pinHeight + gap) sobre el LatLng.
              Positioned(
                bottom: pinHeight + gap,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IntrinsicWidth(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: hasDetail ? onOpenDetail : null,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selection.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.textHi,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (selection.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    selection.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.textMid,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                                if (hasDetail) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver detalles',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_forward,
                                          color: color, size: 12),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Botón cerrar (X).
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                size: 16, color: c.textMid),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pin tipo Google Maps con animación de "drop" y sombra elíptica.
class _AnimatedPin extends StatefulWidget {
  const _AnimatedPin({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  State<_AnimatedPin> createState() => _AnimatedPinState();
}

class _AnimatedPinState extends State<_AnimatedPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _drop;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _drop = Tween<double>(begin: -24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _drop.value),
          child: Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: _scale.value,
            child: SizedBox(
              width: 38,
              height: 50,
              child: CustomPaint(
                painter: _PinPainter(color: widget.color),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(widget.icon,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Sombra elíptica bajo el pin.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 2),
        width: size.width * 0.7,
        height: 6,
      ),
      shadow,
    );

    // Forma del pin: círculo arriba con cola triangular abajo.
    final path = ui.Path();
    final radius = size.width / 2 - 2;
    final cx = size.width / 2;
    final cy = radius + 1;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    // Triángulo apuntando abajo.
    path.moveTo(cx - radius * 0.55, cy + radius * 0.85);
    path.lineTo(cx, size.height - 2);
    path.lineTo(cx + radius * 0.55, cy + radius * 0.85);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}
