import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/capacity_indicator.dart';
import '../../shared/widgets/stagger_list.dart';
import '../../shared/widgets/transit_chip.dart';

class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final stop = mockData.getStopById(stopId);

    if (stop == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Parada no encontrada')),
      );
    }

    // Find all routes that pass through this stop
    final routesAtStop = <String>[];
    for (final entry in mockData.routeStops.entries) {
      if (entry.value.any((rs) => rs.stopId == stopId)) {
        routesAtStop.add(entry.key);
      }
    }

    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ContentConstraints(
        child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 48),

                // ── BACK ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child:
                        Icon(Icons.arrow_back, size: 24, color: c.textMid),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 1. HEADER ──
                Text(
                  stop.name.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: c.textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop.municipality} · ${stop.officialCode}',
                  style: TransitTypography.subheading(c.textMid),
                ),
                const SizedBox(height: 12),

                // Service icons
                Row(
                  children: [
                    if (stop.hasShelter) _serviceIcon(c, Icons.home, 'Marquesina'),
                    if (stop.isAccessible)
                      _serviceIcon(c, Icons.accessible, 'Accesible'),
                    if (stop.hasBench)
                      _serviceIcon(c, Icons.event_seat, 'Banco'),
                  ],
                ),

                Divider(height: 32, thickness: 0.5, color: c.border),

                // ── 2. PRÓXIMAS LLEGADAS ──
                Text('PRÓXIMAS LLEGADAS',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),

                if (routesAtStop.isEmpty)
                  Text('Sin líneas registradas',
                      style: TransitTypography.bodySecondary(c.textMid))
                else
                  StaggerList(
                    children: routesAtStop.map((routeId) {
                      final route = mockData.getRouteById(routeId);
                      if (route == null) return const SizedBox.shrink();

                      final nextDeps =
                          mockData.getNextDepartures(routeId, stopId, 1);
                      final activeTrip =
                          mockData.getActiveTripForRoute(routeId);

                      final now = DateTime.now();
                      final nowMinutes = now.hour * 60 + now.minute;

                      String timeStr = '--:--';
                      String countdownStr = '';
                      bool isNext = false;

                      if (nextDeps.isNotEmpty) {
                        timeStr = nextDeps.first.departureTime;
                        final parts = timeStr.split(':');
                        final depMinutes =
                            int.parse(parts[0]) * 60 + int.parse(parts[1]);
                        final diff = depMinutes - nowMinutes;
                        countdownStr = 'en $diff min';
                        isNext = diff <= 10;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.push('/route/$routeId'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: c.bgSurface,
                              border: Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                TransitChip(route.code,
                                    color: route.routeColor),
                                const SizedBox(width: 12),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: c.textHi,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    countdownStr,
                                    style: GoogleFonts.ibmPlexMono(
                                      fontSize: 14,
                                      color: isNext ? c.accent : c.textMid,
                                    ),
                                  ),
                                ),
                                if (activeTrip != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CapacityIndicator(
                                        activeTrip.capacity),
                                  ),
                                Icon(Icons.notifications_none,
                                    size: 20, color: c.textMid),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // ── 3. LÍNEAS QUE PASAN ──
                Text('LÍNEAS',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: routesAtStop.map((routeId) {
                    final route = mockData.getRouteById(routeId);
                    if (route == null) return const SizedBox.shrink();
                    return TransitChip(
                      route.code,
                      color: route.routeColor,
                      onTap: () => context.push('/route/$routeId'),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── 4. ACCIONES ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionButton(context, c, Icons.warning_amber,
                        'Reportar'),
                    _actionButton(context, c, Icons.edit, 'Mejorar'),
                    _actionButton(context, c, Icons.share, 'Compartir'),
                    _actionButton(
                        context, c, Icons.navigation, 'Cómo llegar'),
                  ],
                ),

                const SizedBox(height: 24),

                // ── 5. SUGERENCIA ──
                GestureDetector(
                  onTap: () => context.push('/suggestions/new'),
                  child: Text(
                    '¿Pasa por aquí una línea que no aparece? →',
                    style: TransitTypography.bodySecondary(c.accent),
                  ),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _serviceIcon(TransitColorScheme c, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Icon(icon, size: 16, color: c.textMid),
          const SizedBox(height: 2),
          Text(label, style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, TransitColorScheme c, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: próximamente')),
        );
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.bgRaised,
              shape: BoxShape.circle,
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(icon, size: 18, color: c.textHi),
          ),
          const SizedBox(height: 4),
          Text(label, style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }
}
