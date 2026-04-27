import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../shared/widgets/single_field_dialog.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../map/map_config.dart';
import '../editor_controller.dart';

class StepStops extends StatelessWidget {
  const StepStops({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onNext,
  });

  final RouteEditorController controller;
  final bool isDark;
  final VoidCallback onNext;

  Future<void> _addStop(BuildContext context, LatLng point) async {
    final name = await showSingleFieldDialog(
      context,
      title: 'Nueva parada',
      hint: 'Nombre de la parada',
      confirmLabel: 'CONFIRMAR',
    );
    if (name != null) {
      controller.addStop(EditorStop(name, point));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);
    final stops = controller.stops;
    final tracePoints = controller.tracePoints;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: controller.stopsMapCtrl,
                options: MapOptions(
                  initialCenter: MapConfig.defaultCenter,
                  initialZoom: MapConfig.defaultZoom,
                  onTap: (_, point) => _addStop(context, point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrl(isDark),
                    subdomains: MapConfig.subdomains,
                    retinaMode: true,
                  ),
                  if (tracePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: tracePoints,
                          color: c.accent.withAlpha(128),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: stops.asMap().entries.map((e) {
                      return Marker(
                        point: e.value.position,
                        width: 28,
                        height: 28,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.bgSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.border, width: 0.5),
                      ),
                      child: Text(
                        '${stops.length} paradas',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 12, color: c.textMid),
                      ),
                    ),
                    const Spacer(),
                    TransitButton(
                      label: 'SIGUIENTE',
                      onPressed: stops.length >= 2 ? onNext : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (stops.isNotEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border(top: BorderSide(color: c.border, width: 0.5)),
            ),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: stops.length,
              onReorder: controller.reorderStops,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return ListTile(
                  key: ValueKey(stop.id),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    '${index + 1}',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 14, color: c.accent),
                  ),
                  title: Text(stop.name,
                      style: TransitTypography.bodySecondary(c.textHi)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 16, color: c.textLo),
                    onPressed: () => controller.removeStopAt(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
