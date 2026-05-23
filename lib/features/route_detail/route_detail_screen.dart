import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/analytics/posthog_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/transit_colors.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/mock/mock_realtime_service.dart';
import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_stop_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/derived/schedule_providers.dart';
import '../../shared/providers/route_lookup_providers.dart';
import '../../shared/providers/user_favorites_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/route_detail_alerts_list.dart';
import 'widgets/route_detail_changelog.dart';
import 'widgets/route_detail_feedback_section.dart';
import 'widgets/route_detail_header_section.dart';
import 'widgets/route_detail_schedule_section.dart';
import 'widgets/route_detail_timeline.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

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
        body: Center(child: Text(AppLocalizations.of(context).routeDetailNotFound)),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PostHogAnalyticsService.routeViewed(route.id, route.operatorId);
    });

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
    final favorites = ref.watch(userFavoritesProvider);
    final isFavorite = favorites.contains(routeId);

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

    final frequency = ref.watch(routeFrequencyProvider(routeId));

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
                          RouteDetailHeaderSection(
                            route: route,
                            activeTrip: activeTrip,
                            stopsCount: stopsForRoute.length,
                            estimatedMinutes: estimatedMinutes,
                            frequencyMinutes: frequency,
                            onPop: () => context.pop(),
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
                          ? AppLocalizations.of(context).routeDetailRemoveFavorite
                          : AppLocalizations.of(context).routeDetailAddFavorite,
                      isPrimary: !isFavorite,
                      onPressed: () async {
                        final notifier = ref.read(userFavoritesProvider.notifier);
                        if (isFavorite) {
                          await notifier.removeLine(routeId);
                        } else {
                          await notifier.addLine(routeId);
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFavorite
                                ? AppLocalizations.of(context).favoriteRemoved
                                : AppLocalizations.of(context).favoriteAdded),
                          ),
                        );
                      },
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
