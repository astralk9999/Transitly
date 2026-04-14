import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/enums.dart';

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
            // Route code + name
            Row(
              children: [
                if (route != null)
                  Container(
                    width: 48,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: route.routeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route.code,
                      style: TransitTypography.routeCodeSmall(Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route?.name ?? trip.routeId,
                    style: TransitTypography.heading(c.textHi),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status
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
            // Vehicle
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
                  'VER RUTA',
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
