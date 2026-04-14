import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/stop_model.dart';

void showStopInfoSheet(
  BuildContext context, {
  required StopModel stop,
  required MockDataService mockData,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  // Find all routes that pass through this stop
  final routesAtStop = <String>[];
  for (final entry in mockData.routeStops.entries) {
    for (final rs in entry.value) {
      if (rs.stopId == stop.id) {
        routesAtStop.add(entry.key);
        break;
      }
    }
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
            // Stop name
            Text(stop.name, style: TransitTypography.heading(c.textHi)),
            const SizedBox(height: 4),
            // Municipality + code
            Text(
              '${stop.municipality} · ${stop.officialCode}',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
            const SizedBox(height: 16),
            // Next arrivals
            Text(
              'PRÓXIMAS LLEGADAS:',
              style: TransitTypography.sectionTitle(c.textMid),
            ),
            const SizedBox(height: 8),
            ...routesAtStop.take(6).map((routeId) {
              final route = mockData.getRouteById(routeId);
              if (route == null) return const SizedBox.shrink();
              final next = mockData.getNextDepartures(routeId, stop.id, 1);
              final time = next.isNotEmpty ? next.first.departureTime : '--:--';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 24,
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
                        route.name,
                        style: TransitTypography.bodySecondary(c.textHi),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(time, style: TransitTypography.stopTime(c.accent)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // Detail button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/stop/${stop.id}');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'VER DETALLE',
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
