import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Estadísticas agregadas del conductor, calculadas sobre el historial
/// de viajes del [MockDataService] (mock-first, sin backend).
class DriverStatsScreen extends ConsumerWidget {
  const DriverStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mock = ref.watch(mockDataServiceProvider);
    final trips = mock.tripHistory;

    if (trips.isEmpty) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: const Column(
          children: [
            TransitAppBar(title: 'Estadísticas'),
            Expanded(
              child: EmptyState(
                'Sin datos aún',
                'Tus estadísticas se calculan a partir del historial de viajes.',
                icon: Icons.insights,
              ),
            ),
          ],
        ),
      );
    }

    final totalTrips = trips.length;
    final totalCost = trips.fold<double>(0, (s, t) => s + (t.cost ?? 0));
    final totalKm = trips.fold<double>(0, (s, t) => s + (t.distanceKm ?? 0));
    final co2 = trips.fold<double>(0, (s, t) => s + (t.co2SavedKg ?? 0));
    final distinctRoutes = trips.map((t) => t.routeId).toSet().length;

    final cards = <_StatData>[
      _StatData('Viajes', '$totalTrips', Icons.directions_bus),
      _StatData('Líneas distintas', '$distinctRoutes', Icons.alt_route),
      _StatData(
          'Coste total', '${totalCost.toStringAsFixed(2)} €', Icons.payments),
      _StatData(
          'Distancia', '${totalKm.toStringAsFixed(1)} km', Icons.straighten),
      _StatData('CO₂ ahorrado', '${co2.toStringAsFixed(1)} kg', Icons.eco),
    ];

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          const TransitAppBar(title: 'Estadísticas'),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(TransitSpacing.space16),
              crossAxisCount: 2,
              mainAxisSpacing: TransitSpacing.space12,
              crossAxisSpacing: TransitSpacing.space12,
              childAspectRatio: 1.3,
              children: [
                for (final s in cards) _StatCard(c: c, data: s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.c, required this.data});
  final TransitColorScheme c;
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(data.icon, color: c.accent, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: TransitTypography.heading(c.textHi)),
              const SizedBox(height: 2),
              Text(data.label,
                  style: TransitTypography.bodySecondary(c.textMid)),
            ],
          ),
        ],
      ),
    );
  }
}
