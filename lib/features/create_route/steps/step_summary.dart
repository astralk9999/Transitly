import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_checkbox.dart';
import 'wizard_models.dart';

class StepSummary extends StatelessWidget {
  const StepSummary({
    super.key,
    required this.routeName,
    required this.routeColor,
    required this.serviceType,
    required this.stopsCount,
    required this.schedulesCount,
    required this.visibility,
    required this.proposeAsCommunity,
    required this.onProposeChanged,
    required this.stops,
    required this.path,
  });

  final String routeName;
  final String routeColor;
  final String serviceType;
  final int stopsCount;
  final int schedulesCount;
  final String visibility;
  final bool proposeAsCommunity;
  final ValueChanged<bool> onProposeChanged;
  final List<WizardStop> stops;
  final WizardRoutePath path;

  static const _serviceTypeLabels = {
    'urban': 'Urbano',
    'interurban': 'Interurbano',
    'long_distance': 'Larga distancia',
    'school': 'Escolar',
    'on_demand': 'A demanda',
    'custom': 'Personalizado',
  };

  static const _visibilityLabels = {
    'public': 'Pública',
    'unlisted': 'Solo con código / enlace',
    'private': 'Privada',
  };

  Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    final typeLabel = _serviceTypeLabels[serviceType] ?? serviceType;
    final visibilityLabel = _visibilityLabels[visibility] ?? visibility;
    final parsedColor = _parseColor(routeColor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: TransitTypography.heading(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space4),
          Text(
            'Revisa tu ruta antes de publicarla.',
            style: TransitTypography.bodySecondary(colors.textMid),
          ),
          const SizedBox(height: TransitSpacing.space24),

          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(TransitSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (parsedColor != null)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: parsedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (parsedColor != null)
                      const SizedBox(width: TransitSpacing.space8),
                    Expanded(
                      child: Text(
                        routeName.isNotEmpty
                            ? routeName
                            : '(sin nombre)',
                        style: TransitTypography.heading(colors.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space16),
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.directions_bus,
                      label: '$stopsCount paradas',
                      colors: colors,
                    ),
                    const SizedBox(width: TransitSpacing.space16),
                    _StatItem(
                      icon: Icons.schedule,
                      label: '$schedulesCount horarios',
                      colors: colors,
                    ),
                    const SizedBox(width: TransitSpacing.space16),
                    _StatItem(
                      icon: Icons.category,
                      label: typeLabel,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space8),
                _StatItem(
                  icon: _visibilityIcon(visibility),
                  label: visibilityLabel,
                  colors: colors,
                ),
              ],
            ),
          ),

          const SizedBox(height: TransitSpacing.space16),
          // Botón "Vista previa" — abre un mapa interactivo con las
          // paradas + trazado para que el usuario revise antes de
          // publicar. Antes solo se podían ver números (paradas, h)
          // sin saber realmente cómo iba a quedar la ruta.
          TransitButton(
            label: 'Vista previa en el mapa',
            icon: Icons.map_outlined,
            isPrimary: false,
            onPressed: stops.length >= 2
                ? () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _PreviewMapScreen(
                        stops: stops,
                        path: path,
                        color: parsedColor ?? colors.accent,
                        routeName: routeName,
                      ),
                    ));
                  }
                : null,
          ),
          const SizedBox(height: TransitSpacing.space24),

          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(TransitSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        size: 20, color: colors.accent),
                    const SizedBox(width: TransitSpacing.space8),
                    Expanded(
                      child: Text(
                        'Contribución comunitaria',
                        style: TransitTypography.bodyPrimary(colors.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space12),
                TransitCheckbox(
                  proposeAsCommunity,
                  onProposeChanged,
                  'Proponer como ruta comunitaria oficial',
                ),
                const SizedBox(height: TransitSpacing.space8),
                Text(
                  'Si se aprueba, aparecerá en el buscador público como ruta verificada.',
                  style: TransitTypography.bodySmall(colors.textLo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _visibilityIcon(String v) {
    switch (v) {
      case 'public':
        return Icons.public;
      case 'unlisted':
        return Icons.link;
      case 'private':
        return Icons.lock;
      default:
        return Icons.visibility;
    }
  }
}

class _PreviewMapScreen extends StatelessWidget {
  const _PreviewMapScreen({
    required this.stops,
    required this.path,
    required this.color,
    required this.routeName,
  });

  final List<WizardStop> stops;
  final WizardRoutePath path;
  final Color color;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    final mapController = MapController();

    final bounds = LatLngBounds.fromPoints(
      stops.map((s) => LatLng(s.lat, s.lng)).toList(),
    );

    final stopMarkers = <Marker>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      stopMarkers.add(Marker(
        point: LatLng(s.lat, s.lng),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: i == 0
                ? Colors.green
                : i == stops.length - 1
                    ? Colors.red
                    : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text('${i + 1}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ));
    }

    // Polilínea: usar el trazado custom de cada segmento si existe;
    // si no, línea recta entre las paradas consecutivas.
    final polylines = <Polyline>[];
    for (var i = 0; i < stops.length - 1; i++) {
      final segs = path.segments.where(
        (s) => s.fromStopId == stops[i].stopId && s.toStopId == stops[i + 1].stopId,
      );
      if (segs.isNotEmpty && segs.first.points.isNotEmpty) {
        polylines.add(Polyline(
          points: [
            LatLng(stops[i].lat, stops[i].lng),
            for (final p in segs.first.points) LatLng(p.lat, p.lng),
            LatLng(stops[i + 1].lat, stops[i + 1].lng),
          ],
          color: color,
          strokeWidth: 4,
        ));
      } else {
        polylines.add(Polyline(
          points: [
            LatLng(stops[i].lat, stops[i].lng),
            LatLng(stops[i + 1].lat, stops[i + 1].lng),
          ],
          color: color.withValues(alpha: 0.55),
          strokeWidth: 3,
        ));
      }
    }

    return Scaffold(
      backgroundColor: colors.bgRoot,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        foregroundColor: colors.textHi,
        title: Text(
          routeName.isNotEmpty ? routeName : 'Vista previa',
          style: TransitTypography.heading(colors.textHi),
        ),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ),
          minZoom: 4,
          maxZoom: 19,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.transitly.transitly',
          ),
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: stopMarkers),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textLo),
        const SizedBox(width: TransitSpacing.space4),
        Text(
          label,
          style: TransitTypography.bodySmall(colors.textMid),
        ),
      ],
    );
  }
}
