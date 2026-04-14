import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/route_card.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_chip.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? _buildShimmer(context)
            : _buildContent(context, c, mockData),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return CustomScrollView(
      key: const ValueKey('shimmer'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ShimmerSkeleton.routeCard(context),
              const SizedBox(height: 16),
              ShimmerSkeleton.text(context, width: 180),
              const SizedBox(height: 8),
              ShimmerSkeleton.list(
                context: context,
                count: 3,
                builder: () => ShimmerSkeleton.stopItem(context),
              ),
              const SizedBox(height: 24),
              ShimmerSkeleton.text(context, width: 120),
              const SizedBox(height: 8),
              ShimmerSkeleton.routeCard(context),
              const SizedBox(height: 8),
              ShimmerSkeleton.routeCard(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, TransitColorScheme c, MockDataService mockData) {
    final favorites = mockData.favorites;
    final favRouteIds = favorites.map((f) => f.routeId).toSet();

    // Simulated habitual trip from first favorite
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

    // Nearby stops
    const jerezLat = 36.6850;
    const jerezLng = -6.1261;
    final nearbyStops = mockData.getNearbyStops(jerezLat, jerezLng, 3);

    // Alerts for favorite routes
    final favAlerts = <AlertModel>[];
    for (final routeId in favRouteIds) {
      favAlerts.addAll(mockData.getAlertsForRoute(routeId));
    }

    return CustomScrollView(
      key: const ValueKey('content'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── 1) VIAJE HABITUAL ──
              if (habitualRoute != null)
                _buildHabitualTrip(
                    c, habitualRoute, habitualStop, habitualDest, habitualNext),
              if (habitualRoute != null) const SizedBox(height: 24),

              // ── 2) PARADAS CERCANAS ──
              _buildSectionTitle(c, 'PARADAS CERCA DE TI'),
              const SizedBox(height: 8),
              ...nearbyStops.map((stop) =>
                  _buildNearbyStop(context, c, mockData, stop)),
              const SizedBox(height: 24),

              // ── 3) MIS LÍNEAS ──
              _buildMyLinesHeader(c, favorites.length),
              const SizedBox(height: 8),
              ...favorites.map((fav) {
                final route = mockData.getRouteById(fav.routeId);
                if (route == null) return const SizedBox.shrink();
                final trip = mockData.getActiveTripForRoute(route.id);
                final stopsForRoute = mockData.getStopsForRoute(route.id);
                final next =
                    mockData.getNextDepartures(route.id, '', 1);
                final mins = next.isNotEmpty ? _minutesUntil(next.first.departureTime) : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RouteCard(
                    route: route,
                    activeTrip: trip,
                    remainingStops: stopsForRoute.length,
                    estimatedMinutes: mins != null ? '${mins}m' : null,
                    onTap: () => context.push('/route/${route.id}'),
                  ),
                );
              }),

              // ── 4) AVISOS ──
              if (favAlerts.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(c, 'AVISOS'),
                const SizedBox(height: 8),
                ...favAlerts.map((alert) => _buildAlertItem(c, alert)),
              ],
              const SizedBox(height: 32),
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
    final mins = next.isNotEmpty ? _minutesUntil(next.first.departureTime) : null;

    return GestureDetector(
      onTap: () => context.push('/route/${route.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: c.accent, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TU PRÓXIMO BUS',
              style: TransitTypography.sectionTitle(c.accent),
            ),
            const SizedBox(height: 8),
            Text(
              '${route.code} · ${stop?.name ?? 'Parada'} → ${dest?.name ?? 'Destino'}',
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(nextTime, style: TransitTypography.stopTime(c.textMid)),
                const SizedBox(width: 12),
                Text(
                  mins != null ? 'en ${mins}m' : '--',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
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

  Widget _buildSectionTitle(TransitColorScheme c, String text) {
    return Text(text, style: TransitTypography.sectionTitle(c.textMid));
  }

  Widget _buildMyLinesHeader(TransitColorScheme c, int count) {
    return Row(
      children: [
        Text('MIS LÍNEAS', style: TransitTypography.sectionTitle(c.textMid)),
        const SizedBox(width: 8),
        Text(
          '($count líneas)',
          style: TransitTypography.bodySmall(c.textLo),
        ),
      ],
    );
  }

  Widget _buildNearbyStop(BuildContext context, TransitColorScheme c,
      MockDataService mockData, StopModel stop) {
    // Find routes that pass through this stop
    final routesAtStop = <String>[];
    for (final entry in mockData.routeStops.entries) {
      for (final rs in entry.value) {
        if (rs.stopId == stop.id) {
          routesAtStop.add(entry.key);
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stop.name, style: TransitTypography.bodyPrimary(c.textHi)),
          const SizedBox(height: 6),
          // Arrivals per route
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: routesAtStop.take(4).map((routeId) {
              final route = mockData.getRouteById(routeId);
              if (route == null) return const SizedBox.shrink();
              final next = mockData.getNextDepartures(routeId, stop.id, 1);
              final time =
                  next.isNotEmpty ? next.first.departureTime : '--:--';
              final mins =
                  next.isNotEmpty ? _minutesUntil(next.first.departureTime) : null;

              return GestureDetector(
                onTap: () => context.push('/route/$routeId'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TransitChip(route.code, color: route.routeColor),
                    const SizedBox(width: 4),
                    Text(time, style: TransitTypography.stopTime(c.textHi)),
                    if (mins != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${mins}m',
                        style: TransitTypography.bodySmall(c.accent),
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
        severityColor = c.stateOnRoute;
      case AlertSeverity.warning:
        severityColor = c.stateDelay;
      case AlertSeverity.critical:
        severityColor = c.stateCancelled;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(width: 2, height: 32, color: severityColor),
          const SizedBox(width: 10),
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
