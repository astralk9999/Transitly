import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_model.dart';
import 'route_detail_header.dart';
import 'route_share_sheet.dart';
import 'route_officialize_modal.dart';

class RouteDetailHeaderSection extends ConsumerWidget {
  const RouteDetailHeaderSection({
    super.key,
    required this.route,
    required this.activeTrip,
    required this.stopsCount,
    required this.estimatedMinutes,
    required this.frequencyMinutes,
    required this.onPop,
  });

  final RouteModel route;
  final ActiveTripModel? activeTrip;
  final int stopsCount;
  final int estimatedMinutes;
  final int? frequencyMinutes;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Row(
          children: [
            GestureDetector(
              onTap: onPop,
              child: Icon(Icons.arrow_back, size: 24, color: c.textMid),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.share, size: 22, color: c.textMid),
              onPressed: () => showRouteShareSheet(
                context,
                ref,
                routeId: route.id,
                routeName: route.name,
              ),
              tooltip: 'Compartir',
            ),
            if (route.status == RouteStatus.draft)
              IconButton(
                icon: Icon(Icons.verified_outlined, size: 22, color: c.textMid),
                onPressed: () => showRouteOfficializeModal(
                  context,
                  ref,
                  routeId: route.id,
                  routeName: route.name,
                ),
                tooltip: 'Solicitar oficialización',
              ),
          ],
        ),
        const SizedBox(height: 16),
        RouteDetailHeader(route: route, activeTrip: activeTrip),
        Divider(height: 32, thickness: 0.5, color: c.border),
        RouteQuickInfoCells(
          stopsCount: stopsCount,
          estimatedMinutes: estimatedMinutes,
          frequencyMinutes: frequencyMinutes,
        ),
      ],
    );
  }
}
