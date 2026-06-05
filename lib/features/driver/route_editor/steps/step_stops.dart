import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../shared/widgets/single_field_dialog.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../core/map/map_config.dart';
import '../editor_controller.dart';
import '../widgets/stop_picker_sheet.dart';

class StepStops extends StatefulWidget {
  const StepStops({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onNext,
  });

  final RouteEditorController controller;
  final bool isDark;
  final VoidCallback onNext;

  @override
  State<StepStops> createState() => _StepStopsState();
}

class _StepStopsState extends State<StepStops> {
  String _filter = '';

  RouteEditorController get controller => widget.controller;
  bool get isDark => widget.isDark;
  VoidCallback get onNext => widget.onNext;

  Future<void> _addStop(BuildContext context, LatLng point) async {
    final name = await showSingleFieldDialog(
      context,
      title: 'Nueva parada',
      hint: 'Nombre de la parada',
      confirmLabel: AppLocalizations.of(context).actionConfirm.toUpperCase(),
    );
    if (name != null) {
      controller.addStop(EditorStop(name, point));
    }
  }

  /// Distancia haversine entre dos LatLng en metros.
  double _distance(LatLng a, LatLng b) {
    const dist = Distance();
    return dist.as(LengthUnit.Meter, a, b);
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
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
                    urlTemplate: MapConfig.tileUrl(isDark ? 'dark' : 'light'),
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
                    const SizedBox(width: 8),
                    if (stops.length >= 2)
                      IconButton(
                        onPressed: controller.reverseStops,
                        tooltip: 'Invertir orden',
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: c.bgSurface,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: c.border, width: 0.5),
                          ),
                          child: Icon(Icons.swap_vert,
                              size: 16, color: c.textMid),
                        ),
                      ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => StopPickerSheet(
                            onPicked: (picked) {
                              for (final s in picked) {
                                controller.addStop(s);
                              }
                            },
                          ),
                        );
                      },
                      tooltip: 'Añadir desde catálogo',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: c.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.border, width: 0.5),
                        ),
                        child: Icon(Icons.search,
                            size: 16, color: c.textMid),
                      ),
                    ),
                    const Spacer(),
                    TransitButton(
                      label: AppLocalizations.of(context).actionNext.toUpperCase(),
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
            height: 180,
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border(top: BorderSide(color: c.border, width: 0.5)),
            ),
            child: Column(
              children: [
                // P2-04: buscador local sobre las paradas ya añadidas.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    style: TransitTypography.bodySecondary(c.textHi),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Filtrar paradas',
                      hintStyle: TransitTypography.bodySmall(c.textLo),
                      prefixIcon:
                          Icon(Icons.search, size: 16, color: c.textLo),
                      filled: true,
                      fillColor: c.bgRaised,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: c.border),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildStopList(stops, c),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStopList(List<EditorStop> stops, TransitColorScheme c) {
    final q = _filter.toLowerCase();
    final indices = stops
        .asMap()
        .entries
        .where((e) =>
            q.isEmpty || e.value.name.toLowerCase().contains(q))
        .map((e) => e.key)
        .toList();

    if (indices.isEmpty) {
      return Center(
        child: Text(
          'Sin coincidencias',
          style: TransitTypography.bodySecondary(c.textLo),
        ),
      );
    }

    // ReorderableListView solo opera correctamente si itera todos los items
    // sin filtro (los keys son por index). Si hay filtro activo, usamos un
    // ListView simple sin drag.
    if (_filter.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: indices.length,
        itemBuilder: (_, i) => _buildStopTile(stops, indices[i], c),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: stops.length,
      onReorder: controller.reorderStops,
      itemBuilder: (_, index) => _buildStopTile(stops, index, c),
    );
  }

  Widget _buildStopTile(
      List<EditorStop> stops, int index, TransitColorScheme c) {
    final stop = stops[index];
    final prev = index > 0 ? stops[index - 1] : null;
    final distance = prev != null ? _distance(prev.position, stop.position) : 0.0;

    return ListTile(
      key: ValueKey(stop.id),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(
        '${index + 1}',
        style: GoogleFonts.ibmPlexMono(fontSize: 14, color: c.accent),
      ),
      title: Text(stop.name,
          style: TransitTypography.bodySecondary(c.textHi)),
      subtitle: prev == null
          ? null
          : Text(
              '↑ ${_formatDistance(distance)}',
              style: TransitTypography.bodySmall(c.textLo),
            ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16, color: c.textLo),
        tooltip: 'Eliminar parada',
        onPressed: () => controller.removeStopAt(index),
      ),
    );
  }
}
