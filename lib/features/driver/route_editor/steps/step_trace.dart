import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../core/map/map_config.dart';
import '../editor_controller.dart';

class StepTrace extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);
    final tracePoints = controller.tracePoints;

    return Stack(
      children: [
        FlutterMap(
          mapController: controller.traceMapCtrl,
          options: MapOptions(
            initialCenter: MapConfig.defaultCenter,
            initialZoom: MapConfig.defaultZoom,
            onTap: (_, point) => controller.addTracePoint(point),
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
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(
              markers: tracePoints.asMap().entries.map((e) {
                return Marker(
                  point: e.value,
                  width: 24,
                  height: 24,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.stateOnRoute,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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
              if (tracePoints.isNotEmpty)
                Expanded(
                  child: TransitButton(
                    label: AppLocalizations.of(context).actionUndo.toUpperCase(),
                    isPrimary: false,
                    icon: Icons.undo,
                    onPressed: controller.removeLastTracePoint,
                  ),
                ),
              if (tracePoints.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: TransitButton(
                  label: AppLocalizations.of(context).actionNext.toUpperCase(),
                  onPressed: tracePoints.length >= 2 ? onNext : null,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Text(
              '${tracePoints.length} puntos',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
            ),
          ),
        ),
      ],
    );
  }
}
