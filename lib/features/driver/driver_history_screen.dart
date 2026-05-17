import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/trip_history_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Historial de actividad del conductor: cada viaje registrado, con la
/// línea, fecha, trayecto y coste. Datos del [MockDataService] (mock-first).
class DriverHistoryScreen extends ConsumerWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mock = ref.watch(mockDataServiceProvider);

    final trips = [...mock.tripHistory]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    RouteModel? routeFor(TripHistoryModel t) {
      for (final r in mock.routes) {
        if (r.id == t.routeId || r.code == t.routeId) return r;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          const TransitAppBar(title: 'Historial de conductor'),
          Expanded(
            child: trips.isEmpty
                ? const EmptyState(
                    'Sin viajes todavía',
                    'Cuando completes rutas aparecerán aquí con su trayecto y coste.',
                    icon: Icons.history,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(TransitSpacing.space16),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: TransitSpacing.space8),
                    itemBuilder: (context, i) {
                      final t = trips[i];
                      final route = routeFor(t);
                      return _TripTile(c: c, trip: t, route: route);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.c, required this.trip, required this.route});

  final TransitColorScheme c;
  final TripHistoryModel trip;
  final RouteModel? route;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy · HH:mm');
    final code = route?.code ?? trip.routeId;
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
            child: Text(
              code,
              style: TransitTypography.bodyPrimary(
                route?.routeColor ?? c.accent,
              ),
            ),
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
                Text(df.format(trip.startedAt),
                    style: TransitTypography.bodySecondary(c.textMid)),
              ],
            ),
          ),
          if (trip.cost != null)
            Text('${trip.cost!.toStringAsFixed(2)} €',
                style: TransitTypography.bodyPrimary(c.accent)),
        ],
      ),
    );
  }
}
