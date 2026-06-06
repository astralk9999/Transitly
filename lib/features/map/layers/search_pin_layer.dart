import 'dart:async';
import 'dart:math' show Point;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/providers/search_selection_provider.dart';

/// Sub B1.5: SOLO el pin (38×50) como Marker pequeño con bottomCenter.
/// Marker pequeño = sin drift al hacer zoom porque la proyección del
/// LatLng en píxeles es estable cuando el área del marker es compacta.
/// La tarjeta de info se renderiza por separado vía
/// [SearchSelectionFloatingCard] como overlay del Stack del MapTab.
class SearchPinLayer extends StatelessWidget {
  const SearchPinLayer({
    super.key,
    required this.selection,
    required this.isDark,
  });

  final SearchSelection selection;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);
    final color = selection.color ?? c.accent;
    return MarkerLayer(
      markers: [
        Marker(
          point: selection.position,
          width: 38,
          height: 50,
          // Alignment(0, 1.3) sube el pin ~7.5px respecto a
          // bottomCenter. Pinta la punta del triángulo ligeramente
          // por ENCIMA del LatLng en lugar de coincidir con él. Esto
          // compensa la percepción visual de que el "punto que marca"
          // es el centro del círculo del pin, no el extremo de la
          // cola.
          alignment: const Alignment(0, 1.3),
          child: _AnimatedPin(color: color, icon: selection.icon),
        ),
      ],
    );
  }
}

/// Tarjeta flotante posicionada con `latLngToScreenPoint` para que sea
/// pixel-perfect y estable durante zoom/move. Se reconstruye cada vez
/// que el mapa emite un evento (zoom in/out, pan, rotate).
class SearchSelectionFloatingCard extends StatefulWidget {
  const SearchSelectionFloatingCard({
    super.key,
    required this.selection,
    required this.mapController,
    required this.isDark,
    required this.onClose,
    required this.onOpenDetail,
  });

  final SearchSelection selection;
  final MapController mapController;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;

  @override
  State<SearchSelectionFloatingCard> createState() =>
      _SearchSelectionFloatingCardState();
}

class _SearchSelectionFloatingCardState
    extends State<SearchSelectionFloatingCard> {
  StreamSubscription<MapEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    // Re-rebuild en cada evento del mapa para reposicionar la tarjeta
    // siguiendo al pin durante zoom/pan/rotate.
    _eventSub = widget.mapController.mapEventStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(widget.isDark);
    final color = widget.selection.color ?? c.accent;
    final hasDetail = widget.selection.pushPath != null;

    Point<double>? screenPoint;
    try {
      screenPoint =
          widget.mapController.camera.latLngToScreenPoint(widget.selection.position);
    } catch (_) {
      return const SizedBox.shrink();
    }

    // Anchor: la tarjeta cuelga justo encima del pin y centrada
    // horizontalmente sobre el LatLng. El pin tiene un offset visual
    // de 7.5px hacia arriba (Alignment(0, 1.3) en el marker), así que
    // la tarjeta también se desplaza esa cantidad para mantenerse
    // pegada al top del pin.
    const pinHeight = 50.0;
    const pinOffsetY = 7.5; // (Alignment.y - 1) * height/2 = 0.3 * 25
    const gap = 2.0;
    const cardWidth = 240.0;

    final left = screenPoint.x - cardWidth / 2;
    final bottomFromTop =
        screenPoint.y - pinHeight - gap - pinOffsetY;

    return Positioned(
      left: left,
      top: bottomFromTop - 80, // 80 = altura estimada de la tarjeta
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: hasDetail ? widget.onOpenDetail : null,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selection.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.textHi,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.selection.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.selection.subtitle!,
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
                  InkWell(
                    onTap: widget.onClose,
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
      ),
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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
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
        // Scale anclado al bottomCenter para que la PUNTA del pin no se
        // mueva durante la animación de entrada. Antes había un
        // Transform.translate adicional con drop que daba la sensación
        // de que el pin saltaba; ahora solo crece desde la punta.
        return Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: _scale.value,
          child: SizedBox(
            width: 38,
            height: 50,
            child: CustomPaint(
              painter: _PinPainter(color: widget.color),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(widget.icon, color: Colors.white, size: 18),
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

    // La punta del triángulo queda EXACTAMENTE en `size.height` (bottom
    // del SizedBox del marker), que es donde el flutter_map ancla el
    // LatLng al usar alignment: bottomCenter. Antes terminaba 2px
    // arriba (`size.height - 2`) por dejar hueco para la sombra
    // elíptica; eso hacía que el LatLng real quedase 2px por debajo de
    // la punta visible y al alejar el zoom el pin parecía moverse.
    final tipY = size.height;

    // Sombra justo encima de la punta, dentro del SizedBox.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, tipY - 3),
        width: size.width * 0.55,
        height: 4,
      ),
      shadow,
    );

    final path = ui.Path();
    final radius = size.width / 2 - 2;
    final cx = size.width / 2;
    final cy = radius + 1;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    path.moveTo(cx - radius * 0.55, cy + radius * 0.85);
    path.lineTo(cx, tipY);
    path.lineTo(cx + radius * 0.55, cy + radius * 0.85);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}
