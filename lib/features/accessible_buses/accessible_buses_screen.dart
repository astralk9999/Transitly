import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_chip.dart';

class AccessibleBusesScreen extends ConsumerStatefulWidget {
  const AccessibleBusesScreen({super.key});

  @override
  ConsumerState<AccessibleBusesScreen> createState() =>
      _AccessibleBusesScreenState();
}

class _AccessibleBusesScreenState
    extends ConsumerState<AccessibleBusesScreen> {
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
      final active = mockData.activeTrips
          .where((t) =>
              t.status != TripStatus.cancelled &&
              t.status != TripStatus.completed)
          .toList();
      setState(() {
        _trips = active;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _sourceLabel(AppLocalizations l10n, ActiveTripModel trip) {
    if (trip.driverId != null) return l10n.accessibleBusesSourceDriver;
    return l10n.accessibleBusesSourceEstimated;
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
              TransitAppBar(title: l10n.accessibleBusesTitle),
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
          child: ErrorCard(l10n.accessibleBusesError, onRetry: _loadBuses),
        ),
      );
    }

    if (_trips.isEmpty) {
      return EmptyState(
        l10n.accessibleBusesEmpty,
        l10n.accessibleBusesNoActiveBuses,
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
          '${l10n.accessibleBusesNextStop}: ${stopName ?? '?'}',
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
                          '${l10n.accessibleBusesNextStop}: $stopName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TransitTypography.bodySecondary(c.textMid),
                        )
                      : null,
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Column(
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
