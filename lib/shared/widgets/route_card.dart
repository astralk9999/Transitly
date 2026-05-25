import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../models/active_trip_model.dart';
import '../models/enums.dart';
import '../models/route_model.dart';
import 'pressable.dart';
import 'status_badge.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    this.activeTrip,
    this.remainingStops,
    this.estimatedMinutes,
    this.onTap,
  });

  final RouteModel route;
  final ActiveTripModel? activeTrip;
  final int? remainingStops;
  final String? estimatedMinutes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    Color statusColor;
    if (activeTrip != null) {
      switch (activeTrip!.status) {
        case TripStatus.onTime:
          statusColor = c.stateOnRoute;
        case TripStatus.delay:
          statusColor = c.stateDelay;
        case TripStatus.cancelled:
          statusColor = c.stateCancelled;
        case TripStatus.completed:
          statusColor = c.stateIdle;
      }
    } else {
      statusColor = c.stateIdle;
    }

    final statusLabel = activeTrip != null ? ', ${activeTrip!.status.label}' : '';
    final minsLabel = estimatedMinutes != null ? ', $estimatedMinutes' : '';

    return Semantics(
      label: AppLocalizations.of(context).routeCardSemantics(route.code, route.name, statusLabel, minsLabel),
      button: onTap != null,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : c.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : c.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Route code box with status color accent
              Container(
                width: 60,
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                      route.code,
                      style: TransitTypography.routeCode(c.accent),
                  ),
                ),
              ),
              // Center content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        route.name.toUpperCase(),
                        style: TransitTypography.routeName(c.textHi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (remainingStops != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$remainingStops paradas',
                          style: TransitTypography.bodySecondary(c.textMid),
                        ),
                      ],
                      if (activeTrip != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (activeTrip!.startedAt != null)
                              Text(
                                '${activeTrip!.startedAt!.hour.toString().padLeft(2, '0')}:${activeTrip!.startedAt!.minute.toString().padLeft(2, '0')}',
                                style: TransitTypography.stopTime(c.textMid),
                              ),
                            if (activeTrip!.startedAt != null)
                              const SizedBox(width: 8),
                            StatusBadge(
                              activeTrip!.status.label,
                              statusColor,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Right: estimated minutes
              if (estimatedMinutes != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                      estimatedMinutes!,
                      style: TransitTypography.timeEstimate(c.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
