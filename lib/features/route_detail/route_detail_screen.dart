import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/mock/mock_realtime_service.dart';
import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_stop_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/widgets/data_freshness_indicator.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/stop_list_item.dart';
import '../../shared/widgets/transit_button.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  DayType _selectedDayType = DayType.weekday;
  bool _showAllSchedules = false;
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
    final realtimeTrips = ref.watch(realtimeTripsProvider);
    // Watch clock for countdown refresh
    ref.watch(realtimeClockProvider);
    final route = mockData.getRouteById(widget.routeId);

    if (route == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Ruta no encontrada')),
      );
    }

    // Use realtime trip if available
    final tripsList = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    ActiveTripModel? activeTrip;
    for (final t in tripsList) {
      if (t.routeId == widget.routeId && t.status != TripStatus.cancelled) {
        activeTrip = t;
        break;
      }
    }
    final routeStopsList = mockData.routeStops[widget.routeId] ?? [];
    final sortedRouteStops = List<RouteStopModel>.from(routeStopsList)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final stopsForRoute = mockData.getStopsForRoute(widget.routeId);
    final stopsMap = <String, StopModel>{};
    for (final s in mockData.stops) {
      stopsMap[s.id] = s;
    }
    final alerts = mockData.getAlertsForRoute(widget.routeId);
    final isFavorite =
        mockData.favorites.any((f) => f.routeId == widget.routeId);

    // Transfers: for each stop, find other routes passing through it
    final transfers = <String, List<String>>{};
    for (final rs in sortedRouteStops) {
      final otherRoutes = <String>[];
      for (final entry in mockData.routeStops.entries) {
        if (entry.key == widget.routeId) continue;
        if (entry.value.any((r) => r.stopId == rs.stopId)) {
          final otherRoute = mockData.getRouteById(entry.key);
          if (otherRoute != null) otherRoutes.add(otherRoute.code);
        }
      }
      if (otherRoutes.isNotEmpty) transfers[rs.stopId] = otherRoutes;
    }

    // Time estimate from last stop
    final lastTimeMinutes = sortedRouteStops.isNotEmpty
        ? sortedRouteStops.last.timeFromStartMinutes
        : null;
    final estimatedMinutes = lastTimeMinutes ?? (stopsForRoute.length * 3);

    // Average frequency from weekday schedules
    final weekdaySchedules =
        mockData.getSchedulesForRoute(widget.routeId, dayType: DayType.weekday);
    final frequency = _calcFrequency(weekdaySchedules);

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back, size: 24, color: c.textMid),
              ),
              const SizedBox(height: 16),
              ShimmerSkeleton.rect(context, height: 60),
              const SizedBox(height: 16),
              ShimmerSkeleton.text(context, width: 200),
              const SizedBox(height: 24),
              ShimmerSkeleton.list(
                context: context,
                count: 5,
                builder: () => ShimmerSkeleton.stopItem(context),
              ),
              const SizedBox(height: 24),
              ShimmerSkeleton.text(context, width: 140),
              const SizedBox(height: 8),
              ShimmerSkeleton.rect(context, height: 40),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 48),

                    // ── BACK BUTTON ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(Icons.arrow_back,
                            size: 24, color: c.textMid),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 1. HEADER ──
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.bgRaised,
                            border:
                                Border.all(color: route.routeColor, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              route.code,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: route.routeColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: c.textHi,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'COMUJESA',
                                style: TransitTypography.subheading(c.textMid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (activeTrip != null)
                          StatusBadge(
                            activeTrip.status.label,
                            _tripStatusColor(c, activeTrip.status),
                          ),
                        StatusBadge(route.status.label, c.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DataFreshnessIndicator(
                      DateTime.now().subtract(const Duration(days: 2)),
                    ),

                    Divider(height: 32, thickness: 0.5, color: c.border),

                    // ── 2. INFO RÁPIDA ──
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _infoCell(
                              c,
                              '${stopsForRoute.length}',
                              'paradas',
                            ),
                          ),
                          Container(
                              width: 1, height: 24, color: c.border),
                          Expanded(
                            child: _infoCell(
                              c,
                              '~$estimatedMinutes',
                              'min',
                            ),
                          ),
                          Container(
                              width: 1, height: 24, color: c.border),
                          Expanded(
                            child: _infoCell(
                              c,
                              frequency != null ? 'Cada $frequency' : '--',
                              'min',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. ALERTAS ──
                    if (alerts.isNotEmpty) ...[
                      ...alerts.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.bgSurface,
                                border: Border(
                                  left: BorderSide(
                                    color: _severityColor(c, alert.severity),
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.title,
                                      style: TransitTypography.bodyPrimary(
                                          c.textHi)),
                                  const SizedBox(height: 4),
                                  Text(alert.body,
                                      style: TransitTypography.bodySecondary(
                                          c.textMid)),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── 4. RECORRIDO ──
                    Text('RECORRIDO',
                        style: TransitTypography.sectionTitle(c.textMid)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: sortedRouteStops.length * 60.0,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedRouteStops.length,
                        itemBuilder: (context, index) {
                          final rs = sortedRouteStops[index];
                          final stop = stopsMap[rs.stopId];
                          if (stop == null) return const SizedBox.shrink();

                          final bool isCurrent = activeTrip?.currentStopIndex !=
                                  null &&
                              index == activeTrip!.currentStopIndex;
                          final bool isPassed =
                              activeTrip?.currentStopIndex != null &&
                                  index < activeTrip!.currentStopIndex!;

                          return StopListItem(
                            stop: stop,
                            scheduledTime: rs.timeFromStartMinutes != null
                                ? '+${rs.timeFromStartMinutes}m'
                                : '--:--',
                            isCurrent: isCurrent,
                            isPassed: isPassed,
                            isFirst: index == 0,
                            isLast: index == sortedRouteStops.length - 1,
                            transferLines: transfers[rs.stopId],
                            onTap: () =>
                                context.push('/stop/${stop.id}'),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 5. HORARIOS ──
                    _buildScheduleSection(c, mockData),

                    const SizedBox(height: 24),

                    // ── 6. CAMBIOS RECIENTES ──
                    Text('CAMBIOS RECIENTES',
                        style: TransitTypography.sectionTitle(c.textMid)),
                    const SizedBox(height: 8),
                    _changelogItem(c, Icons.edit, '12/03',
                        'Horario actualizado para días laborables'),
                    _changelogItem(c, Icons.add_location, '28/02',
                        'Añadida parada Esteve'),
                    _changelogItem(c, Icons.verified, '15/02',
                        'Ruta verificada por la comunidad'),

                    const SizedBox(height: 24),

                    // ── 7. FEEDBACK ──
                    Divider(height: 1, thickness: 0.5, color: c.border),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '¿Esta información es correcta?',
                              style:
                                  TransitTypography.bodySecondary(c.textMid),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.thumb_up_outlined,
                                size: 20, color: c.accent),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('¡Gracias por confirmar!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.thumb_down_outlined,
                                size: 20, color: c.textMid),
                            onPressed: () => context
                                .push('/feedback/${widget.routeId}'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 8. BOTÓN FEEDBACK ──
                    SizedBox(
                      width: double.infinity,
                      child: TransitButton(
                        label: '¿ALGO NO ESTÁ BIEN?',
                        isPrimary: false,
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => context
                            .push('/feedback/${widget.routeId}'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),

          // ── 9. BOTÓN FLOTANTE INFERIOR ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: isFavorite ? 'EN MIS LÍNEAS ✓' : 'AÑADIR A MIS LÍNEAS ★',
                isPrimary: true,
                onPressed: isFavorite ? null : () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(TransitColorScheme c, MockDataService mockData) {
    final schedules = mockData.getSchedulesForRoute(widget.routeId,
        dayType: _selectedDayType);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Sort schedules by time
    final sorted = List.of(schedules)
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    // Find next upcoming
    int nextIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      final m = _timeToMinutes(sorted[i].departureTime);
      if (m >= nowMinutes) {
        nextIndex = i;
        break;
      }
    }

    // Upcoming 5 for compact view
    final upcoming = <_ScheduleEntry>[];
    if (nextIndex >= 0) {
      for (int i = nextIndex;
          i < sorted.length && upcoming.length < 5;
          i++) {
        final m = _timeToMinutes(sorted[i].departureTime);
        final diff = m - nowMinutes;
        upcoming.add(_ScheduleEntry(sorted[i].departureTime, diff, i == nextIndex));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + day type toggle
        Row(
          children: [
            Text('HORARIOS',
                style: TransitTypography.sectionTitle(c.textMid)),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dayTypeButton(c, 'LABORABLE', DayType.weekday),
            const SizedBox(width: 12),
            _dayTypeButton(c, 'SÁBADO', DayType.saturday),
            const SizedBox(width: 12),
            _dayTypeButton(c, 'FESTIVO', DayType.sundayHoliday),
          ],
        ),
        const SizedBox(height: 12),

        // Upcoming compact
        if (upcoming.isNotEmpty) ...[
          ...upcoming.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        entry.time,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: entry.isNext ? c.accent : c.textHi,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'en ${entry.diffMinutes} min',
                        key: ValueKey(entry.diffMinutes),
                        style: TransitTypography.bodySecondary(
                            entry.isNext ? c.accent : c.textMid),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin horarios próximos',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
        ],

        // Expand toggle
        GestureDetector(
          onTap: () => setState(() => _showAllSchedules = !_showAllSchedules),
          child: Text(
            _showAllSchedules ? 'Ocultar ▴' : 'Ver todos ▾',
            style: TransitTypography.bodySecondary(c.accent),
          ),
        ),

        // Full schedule wrap
        if (_showAllSchedules) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: sorted.map((s) {
              final m = _timeToMinutes(s.departureTime);
              final isPast = m < nowMinutes;
              final isNext = sorted.indexOf(s) == nextIndex;
              return Text(
                s.departureTime,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 14,
                  color: isNext
                      ? c.accent
                      : isPast
                          ? c.textLo
                          : c.textHi,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _dayTypeButton(TransitColorScheme c, String label, DayType type) {
    final isActive = _selectedDayType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDayType = type;
        _showAllSchedules = false;
      }),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? c.accent : c.textMid,
              letterSpacing: 0.5,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: label.length * 6.5,
              color: c.accent,
            ),
        ],
      ),
    );
  }

  Widget _infoCell(TransitColorScheme c, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: c.textHi,
          ),
        ),
        Text(label, style: TransitTypography.bodySmall(c.textMid)),
      ],
    );
  }

  Widget _changelogItem(
      TransitColorScheme c, IconData icon, String date, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.textMid),
          const SizedBox(width: 8),
          Text(date, style: TransitTypography.bodySecondary(c.textLo)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TransitTypography.bodySecondary(c.textHi),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _tripStatusColor(TransitColorScheme c, TripStatus status) {
    return switch (status) {
      TripStatus.onTime => c.stateOnTime,
      TripStatus.delay => c.stateDelay,
      TripStatus.cancelled => c.stateCancelled,
      TripStatus.completed => c.stateIdle,
    };
  }

  Color _severityColor(TransitColorScheme c, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => c.accent,
      AlertSeverity.warning => c.stateDelay,
      AlertSeverity.critical => c.stateCancelled,
    };
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int? _calcFrequency(List<dynamic> schedules) {
    if (schedules.length < 2) return null;
    final times = schedules
        .map((s) => _timeToMinutes((s as dynamic).departureTime as String))
        .toList()
      ..sort();
    int totalDiff = 0;
    for (int i = 1; i < times.length; i++) {
      totalDiff += times[i] - times[i - 1];
    }
    return (totalDiff / (times.length - 1)).round();
  }
}

class _ScheduleEntry {
  final String time;
  final int diffMinutes;
  final bool isNext;
  const _ScheduleEntry(this.time, this.diffMinutes, this.isNext);
}
