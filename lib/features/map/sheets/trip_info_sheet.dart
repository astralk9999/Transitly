import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/route_card.dart';

void showTripInfoSheet(
  BuildContext context, {
  required ActiveTripModel trip,
  required MockDataService mockData,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  final route = mockData.getRouteById(trip.routeId);
  final stopsForRoute = mockData.getStopsForRoute(trip.routeId);
  final totalStops = stopsForRoute.length;

  // Current stop name
  String currentStopName = '';
  if (trip.currentStopIndex != null &&
      trip.currentStopIndex! < stopsForRoute.length) {
    currentStopName = stopsForRoute[trip.currentStopIndex!].name;
  }

  // Status color
  Color statusColor;
  switch (trip.status) {
    case TripStatus.onTime:
      statusColor = c.stateOnTime;
    case TripStatus.delay:
      statusColor = c.stateDelay;
    case TripStatus.cancelled:
      statusColor = c.stateCancelled;
    case TripStatus.completed:
      statusColor = c.stateIdle;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.textLo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // RouteCard
            if (route != null)
              RouteCard(
                route: route,
                activeTrip: trip,
                remainingStops: totalStops,
              ),
            const SizedBox(height: 12),
            // Status detail
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  trip.status.label,
                  style: TransitTypography.bodySecondary(statusColor),
                ),
                if (trip.delayMinutes > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(+${trip.delayMinutes} min)',
                    style: TransitTypography.bodySecondary(c.stateDelay),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Current stop
            if (currentStopName.isNotEmpty)
              Text(
                'En parada ${(trip.currentStopIndex! + 1)}/$totalStops: $currentStopName',
                style: TransitTypography.bodyPrimary(c.textHi),
              ),
            // Capacity
            const SizedBox(height: 4),
            Text(
              'Capacidad: ${trip.capacity.label}',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
            if (trip.vehicleNumber != null) ...[
              const SizedBox(height: 2),
              Text(
                'Vehículo: ${trip.vehicleNumber}',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
            ],
            const SizedBox(height: 16),
            // View route button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/route/${trip.routeId}');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'VER RUTA →',
                  style: TransitTypography.sectionTitle(c.accent),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
