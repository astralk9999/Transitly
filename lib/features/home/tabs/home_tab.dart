import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/route_card.dart';
import '../../../shared/widgets/stagger_list.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_chip.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final realtimeTrips = ref.watch(realtimeTripsProvider);
    ref.watch(realtimeClockProvider);

    final activeTripsMap = <String, ActiveTripModel>{};
    final tripsList = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    for (final t in tripsList) {
      activeTripsMap[t.routeId] = t;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: c.accent,
        child: _buildContent(context, c, mockData, activeTripsMap),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransitColorScheme c,
      MockDataService mockData, Map<String, ActiveTripModel> activeTripsMap) {
    final favorites = mockData.favorites;
    final favRouteIds = favorites.map((f) => f.routeId).toSet();
    final padding = ResponsiveScaffold.screenPadding(context);

    final habitualFav = favorites.isNotEmpty ? favorites.first : null;
    final habitualRoute =
        habitualFav != null ? mockData.getRouteById(habitualFav.routeId) : null;
    final habitualStop = habitualFav?.homeStopId != null
        ? mockData.getStopById(habitualFav!.homeStopId!)
        : null;
    final habitualStops = habitualRoute != null
        ? mockData.getStopsForRoute(habitualRoute.id)
        : <StopModel>[];
    final habitualDest =
        habitualStops.length > 1 ? habitualStops.last : null;
    final habitualNext = habitualRoute != null
        ? mockData.getNextDepartures(habitualRoute.id, '', 1)
        : <ScheduleModel>[];

    const jerezLat = 36.6850;
    const jerezLng = -6.1261;
    final nearbyStops = mockData.getNearbyStops(jerezLat, jerezLng, 3);

    final favAlerts = <AlertModel>[];
    for (final routeId in favRouteIds) {
      favAlerts.addAll(mockData.getAlertsForRoute(routeId));
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      key: const ValueKey('content'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: topPadding + 24,
            bottom: 16,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Header ──
              Text(
                'TRANSITLY',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: c.textHi,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jerez de la Frontera',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: c.textMid,
                ),
              ),
              const SizedBox(height: 24),
              // ── 1) VIAJE HABITUAL ──
              if (habitualRoute != null)
                _buildHabitualTrip(
                    c, habitualRoute, habitualStop, habitualDest, habitualNext),
              if (habitualRoute != null) const SizedBox(height: 28),

              // ── 2) PARADAS CERCANAS ──
              _sectionTitle(c, 'PARADAS CERCA DE TI'),
              const SizedBox(height: 10),
              StaggerList(
                children: nearbyStops
                    .map((stop) =>
                        _buildNearbyStop(context, c, mockData, stop))
                    .toList(),
              ),
              const SizedBox(height: 28),

              // ── 3) MIS LINEAS ──
              _sectionTitle(c, 'MIS LINEAS'),
              const SizedBox(height: 10),
              StaggerList(
                children: favorites.map((fav) {
                  final route = mockData.getRouteById(fav.routeId);
                  if (route == null) return const SizedBox.shrink();
                  final trip = activeTripsMap[route.id] ??
                      mockData.getActiveTripForRoute(route.id);
                  final stopsForRoute = mockData.getStopsForRoute(route.id);
                  final next = mockData.getNextDepartures(route.id, '', 1);
                  final mins = next.isNotEmpty
                      ? _minutesUntil(next.first.departureTime)
                      : null;
                  final minsStr = mins != null ? '${mins}m' : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RouteCard(
                      route: route,
                      activeTrip: trip,
                      remainingStops: stopsForRoute.length,
                      estimatedMinutes: minsStr,
                      onTap: () => context.push('/route/${route.id}'),
                    ),
                  );
                }).toList(),
              ),

              // ── 4) AVISOS ──
              if (favAlerts.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(c, 'AVISOS'),
                const SizedBox(height: 10),
                StaggerList(
                  children: favAlerts
                      .map((alert) => _buildAlertItem(c, alert))
                      .toList(),
                ),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitualTrip(
    TransitColorScheme c,
    RouteModel route,
    StopModel? stop,
    StopModel? dest,
    List<ScheduleModel> next,
  ) {
    final nextTime = next.isNotEmpty ? next.first.departureTime : '--:--';
    final mins =
        next.isNotEmpty ? _minutesUntil(next.first.departureTime) : null;

    return GestureDetector(
      onTap: () => context.push('/route/${route.id}'),
      child: GlassCard(
        blur: 28,
        fillOpacity: 0.10,
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TU PROXIMO BUS',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: c.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${route.code} \u00B7 ${stop?.name ?? 'Parada'} \u2192 ${dest?.name ?? 'Destino'}',
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(nextTime,
                    style: TransitTypography.stopTime(c.textMid)),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    mins != null ? 'en ${mins}m' : '--',
                    key: ValueKey(mins),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
                const Spacer(),
                TransitButton(
                  label: 'SEGUIR',
                  isSmall: true,
                  onPressed: () => context.push('/route/${route.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(TransitColorScheme c, String text) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: c.textMid,
        ),
      ),
    );
  }

  Widget _buildNearbyStop(BuildContext context, TransitColorScheme c,
      MockDataService mockData, StopModel stop) {
    final routesAtStop = <String>[];
    for (final entry in mockData.routeStops.entries) {
      for (final rs in entry.value) {
        if (rs.stopId == stop.id) {
          routesAtStop.add(entry.key);
          break;
        }
      }
    }

    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stop.name, style: TransitTypography.bodyPrimary(c.textHi)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: routesAtStop.take(4).map((routeId) {
              final route = mockData.getRouteById(routeId);
              if (route == null) return const SizedBox.shrink();
              final next = mockData.getNextDepartures(routeId, stop.id, 1);
              final time =
                  next.isNotEmpty ? next.first.departureTime : '--:--';
              final mins = next.isNotEmpty
                  ? _minutesUntil(next.first.departureTime)
                  : null;

              return GestureDetector(
                onTap: () => context.push('/route/$routeId'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TransitChip(route.code, color: route.routeColor),
                    const SizedBox(width: 4),
                    Text(time,
                        style: TransitTypography.stopTime(c.textHi)),
                    if (mins != null) ...[
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '${mins}m',
                          key: ValueKey('$routeId-$mins'),
                          style: TransitTypography.bodySmall(c.accent),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.notifications_none, size: 14, color: c.textLo),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(TransitColorScheme c, AlertModel alert) {
    final Color severityColor;
    switch (alert.severity) {
      case AlertSeverity.info:
        severityColor = c.neonBlue;
      case AlertSeverity.warning:
        severityColor = c.stateDelay;
      case AlertSeverity.critical:
        severityColor = c.stateCancelled;
    }

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 12,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.title,
              style: TransitTypography.bodySecondary(c.textHi),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  int? _minutesUntil(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    final mins = (h * 60 + m) - (now.hour * 60 + now.minute);
    return mins > 0 ? mins : null;
  }
}
