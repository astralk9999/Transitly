import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../map/map_config.dart';
import '../editor_controller.dart';

class StepReview extends ConsumerWidget {
  const StepReview({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final RouteEditorController controller;
  final bool isDark;

  String _returnLabel(String choice) => switch (choice) {
        'invert' => 'Invertida',
        'new' => 'Nueva',
        _ => 'Solo ida',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = TransitColorScheme.of(isDark);
    final tracePoints = controller.tracePoints;
    final stops = controller.stops;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: tracePoints.isNotEmpty
                  ? tracePoints[tracePoints.length ~/ 2]
                  : MapConfig.defaultCenter,
              initialZoom: 14,
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
                markers: stops.asMap().entries.map((e) {
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
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border(top: BorderSide(color: c.border, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${controller.codeCtrl.text} · ${controller.nameCtrl.text}',
                style: TransitTypography.heading(c.textHi),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo: ${controller.serviceType} · ${stops.length} paradas · ${controller.totalScheduleCount} horarios',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              const SizedBox(height: 4),
              Text(
                'Vuelta: ${_returnLabel(controller.returnChoice)}',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: AppLocalizations.of(context).actionSaveDraft.toUpperCase(),
                      isPrimary: false,
                      onPressed: () async {
                        await controller.saveDraft();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Borrador guardado')),
                          );
                          context.pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TransitButton(
                      label: 'PUBLICAR',
                      onPressed: () async {
                        // F15: conectar a RouteRepository.create() para
                        // persistir ruta comunitaria en Supabase + cola offline.
                        if (controller.codeCtrl.text.isEmpty ||
                            controller.nameCtrl.text.isEmpty ||
                            controller.stops.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Código, nombre y al menos 2 paradas son obligatorios')),
                          );
                          return;
                        }
                        await controller.saveDraft();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Ruta guardada como borrador. La publicación se habilitará en F15.')),
                          );
                          context.go('/home/mapa');
                        }
                      },
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
