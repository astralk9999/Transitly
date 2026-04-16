import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
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

    // Left border color based on trip status
    Color leftBorderColor;
    if (activeTrip != null) {
      switch (activeTrip!.status) {
        case TripStatus.onTime:
          leftBorderColor = c.stateOnRoute;
        case TripStatus.delay:
          leftBorderColor = c.stateDelay;
        case TripStatus.cancelled:
          leftBorderColor = c.stateCancelled;
        case TripStatus.completed:
          leftBorderColor = c.stateIdle;
      }
    } else {
      leftBorderColor = c.stateIdle;
    }

    final statusLabel = activeTrip != null ? ', ${activeTrip!.status.label}' : '';
    final minsLabel = estimatedMinutes != null ? ', $estimatedMinutes' : '';

    return Semantics(
      label: 'Línea ${route.code}, ${route.name}$statusLabel$minsLabel',
      button: onTap != null,
      child: Pressable(
      onTap: onTap,
      child: Container(
          constraints: const BoxConstraints(minHeight: TransitSpacing.heightRouteCard),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border.all(color: c.border, width: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Left accent border
              Container(
                width: 3,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: leftBorderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              // Route code box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 52,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    route.code,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
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
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: c.textHi,
                        ),
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
                              leftBorderColor,
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
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    estimatedMinutes!,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: activeTrip != null ? c.accent : c.textMid,
                    ),
                  ),
                ),
            ],
          ),
      ),
      ),
    );
  }
}
