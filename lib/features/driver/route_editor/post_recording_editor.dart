import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';
import '../../map/map_config.dart';

class PostRecordingEditor extends StatefulWidget {
  const PostRecordingEditor({super.key});

  @override
  State<PostRecordingEditor> createState() => _PostRecordingEditorState();
}

class _PostRecordingEditorState extends State<PostRecordingEditor> {
  // Mock recorded data (in real app, passed from LiveRouteRecorder)
  final _trace = const [
    LatLng(36.6819, -6.1365),
    LatLng(36.6826, -6.1357),
    LatLng(36.6834, -6.1349),
    LatLng(36.6828, -6.1355),
    LatLng(36.6815, -6.1340),
    LatLng(36.6800, -6.1320),
    LatLng(36.6786, -6.1287),
    LatLng(36.6760, -6.1340),
    LatLng(36.6720, -6.1360),
    LatLng(36.6700, -6.1370),
    LatLng(36.6680, -6.1350),
  ];

  late final List<_PostStop> _stops;
  int? _editingIndex;
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stops = [
      _PostStop(position: _trace[0], distKm: 0),
      _PostStop(position: _trace[3], distKm: 0.12),
      _PostStop(position: _trace[6], distKm: 0.45),
      _PostStop(position: _trace[8], distKm: 0.78),
      _PostStop(position: _trace[10], distKm: 1.1),
    ];
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('EDITAR GRABACIÓN',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Map preview
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _trace[_trace.length ~/ 2],
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrl(isDark),
                  subdomains: MapConfig.subdomains,
                  retinaMode: true,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trace,
                      color: c.accent,
                      strokeWidth: 3,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _stops.asMap().entries.map((e) {
                    return Marker(
                      point: e.value.position,
                      width: 24,
                      height: 24,
                      child: Container(
                        width: 24,
                        height: 24,
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
          ),

          // Stop list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stops.length,
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final isEditing = _editingIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: TransitInput(
                                hint: 'Nombre de la parada',
                                controller: _editCtrl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.check,
                                  size: 20, color: c.accent),
                              onPressed: () {
                                setState(() {
                                  _stops[index] = _PostStop(
                                    position: stop.position,
                                    distKm: stop.distKm,
                                    name: _editCtrl.text.isNotEmpty
                                        ? _editCtrl.text
                                        : null,
                                  );
                                  _editingIndex = null;
                                });
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              '#${index + 1}',
                              style: GoogleFonts.ibmPlexMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stop.name ?? 'sin nombre',
                                style: TransitTypography.bodySecondary(
                                  stop.name != null
                                      ? c.textHi
                                      : c.textLo,
                                ),
                              ),
                            ),
                            Text(
                              '${stop.distKm.toStringAsFixed(2)} km',
                              style: GoogleFonts.ibmPlexMono(
                                  fontSize: 12, color: c.textMid),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _editingIndex = index;
                                  _editCtrl.text = stop.name ?? '';
                                });
                              },
                              child: Text('Renombrar',
                                  style: TransitTypography.bodySmall(
                                      c.accent)),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: 'GUARDAR BORRADOR',
                      isPrimary: false,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Borrador guardado')),
                        );
                        context.pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TransitButton(
                      label: 'PUBLICAR RUTA',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Ruta publicada')),
                        );
                        context.go('/home/mapa');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostStop {
  final LatLng position;
  final double distKm;
  final String? name;
  const _PostStop({
    required this.position,
    required this.distKm,
    this.name,
  });
}
