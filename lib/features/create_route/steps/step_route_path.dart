import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/transit_button.dart';
import 'wizard_models.dart';

class StepRoutePath extends StatefulWidget {
  const StepRoutePath({
    super.key,
    required this.stops,
    required this.path,
    required this.onChanged,
  });

  final List<WizardStop> stops;
  final WizardRoutePath path;
  final VoidCallback onChanged;

  @override
  State<StepRoutePath> createState() => _StepRoutePathState();
}

class _StepRoutePathState extends State<StepRoutePath> {
  final _mapController = MapController();
  int? _editingSegmentIndex;
  final List<WizardRoutePathPoint> _currentPoints = [];

  LatLng _mapCenter() {
    if (widget.stops.isNotEmpty) {
      final s = widget.stops.first;
      return LatLng(s.lat, s.lng);
    }
    return const LatLng(36.6819, -6.1365);
  }

  void _startEditing(int index) {
    setState(() {
      _editingSegmentIndex = index;
      _currentPoints.clear();
      _currentPoints.addAll(widget.path.segments[index].points);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingSegmentIndex = null;
      _currentPoints.clear();
    });
  }

  /// Si está activo el modo "mover parada", el primer tap en el mapa
  /// re-ubica la parada seleccionada. Si no, y hay un segmento en
  /// edición, añade un waypoint al trazado.
  int? _movingStopIndex;

  void _addPoint(TapPosition tap, LatLng pos) {
    if (_movingStopIndex != null) {
      final i = _movingStopIndex!;
      if (i >= 0 && i < widget.stops.length) {
        widget.stops[i] = widget.stops[i].copyWith(
          lat: pos.latitude,
          lng: pos.longitude,
        );
        setState(() => _movingStopIndex = null);
        widget.onChanged();
      }
      return;
    }
    if (_editingSegmentIndex == null) return;
    setState(() {
      _currentPoints.add(WizardRoutePathPoint(lat: pos.latitude, lng: pos.longitude));
    });
  }

  void _confirmSegment() {
    if (_editingSegmentIndex == null) return;
    final seg = widget.path.segments[_editingSegmentIndex!];
    seg.points
      ..clear()
      ..addAll(_currentPoints);
    setState(() {
      _editingSegmentIndex = null;
      _currentPoints.clear();
    });
    widget.onChanged();
  }

  Widget _buildMap(TransitColorScheme colors) {
    final segments = widget.path.segments;
    final stopMarkers = <Marker>[];
    for (var idx = 0; idx < widget.stops.length; idx++) {
      final s = widget.stops[idx];
      final isMoving = _movingStopIndex == idx;
      final base = idx == 0
          ? Colors.green
          : idx == widget.stops.length - 1
              ? Colors.red
              : colors.accent;
      stopMarkers.add(Marker(
        point: LatLng(s.lat, s.lng),
        width: 36,
        height: 36,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              // Tap sobre una parada → toggle modo "mover esta parada".
              // El siguiente tap en zona libre del mapa la re-ubica.
              _movingStopIndex = isMoving ? null : idx;
              _editingSegmentIndex = null;
              _currentPoints.clear();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: base,
              shape: BoxShape.circle,
              border: Border.all(
                color: isMoving ? Colors.amber : Colors.white,
                width: isMoving ? 3 : 2,
              ),
              boxShadow: isMoving
                  ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text('${idx + 1}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ));
    }

    // Puntos visibles del segmento en edición: sin esto el usuario
    // toca el mapa y "no pasa nada" porque hace falta ≥2 puntos para
    // dibujar la polyline amarilla. Con markers individuales cada tap
    // queda confirmado al instante.
    final editingMarkers = <Marker>[];
    if (_editingSegmentIndex != null) {
      for (var i = 0; i < _currentPoints.length; i++) {
        final p = _currentPoints[i];
        editingMarkers.add(Marker(
          point: LatLng(p.lat, p.lng),
          width: 16,
          height: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ));
      }
    }

    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter(),
            initialZoom: 14.0,
            onTap: _addPoint,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.transitly.transitly',
            ),
            PolylineLayer(
              polylines: [
                for (final seg in segments) ...[
                  if (seg.points.isNotEmpty)
                    Polyline(
                      points: [for (final p in seg.points) LatLng(p.lat, p.lng)],
                      color: colors.accent,
                      strokeWidth: 3,
                    ),
                ],
                if (_editingSegmentIndex != null && _currentPoints.length >= 2)
                  Polyline(
                    points: [for (final p in _currentPoints) LatLng(p.lat, p.lng)],
                    color: Colors.amber,
                    strokeWidth: 3,
                  ),
              ],
            ),
            MarkerLayer(markers: stopMarkers),
            if (editingMarkers.isNotEmpty)
              MarkerLayer(markers: editingMarkers),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    final segments = widget.path.segments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trazar el camino', style: TransitTypography.heading(colors.textHi)),
          const SizedBox(height: 4),
          Text('Toca el mapa para añadir puntos del recorrido entre paradas.',
              style: TransitTypography.bodySecondary(colors.textMid)),
          const SizedBox(height: 16),
          _buildMap(colors),
          const SizedBox(height: 8),
          if (_movingStopIndex != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.6), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.open_with, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Moviendo parada ${_movingStopIndex! + 1}. Toca el mapa donde quieras colocarla.',
                      style: TransitTypography.bodySmall(colors.textHi),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: colors.textMid,
                    onPressed: () =>
                        setState(() => _movingStopIndex = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (_editingSegmentIndex == null) ...[
            Text(
              'Toca una parada para mover su posición. Para trazar el camino entre paradas, pulsa "Añadir puntos" en cualquier segmento de la lista de abajo.',
              style: TransitTypography.bodySmall(colors.textMid),
            ),
          ] else ...[
            Text(
              'Editando segmento ${_editingSegmentIndex! + 1} · ${_currentPoints.length} puntos',
              style: TransitTypography.bodyPrimary(colors.accent),
            ),
            const SizedBox(height: 4),
            Text(
              _currentPoints.isEmpty
                  ? 'Toca el mapa para añadir el primer punto.'
                  : 'Toca para añadir más puntos. Usa los botones de abajo para deshacer, confirmar o cancelar.',
              style: TransitTypography.bodySmall(colors.textMid),
            ),
            const SizedBox(height: 8),
            // Botones en Wrap para que ningún label se corte y sea
            // responsive en pantallas estrechas. Cancelar/Deshacer en
            // modo icono+texto reducen ancho sin perder claridad.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      _currentPoints.isEmpty ? null : _confirmSegment,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _currentPoints.isEmpty
                      ? null
                      : () =>
                          setState(() => _currentPoints.removeLast()),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Deshacer'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    foregroundColor: colors.textHi,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _cancelEditing,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    foregroundColor: colors.textMid,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (widget.stops.length >= 2) ...[
            Text('Segmentos', style: TransitTypography.sectionTitle(colors.textHi)),
            const SizedBox(height: 8),
            for (var i = 0; i < segments.length; i++) ...[
              _SegmentCard(
                index: i,
                segment: segments[i],
                stops: widget.stops,
                colors: colors,
                onEdit: () => _startEditing(i),
              ),
            ],
          ] else
            Text('Añade al menos 2 paradas en el paso anterior para trazar el camino.',
                style: TransitTypography.bodySecondary(colors.textMid)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.segment,
    required this.stops,
    required this.colors,
    required this.onEdit,
  });

  final int index;
  final WizardSegment segment;
  final List<WizardStop> stops;
  final TransitColorScheme colors;
  final VoidCallback onEdit;

  WizardStop? _findStop(String id) {
    for (final s in stops) {
      if (s.stopId == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final from = _findStop(segment.fromStopId);
    final to = _findStop(segment.toStopId);
    final hasPoints = segment.points.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: TransitSpacing.space8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasPoints ? colors.accent.withValues(alpha: 0.15) : colors.textLo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(hasPoints ? Icons.route : Icons.straighten,
                  size: 16, color: hasPoints ? colors.accent : colors.textLo),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${from?.name ?? '?'}  →  ${to?.name ?? '?'}',
                    style: TransitTypography.bodyPrimary(colors.textHi),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    hasPoints ? '${segment.points.length} puntos' : 'Línea recta',
                    style: TransitTypography.bodySmall(
                        hasPoints ? colors.accent : colors.textMid),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(hasPoints ? 'Editar' : 'Añadir puntos',
                  style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
