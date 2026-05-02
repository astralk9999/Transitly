import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/mock/mock_realtime_service.dart';
import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_stop_model.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/route_lookup_providers.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/route_detail_alerts_list.dart';
import 'widgets/route_detail_changelog.dart';
import 'widgets/route_detail_feedback_section.dart';
import 'widgets/route_detail_header.dart';
import 'widgets/route_detail_schedule_section.dart';
import 'widgets/route_detail_timeline.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int? _calcFrequency(List<ScheduleModel> schedules) {
    if (schedules.length < 2) return null;
    final times = schedules.map((s) => _timeToMinutes(s.departureTime)).toList()
      ..sort();
    var totalDiff = 0;
    for (var i = 1; i < times.length; i++) {
      totalDiff += times[i] - times[i - 1];
    }
    return (totalDiff / (times.length - 1)).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    // Refresh countdowns on clock tick.
    ref.watch(realtimeClockProvider);
    final route = mockData.getRouteById(routeId);

    if (route == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: const Center(child: Text('Ruta no encontrada')),
      );
    }

    final realtimeTrips = ref.watch(realtimeTripsProvider);
    final tripsList = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    ActiveTripModel? activeTrip;
    for (final t in tripsList) {
      if (t.routeId == routeId && t.status != TripStatus.cancelled) {
        activeTrip = t;
        break;
      }
    }

    final routeStopsList = mockData.routeStops[routeId] ?? const [];
    final sortedRouteStops = List<RouteStopModel>.from(routeStopsList)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final stopsForRoute = mockData.getStopsForRoute(routeId);
    final stopsMap = <String, StopModel>{
      for (final s in mockData.stops) s.id: s,
    };
    final alerts = mockData.getAlertsForRoute(routeId);
    final isFavorite = mockData.favorites.any((f) => f.routeId == routeId);

    // Transfers: memoized stop → route codes lookup (O(1) per stop).
    final stopToRoutes = ref.watch(stopToRouteCodesProvider);
    final transfers = <String, List<String>>{};
    for (final rs in sortedRouteStops) {
      final others = stopToRoutes[rs.stopId]
          ?.where((code) => code != route.code)
          .toList();
      if (others != null && others.isNotEmpty) {
        transfers[rs.stopId] = others;
      }
    }

    final lastTimeMinutes = sortedRouteStops.isNotEmpty
        ? sortedRouteStops.last.timeFromStartMinutes
        : null;
    final estimatedMinutes = lastTimeMinutes ?? (stopsForRoute.length * 3);

    final weekdaySchedules =
        mockData.getSchedulesForRoute(routeId, dayType: DayType.weekday);
    final frequency = _calcFrequency(weekdaySchedules);

    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          ContentConstraints(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 48),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Icon(Icons.arrow_back,
                                  size: 24, color: c.textMid),
                            ),
                          ),
                          const SizedBox(height: 16),
                          RouteDetailHeader(
                              route: route, activeTrip: activeTrip),
                          Divider(height: 32, thickness: 0.5, color: c.border),
                          RouteQuickInfoCells(
                            stopsCount: stopsForRoute.length,
                            estimatedMinutes: estimatedMinutes,
                            frequencyMinutes: frequency,
                          ),
                          const SizedBox(height: 24),
                          if (alerts.isNotEmpty) ...[
                            RouteDetailAlertsList(alerts: alerts),
                            const SizedBox(height: 16),
                          ],
                          RouteDetailTimeline(
                            sortedRouteStops: sortedRouteStops,
                            stopsMap: stopsMap,
                            transfers: transfers,
                            activeTrip: activeTrip,
                          ),
                          const SizedBox(height: 24),
                          RouteDetailScheduleSection(
                              mockData: mockData, routeId: routeId),
                          const SizedBox(height: 24),
                          RouteDetailChangelog(routeId: routeId),
                          const SizedBox(height: 24),
                          RouteDetailFeedbackSection(routeId: routeId),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: padding,
                  right: padding,
                  bottom: 16,
                  child: SizedBox(
                    width: double.infinity,
                    child: TransitButton(
                      label: isFavorite
                          ? 'EN MIS LÍNEAS ✓'
                          : 'AÑADIR A MIS LÍNEAS ★',
                      isPrimary: true,
                      onPressed: isFavorite ? null : () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
