import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/route_stop_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/widgets/stop_list_item.dart';

class RouteDetailTimeline extends StatelessWidget {
  const RouteDetailTimeline({
    super.key,
    required this.sortedRouteStops,
    required this.stopsMap,
    required this.transfers,
    required this.activeTrip,
  });

  final List<RouteStopModel> sortedRouteStops;
  final Map<String, StopModel> stopsMap;
  final Map<String, List<String>> transfers;
  final ActiveTripModel? activeTrip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('RECORRIDO',
              style: TransitTypography.sectionTitle(c.textMid)),
        ),
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

              final currentIdx = activeTrip?.currentStopIndex;
              final isCurrent = currentIdx != null && index == currentIdx;
              final isPassed = currentIdx != null && index < currentIdx;

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
                onTap: () => context.push('/stop/${stop.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
