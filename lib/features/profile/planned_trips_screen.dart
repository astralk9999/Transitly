import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/user_favorite_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Viajes planificados / habituales del usuario, derivados de sus rutas
/// favoritas del [MockDataService] (parada de casa + aviso configurado).
class PlannedTripsScreen extends ConsumerWidget {
  const PlannedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mock = ref.watch(mockDataServiceProvider);
    final favs = mock.favorites;

    RouteModel? routeFor(String id) {
      for (final r in mock.routes) {
        if (r.id == id || r.code == id) return r;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          const TransitAppBar(title: 'Viajes planificados'),
          Expanded(
            child: favs.isEmpty
                ? const EmptyState(
                    'Sin viajes planificados',
                    'Marca una ruta como favorita y configura un aviso para '
                    'verla aquí como viaje habitual.',
                    icon: Icons.event_repeat,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(TransitSpacing.space16),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: TransitSpacing.space8),
                    itemBuilder: (context, i) {
                      final f = favs[i];
                      return _PlannedTile(
                        c: c,
                        fav: f,
                        route: routeFor(f.routeId),
                        stopName:
                            mock.getStopById(f.homeStopId ?? '')?.name,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({
    required this.c,
    required this.fav,
    required this.route,
    required this.stopName,
  });

  final TransitColorScheme c;
  final UserFavoriteModel fav;
  final RouteModel? route;
  final String? stopName;

  @override
  Widget build(BuildContext context) {
    final code = route?.code ?? fav.routeId;
    final name = route?.name ?? 'Ruta desconocida';

    return Container(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (route?.routeColor ?? c.accent).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(code,
                style: TransitTypography.bodyPrimary(
                    route?.routeColor ?? c.accent)),
          ),
          const SizedBox(width: TransitSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TransitTypography.bodyPrimary(c.textHi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  stopName == null ? 'Parada no definida' : 'Desde $stopName',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),
          if (fav.alarmMinutesBefore != null)
            Row(
              children: [
                Icon(Icons.notifications_active,
                    size: 16, color: c.accent),
                const SizedBox(width: 4),
                Text('${fav.alarmMinutesBefore} min',
                    style: TransitTypography.bodySecondary(c.accent)),
              ],
            ),
        ],
      ),
    );
  }
}
