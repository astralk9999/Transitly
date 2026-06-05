import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../core/map/map_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/home_reference_stop_provider.dart';
import '../../shared/providers/user_location_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_chip.dart';

class NearbyBusesScreen extends ConsumerStatefulWidget {
  const NearbyBusesScreen({super.key});

  @override
  ConsumerState<NearbyBusesScreen> createState() =>
      _NearbyBusesScreenState();
}

class _NearbyBusesScreenState
    extends ConsumerState<NearbyBusesScreen> {
  List<ActiveTripModel> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final mockData = ref.read(mockDataServiceProvider);
      final allTrips = mockData.activeTrips
          .where((t) =>
              t.status != TripStatus.cancelled &&
              t.status != TripStatus.completed)
          .toList();

      final center = _computeCenter(mockData);
      const maxDistanceM = 5000.0;

      final filtered = allTrips.where((trip) {
        if (center == null) return true;
        final tripLoc = _tripLocation(mockData, trip);
        if (tripLoc == null) return false;
        final dist = const Distance().as(
          LengthUnit.Meter,
          center,
          tripLoc,
        );
        return dist <= maxDistanceM;
      }).toList();

      setState(() {
        _trips = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  LatLng? _computeCenter(MockDataService mockData) {
    final userLoc = ref.read(userLocationLatLngProvider);
    if (userLoc != null) return userLoc;

    final refStopId = ref.read(homeReferenceStopProvider);
    if (refStopId != null) {
      final stop = mockData.getStopById(refStopId);
      if (stop != null) return LatLng(stop.lat, stop.lng);
    }

    return MapConfig.defaultCenter;
  }

  LatLng? _tripLocation(MockDataService mockData, ActiveTripModel trip) {
    if (trip.currentLat != null && trip.currentLng != null) {
      return LatLng(trip.currentLat!, trip.currentLng!);
    }
    final stops = mockData.getStopsForRoute(trip.routeId);
    final first = stops.firstOrNull;
    if (first != null) return LatLng(first.lat, first.lng);
    return null;
  }

  String _sourceLabel(AppLocalizations l10n, ActiveTripModel trip) {
    if (trip.driverId != null) return l10n.nearbyBusesSourceDriver;
    return l10n.nearbyBusesSourceEstimated;
  }

  String? _nextStopName(MockDataService mockData, ActiveTripModel trip) {
    final stops = mockData.getStopsForRoute(trip.routeId);
    if (stops.isEmpty) return null;
    final idx = trip.currentStopIndex;
    if (idx != null && idx >= 0 && idx < stops.length) return stops[idx].name;
    return stops.firstOrNull?.name;
  }

  int? _minutesUntil(MockDataService mockData, ActiveTripModel trip) {
    final next = mockData.getNextDepartures(trip.routeId, '', 1);
    final departureTime = next.firstOrNull?.departureTime;
    if (departureTime == null) return null;
    final parts = departureTime.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    final mins = (h * 60 + m) - (now.hour * 60 + now.minute);
    return mins > 0 ? mins : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          Column(
            children: [
              TransitAppBar(title: l10n.nearbyBusesTitle),
              Expanded(child: _buildContent(c, l10n)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c, AppLocalizations l10n) {
    if (_loading) {
      return ShimmerSkeleton.list(
        context: context,
        count: 4,
        builder: () => ShimmerSkeleton.routeCard(context),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(l10n.nearbyBusesError, onRetry: _loadBuses),
        ),
      );
    }

    if (_trips.isEmpty) {
      return EmptyState(
        l10n.nearbyBusesEmptyTitle,
        l10n.nearbyBusesEmptySubtitle,
        icon: Icons.directions_bus_outlined,
      );
    }

    final mockData = ref.watch(mockDataServiceProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        final route = mockData.getRouteById(trip.routeId);
        final stopName = _nextStopName(mockData, trip);
        final mins = _minutesUntil(mockData, trip);
        final source = _sourceLabel(l10n, trip);
        final routeCode = route?.code ?? trip.routeId;
        final routeName = route?.name ?? '';

        final semanticsParts = <String>[
          routeCode,
          if (routeName.isNotEmpty) routeName,
          '${l10n.nearbyBusesNextStop}: ${stopName ?? '?'}',
          if (mins != null) '$mins min' else '--',
          source,
        ];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _trips.length - 1 ? 8 : 0,
          ),
          child: Semantics(
            button: true,
            label: semanticsParts.join(', '),
            child: GestureDetector(
              onTap: () => context.push('/route/${trip.routeId}'),
              child: GlassCard(
                blur: 12,
                fillOpacity: 0.05,
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: c.accent.withValues(alpha: 0.12),
                    child: FittedBox(
                      child: Text(
                        routeCode.isNotEmpty ? routeCode : '?',
                        maxLines: 1,
                        style: GoogleFonts.ibmPlexMono(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    routeName.isNotEmpty ? routeName : routeCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                  subtitle: stopName != null
                      ? Text(
                          '${l10n.nearbyBusesNextStop}: $stopName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TransitTypography.bodySecondary(c.textMid),
                        )
                      : null,
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          mins != null ? '$mins min' : '--',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TransitTypography.stopTime(c.textHi),
                        ),
                        const SizedBox(height: 4),
                        TransitChip(source, color: c.textLo),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
