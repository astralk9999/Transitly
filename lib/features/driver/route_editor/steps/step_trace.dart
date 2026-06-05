import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../core/map/map_config.dart';
import '../editor_controller.dart';

class StepTrace extends StatefulWidget {
  const StepTrace({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onNext,
  });

  final RouteEditorController controller;
  final bool isDark;
  final VoidCallback onNext;

  @override
  State<StepTrace> createState() => _StepTraceState();
}

class _StepTraceState extends State<StepTrace> {
  /// Sub P2-05: índice del vértice seleccionado (para borrar).
  int? _selectedIndex;

  /// Umbral en metros para "tap sobre vértice existente".
  static const _tapThresholdMeters = 25.0;

  RouteEditorController get controller => widget.controller;
  bool get isDark => widget.isDark;

  void _onMapTap(LatLng point) {
    // Si el tap está cerca de un vértice existente, lo selecciona.
    const dist = Distance();
    for (var i = 0; i < controller.tracePoints.length; i++) {
      final p = controller.tracePoints[i];
      if (dist.as(LengthUnit.Meter, p, point) < _tapThresholdMeters) {
        setState(() {
          _selectedIndex = _selectedIndex == i ? null : i;
        });
        return;
      }
    }
    // Tap en zona libre → añade nuevo vértice y deselecciona.
    setState(() => _selectedIndex = null);
    controller.addTracePoint(point);
  }

  void _deleteSelected() {
    final i = _selectedIndex;
    if (i == null) return;
    controller.removeTracePointAt(i);
    setState(() => _selectedIndex = null);
  }

  void _closePolygon() {
    controller.closeTracePolygon();
    setState(() => _selectedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);
    final tracePoints = controller.tracePoints;
    final stops = controller.stops;
    final totalKm = controller.traceTotalKm;

    return Stack(
      children: [
        FlutterMap(
          mapController: controller.traceMapCtrl,
          options: MapOptions(
            initialCenter: MapConfig.defaultCenter,
            initialZoom: MapConfig.defaultZoom,
            onTap: (_, point) => _onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrl(isDark ? 'dark' : 'light'),
              subdomains: MapConfig.subdomains,
              retinaMode: true,
            ),
            if (tracePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tracePoints,
                    color: c.accent,
                    strokeWidth: 4,
                  ),
                ],
              ),
            // P2-05: paradas como markers ghost (referencia visual).
            if (stops.isNotEmpty)
              MarkerLayer(
                markers: stops.asMap().entries.map((e) {
                  return Marker(
                    point: e.value.position,
                    width: 22,
                    height: 22,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            // Vértices del trazado (resaltados si seleccionados).
            MarkerLayer(
              markers: tracePoints.asMap().entries.map((e) {
                final isSelected = _selectedIndex == e.key;
                final size = isSelected ? 32.0 : 24.0;
                return Marker(
                  point: e.value,
                  width: size,
                  height: size,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: isSelected ? c.stateCancelled : c.stateOnRoute,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white,
                          width: isSelected ? 2.5 : 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSelected ? 12 : 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Panel superior con contador + km total.
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: Text(
                  '${tracePoints.length} puntos · ${totalKm.toStringAsFixed(2)} km',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
                ),
              ),
              const Spacer(),
              if (_selectedIndex != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.stateCancelled.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.stateCancelled, width: 0.5),
                  ),
                  child: Text(
                    'Vértice ${_selectedIndex! + 1} seleccionado',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: c.stateCancelled),
                  ),
                ),
            ],
          ),
        ),
        // Panel inferior con botones.
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedIndex != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: 'BORRAR PUNTO',
                          isDanger: true,
                          icon: Icons.delete_outline,
                          onPressed: _deleteSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  if (tracePoints.length >= 3)
                    Expanded(
                      child: TransitButton(
                        label: 'CERRAR',
                        isPrimary: false,
                        icon: Icons.repeat,
                        onPressed: _closePolygon,
                      ),
                    ),
                  if (tracePoints.length >= 3) const SizedBox(width: 8),
                  if (tracePoints.isNotEmpty)
                    Expanded(
                      child: TransitButton(
                        label:
                            AppLocalizations.of(context).actionUndo.toUpperCase(),
                        isPrimary: false,
                        icon: Icons.undo,
                        onPressed: () {
                          controller.removeLastTracePoint();
                          setState(() => _selectedIndex = null);
                        },
                      ),
                    ),
                  if (tracePoints.isNotEmpty) const SizedBox(width: 8),
                  Expanded(
                    child: TransitButton(
                      label: AppLocalizations.of(context).actionNext.toUpperCase(),
                      onPressed: tracePoints.length >= 2 ? widget.onNext : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
