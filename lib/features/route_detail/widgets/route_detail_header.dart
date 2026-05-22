import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/widgets/data_freshness_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class RouteDetailHeader extends StatelessWidget {
  const RouteDetailHeader({
    super.key,
    required this.route,
    required this.activeTrip,
  });

  final RouteModel route;
  final ActiveTripModel? activeTrip;

  Color _tripStatusColor(TransitColorScheme c, TripStatus status) {
    return switch (status) {
      TripStatus.onTime => c.stateOnTime,
      TripStatus.delay => c.stateDelay,
      TripStatus.cancelled => c.stateCancelled,
      TripStatus.completed => c.stateIdle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final trip = activeTrip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: c.bgRaised,
                border: Border.all(color: route.routeColor, width: 1),
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
                  Semantics(
                    header: true,
                    label: route.name.toUpperCase(),
                    child: Text(
                      route.name.toUpperCase(),
                      style: TransitTypography.heading(c.textHi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (trip != null)
              StatusBadge(
                trip.status.label,
                _tripStatusColor(c, trip.status),
              ),
            StatusBadge(route.status.label, c.accent),
          ],
        ),
        const SizedBox(height: 8),
        if (route.lastUpdatedAt != null)
          DataFreshnessIndicator(
            route.lastUpdatedAt!,
          ),
      ],
    );
  }
}

class RouteQuickInfoCells extends StatelessWidget {
  const RouteQuickInfoCells({
    super.key,
    required this.stopsCount,
    required this.estimatedMinutes,
    required this.frequencyMinutes,
  });

  final int stopsCount;
  final int estimatedMinutes;
  final int? frequencyMinutes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _cell(c, '$stopsCount', 'paradas')),
          Container(width: 1, height: 24, color: c.border),
          Expanded(child: _cell(c, '~$estimatedMinutes', 'min')),
          Container(width: 1, height: 24, color: c.border),
          Expanded(
            child: _cell(
              c,
              frequencyMinutes != null ? 'Cada $frequencyMinutes' : '--',
              'min',
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(TransitColorScheme c, String value, String label) {
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
}
