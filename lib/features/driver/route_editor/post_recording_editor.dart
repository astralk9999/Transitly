import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';
import '../../map/map_config.dart';
import 'recorded_session.dart';

class PostRecordingEditor extends StatefulWidget {
  const PostRecordingEditor({
    super.key,
    required this.trace,
    required this.stops,
  });

  final List<LatLng> trace;
  final List<RecordedStop> stops;

  @override
  State<PostRecordingEditor> createState() => _PostRecordingEditorState();
}

class _PostRecordingEditorState extends State<PostRecordingEditor> {
  late List<RecordedStop> _stops;
  int? _editingIndex;
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stops = List<RecordedStop>.from(widget.stops);
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
    final trace = widget.trace;

    if (trace.isEmpty) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: Stack(
          children: [
            Positioned.fill(
                child: SmokeBackground(color: c.accent, isDark: isDark)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sin grabación que editar',
                      style: TransitTypography.bodyPrimary(c.textMid)),
                  const SizedBox(height: 16),
                  TransitButton(
                    label: AppLocalizations.of(context).actionBack.toUpperCase(),
                    isSmall: true,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text('EDITAR GRABACIÓN',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
            children: [
              // Map preview
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: trace[trace.length ~/ 2],
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.tileUrl(isDark ? 'dark' : 'light'),
                      subdomains: MapConfig.subdomains,
                      retinaMode: true,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: trace,
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
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
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
                child: _stops.isEmpty
                    ? Center(
                        child: Text('Sin paradas marcadas',
                            style:
                                TransitTypography.bodySecondary(c.textMid)),
                      )
                    : ListView.builder(
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
                              border:
                                  Border.all(color: c.border, width: 0.5),
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
                                        tooltip: 'Confirmar edición',
                                        onPressed: () {
                                          setState(() {
                                            _stops[index] = stop.copyWith(
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
                                          style:
                                              TransitTypography.bodySecondary(
                                            stop.name != null
                                                ? c.textHi
                                                : c.textLo,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _fmtOffset(stop.arrivalOffset),
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
                          label: 'GUARDAR LOCAL (prototipo)',
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
        ],
      ),
    );
  }

  String _fmtOffset(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
