import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/geo/geo_providers.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/derived/home_providers.dart';
import '../../../shared/providers/home_habitual_config_provider.dart';
import '../../../shared/providers/home_reference_stop_provider.dart';
import '../../../shared/providers/user_favorites_provider.dart';
import '../../../shared/providers/user_location_provider.dart';
import '../../../shared/providers/route_lookup_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/stagger_list.dart';
import '../../../shared/widgets/route_card.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_chip.dart';
import '../widgets/home_alert_item.dart';
import '../widgets/habitual_config_sheet.dart';
import '../widgets/reference_stop_picker_sheet.dart';

const _nearbyCount = 3;

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
          ref.invalidate(mockDataServiceProvider);
          ref.invalidate(realtimeTripsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        color: c.accent,
        child: _buildContent(context, c, mockData, activeTripsMap),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransitColorScheme c,
      MockDataService mockData, Map<String, ActiveTripModel> activeTripsMap) {
    final l10n = AppLocalizations.of(context);
    final padding = ResponsiveScaffold.screenPadding(context);

    // ── T5: Viaje habitual configurable ──
    final habitualConfig = ref.watch(homeHabitualConfigProvider);

    // ── T6: Paradas cerca con GPS + fallback ──
    final userLoc = ref.watch(userLocationStreamProvider).valueOrNull;
    final refStopId = ref.watch(homeReferenceStopProvider);
    final refStop =
        refStopId != null ? mockData.getStopById(refStopId) : null;
    final center = userLoc ??
        (refStop != null ? LatLng(refStop.lat, refStop.lng) : null);

    List<StopModel> nearbyStops;
    Map<String, double> nearbyDistances;
    if (center != null) {
      final raw = mockData.stops
          .map((s) => (
                stop: s,
                dist: const Distance().as(
                    LengthUnit.Meter, center, LatLng(s.lat, s.lng)),
              ))
          .toList()
        ..sort((a, b) => a.dist.compareTo(b.dist));
      nearbyStops = raw.take(_nearbyCount).map((e) => e.stop).toList();
      nearbyDistances = {
        for (final e in raw.take(_nearbyCount)) e.stop.id: e.dist,
      };
    } else {
      nearbyStops = [];
      nearbyDistances = {};
    }

    // ── T7: Mis líneas desde favoritos reales ──
    final favLineIds = ref.watch(userFavoritesProvider);
    final favRoutes = favLineIds
        .map((id) => mockData.getRouteById(id))
        .whereType<RouteModel>()
        .toList();

    // ── T9: Mis paradas desde favoritos reales ──
    final favStopIds = ref.watch(userFavoriteStopsProvider);
    final favStops = favStopIds
        .map((id) => mockData.getStopById(id))
        .whereType<StopModel>()
        .toList();

    final favAlerts = ref.watch(homeFavAlertsProvider);

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
              Semantics(
                header: true,
                label: l10n.appTitle,
                child: Text(
                  l10n.appTitle.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: c.textHi,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: l10n.homeChangeCityTooltip,
                child: GestureDetector(
                  onTap: () => context.push('/city-picker'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          ref.watch(activeOperatorProvider)?.name ??
                              l10n.homeDefaultCity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8888A8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 18, color: c.textMid),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 1) VIAJE HABITUAL ──
              if (habitualConfig.isConfigured) ...[
                _buildHabitualTripConfigured(
                    c, mockData, habitualConfig),
                const SizedBox(height: 28),
              ] else ...[
                _sectionTitle(c, l10n.homeSectionHabitualTrip),
                const SizedBox(height: 8),
                _buildConfigureHabitualCTA(c, l10n),
                const SizedBox(height: 28),
              ],

              // ── 2) PARADAS CERCANAS ──
              _sectionTitle(c, l10n.homeSectionNearbyStops),
              const SizedBox(height: 10),
              if (center == null) ...[
                _buildPickReferenceCTA(c, l10n),
              ] else if (nearbyStops.isNotEmpty)
                StaggerList(
                  children: nearbyStops.map((stop) {
                    final dist = nearbyDistances[stop.id];
                    return _buildNearbyStop(
                        context, c, mockData, stop, dist);
                  }).toList(),
                )
              else
                EmptyState(
                  l10n.homeNoNearbyStops,
                  l10n.homeNoNearbyStopsHint,
                  icon: Icons.location_off_outlined,
                ),
              const SizedBox(height: 28),

              // ── 3) MIS LINEAS ──
              _sectionTitle(c, l10n.homeSectionMyLines),
              const SizedBox(height: 10),
              if (favRoutes.isNotEmpty)
                StaggerList(
                  children: favRoutes.map((route) {
                    final trip = activeTripsMap[route.id] ??
                        mockData.getActiveTripForRoute(route.id);
                    final stopsForRoute =
                        mockData.getStopsForRoute(route.id);
                    final next =
                        mockData.getNextDepartures(route.id, '', 1);
                    final mins = next.isNotEmpty
                        ? _minutesUntil(next.first.departureTime)
                        : null;
                    final minsStr =
                        mins != null ? '${mins}m' : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RouteCard(
                        route: route,
                        activeTrip: trip,
                        remainingStops: stopsForRoute.length,
                        estimatedMinutes: minsStr,
                        onTap: () =>
                            context.push('/route/${route.id}'),
                      ),
                    );
                  }).toList(),
                )
              else
                EmptyState(
                  l10n.homeNoFavorites,
                  l10n.homeMarkLineFavoriteCTA,
                  icon: Icons.star_border_outlined,
                ),

              // ── 4) MIS PARADAS ──
              if (favStops.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(c, l10n.homeMyStops),
                const SizedBox(height: 10),
                StaggerList(
                  children: favStops.map((stop) {
                    final routesAtStop =
                        mockData.routeStops.entries
                            .where((e) => e.value
                                .any((rs) => rs.stopId == stop.id))
                            .map((e) => e.key)
                            .toList();
                    String? nextBusStr;
                    for (final rid in routesAtStop) {
                      final dep = mockData.getNextDepartures(
                          rid, stop.id, 1);
                      if (dep.isNotEmpty) {
                        final mins =
                            _minutesUntil(dep.first.departureTime);
                        if (mins != null) {
                          nextBusStr =
                              l10n.homeNextBus('$mins');
                          break;
                        }
                      }
                    }
                    return _buildFavoriteStopCard(
                        c, mockData, stop, routesAtStop,
                        nextBusStr ?? l10n.homeNoUpcomingDepartures);
                  }).toList(),
                ),
              ],

              // ── 5) AVISOS ──
              if (favAlerts.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle(c, l10n.homeSectionAlerts),
                const SizedBox(height: 10),
                StaggerList(
                  children: favAlerts
                      .map((alert) =>
                          HomeAlertItem(c: c, alert: alert))
                      .toList(),
                ),
              ],

              // ── 6) ACCESIBLE BUSES LINK ──
              const SizedBox(height: 28),
              _sectionTitle(
                  c, l10n.profileSectionAccessibility),
              const SizedBox(height: 10),
              Semantics(
                label: l10n.accessibleBusesLinkLabel,
                child: GlassCard(
                  blur: 16,
                  fillOpacity: 0.05,
                  borderRadius: 12,
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.list_alt,
                        size: 24, color: c.accent),
                    title: Text(
                      l10n.accessibleBusesLinkLabel,
                      style: TransitTypography.bodyPrimary(
                          c.textHi),
                    ),
                    subtitle: Text(
                      l10n.accessibleBusesEmpty,
                      style: TransitTypography.bodySecondary(
                          c.textMid),
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: c.textMid),
                    onTap: () =>
                        context.push('/accessible-buses'),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  // ── T5: Viaje habitual desde provider ──
  Widget _buildHabitualTripConfigured(
    TransitColorScheme c,
    MockDataService mockData,
    HomeHabitualConfig cfg,
  ) {
    final l10n = AppLocalizations.of(context);
    final route = mockData.getRouteById(cfg.routeId!);
    if (route == null) return const SizedBox.shrink();
    final stop = mockData.getStopById(cfg.stopId!);
    final stopsForRoute = mockData.getStopsForRoute(route.id);
    final dest =
        stopsForRoute.length > 1 ? stopsForRoute.last : null;
    final next =
        mockData.getNextDepartures(route.id, cfg.stopId!, 1);
    final nextTime =
        next.isNotEmpty ? next.first.departureTime : '--:--';
    final mins = next.isNotEmpty
        ? _minutesUntil(next.first.departureTime)
        : null;

    return Semantics(
      button: true,
      label: l10n.homeNextBusSemantics(route.code),
      child: GestureDetector(
        onTap: () => context.push('/route/${route.id}'),
        child: GlassCard(
          blur: 28,
          fillOpacity: 0.10,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeSectionNextBus,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: c.accent,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showHabitualConfigSheet(
                        context, ref),
                    child: Icon(Icons.tune,
                        size: 18, color: c.textMid),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${route.code} · ${stop?.name ?? 'Parada'} → ${dest?.name ?? 'Destino'}',
                style: TransitTypography.bodyPrimary(c.textHi),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(nextTime,
                      style:
                          TransitTypography.stopTime(c.textMid)),
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
                    label: l10n.actionFollow,
                    isSmall: true,
                    onPressed: () =>
                        context.push('/route/${route.id}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── T5: CTA configurar viaje habitual ──
  Widget _buildConfigureHabitualCTA(
      TransitColorScheme c, AppLocalizations l10n) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.tune, size: 24, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeConfigureHabitualCTA,
                  style:
                      TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeConfigureHabitualCTAHint,
                  style: TransitTypography.bodySmall(c.textMid),
                ),
              ],
            ),
          ),
          TransitButton(
            label: l10n.homeConfigureHabitualAction,
            isSmall: true,
            isPrimary: false,
            onPressed: () =>
                showHabitualConfigSheet(context, ref),
          ),
        ],
      ),
    );
  }

  // ── T6: CTA elegir parada de referencia ──
  Widget _buildPickReferenceCTA(
      TransitColorScheme c, AppLocalizations l10n) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.location_searching,
              size: 24, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homePickReferenceCTA,
                  style:
                      TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homePickReferenceCTAHint,
                  style: TransitTypography.bodySmall(c.textMid),
                ),
              ],
            ),
          ),
          TransitButton(
            label: l10n.homePickReferenceAction,
            isSmall: true,
            isPrimary: false,
            onPressed: () =>
                showReferenceStopPickerSheet(context, ref),
          ),
        ],
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

  // ── T6: Parada cercana con distancia ──
  Widget _buildNearbyStop(BuildContext context, TransitColorScheme c,
      MockDataService mockData, StopModel stop, double? distanceMeters) {
    final l10n = AppLocalizations.of(context);
    final stopToRoutes = ref.watch(stopToRouteCodesProvider);
    final routesAtStop = stopToRoutes[stop.id] ?? const <String>[];
    final distStr = distanceMeters != null
        ? l10n.homeNearbyDistance('${distanceMeters.toInt()}')
        : null;

    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stop.name,
                    style:
                        TransitTypography.bodyPrimary(c.textHi)),
              ),
              if (distStr != null)
                Text(distStr,
                    style:
                        TransitTypography.bodySmall(c.accent)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: routesAtStop.take(4).map((routeId) {
              final route = mockData.getRouteById(routeId);
              if (route == null) return const SizedBox.shrink();
              final next =
                  mockData.getNextDepartures(routeId, stop.id, 1);
              final time = next.isNotEmpty
                  ? next.first.departureTime
                  : '--:--';
              final mins = next.isNotEmpty
                  ? _minutesUntil(next.first.departureTime)
                  : null;

              return Semantics(
                button: true,
                label: l10n.homeRouteSemanticsLabel(
                    route.code, time),
                child: GestureDetector(
                  onTap: () =>
                      context.push('/route/$routeId'),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TransitChip(route.code,
                            color: route.routeColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            route.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TransitTypography.bodySmall(
                                c.textMid),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(time,
                            style: TransitTypography.stopTime(
                                c.textHi)),
                        if (mins != null) ...[
                          const SizedBox(width: 4),
                          AnimatedSwitcher(
                            duration: const Duration(
                                milliseconds: 200),
                            child: Text(
                              '${mins}m',
                              key: ValueKey(
                                  '$routeId-$mins'),
                              style:
                                  TransitTypography.bodySmall(
                                      c.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── T9: Card de parada favorita ──
  Widget _buildFavoriteStopCard(
    TransitColorScheme c,
    MockDataService mockData,
    StopModel stop,
    List<String> routeIdsAtStop,
    String nextBusLabel,
  ) {
    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stop.name,
                    style:
                        TransitTypography.bodyPrimary(c.textHi)),
              ),
              Text(nextBusLabel,
                  style: TransitTypography.bodySmall(
                      c.accent)),
            ],
          ),
          if (routeIdsAtStop.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routeIdsAtStop.take(4).map((rid) {
                final route = mockData.getRouteById(rid);
                if (route == null) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => context.push('/route/$rid'),
                  child: TransitChip(route.code,
                      color: route.routeColor),
                );
              }).toList(),
            ),
          ],
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
