import 'package:flutter/material.dart';

import '../models/route_stop_model.dart';
import '../models/stop_model.dart';
import 'stop_list_item.dart';

class StopTimeline extends StatelessWidget {
  const StopTimeline({
    super.key,
    required this.routeStops,
    required this.stopsMap,
    this.currentStopIndex,
    this.transfers,
    this.onStopTap,
  });

  final List<RouteStopModel> routeStops;
  final Map<String, StopModel> stopsMap;
  final int? currentStopIndex;
  final Map<String, List<String>>? transfers;
  final ValueChanged<StopModel>? onStopTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: routeStops.length,
      itemBuilder: (context, index) {
        final rs = routeStops[index];
        final stop = stopsMap[rs.stopId];
        if (stop == null) return const SizedBox.shrink();

        final bool isCurrent =
            currentStopIndex != null && index == currentStopIndex;
        final bool isPassed =
            currentStopIndex != null && index < currentStopIndex!;

        return StopListItem(
          stop: stop,
          scheduledTime: '--:--',
          isCurrent: isCurrent,
          isPassed: isPassed,
          isFirst: index == 0,
          isLast: index == routeStops.length - 1,
          transferLines: transfers?[rs.stopId],
          onTap: onStopTap != null ? () => onStopTap!(stop) : null,
        );
      },
    );
  }
}
