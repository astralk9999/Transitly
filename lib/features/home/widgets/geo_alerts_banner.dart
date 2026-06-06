import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/geo_alerts/geo_alerts_repository.dart';
import '../../../shared/models/geo_alert_model.dart';
import '../../../shared/providers/user_location_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Sub P2-#55: banner que muestra avisos geo activos cuyo radio incluye
/// la ubicación actual del usuario. Se renderiza arriba de la pantalla
/// de inicio. Sin notificación push (versión simplificada).
class GeoAlertsBanner extends ConsumerWidget {
  const GeoAlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final alertsAsync = ref.watch(activeGeoAlertsProvider);
    final userPos = ref.watch(userLocationLatLngProvider);

    return alertsAsync.maybeWhen(
      data: (alerts) {
        final relevant = userPos == null
            ? const <GeoAlertModel>[]
            : alerts.where((a) {
                const dist = Distance();
                final d = dist.as(
                    LengthUnit.Meter,
                    userPos,
                    LatLng(a.centerLat, a.centerLng));
                return d <= a.radiusM;
              }).toList();
        if (relevant.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: relevant
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AlertCard(alert: a, c: c),
                  ))
              .toList(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.c});
  final GeoAlertModel alert;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    final sevColor = switch (alert.severity) {
      GeoAlertSeverity.info => c.accent,
      GeoAlertSeverity.warning => c.stateDelay,
      GeoAlertSeverity.critical => c.stateCancelled,
    };
    final icon = switch (alert.severity) {
      GeoAlertSeverity.info => Icons.info_outline,
      GeoAlertSeverity.warning => Icons.warning_amber_outlined,
      GeoAlertSeverity.critical => Icons.error_outline,
    };
    return GlassCard(
      blur: 12,
      fillOpacity: 0.08,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: sevColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style:
                      TransitTypography.bodyPrimary(c.textHi).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(alert.body,
                    style: TransitTypography.bodySecondary(c.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
