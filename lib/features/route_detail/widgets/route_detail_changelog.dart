import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_changelog_model.dart';

class RouteDetailChangelog extends ConsumerWidget {
  const RouteDetailChangelog({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final entries = mockData.getChangelogForRoute(routeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('CAMBIOS RECIENTES',
              style: TransitTypography.sectionTitle(c.textMid)),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text('Sin cambios recientes',
              style: TransitTypography.bodySecondary(c.textMid))
        else
          ...entries.map((e) => _item(c, e)),
      ],
    );
  }

  Widget _item(TransitColorScheme c, RouteChangelogModel entry) {
    final date = '${entry.createdAt.day.toString().padLeft(2, '0')}/'
        '${entry.createdAt.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_iconFor(entry.changeType), size: 16, color: c.textMid),
          const SizedBox(width: 8),
          Text(date, style: TransitTypography.bodySecondary(c.textLo)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.description,
              style: TransitTypography.bodySecondary(c.textHi),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ChangeType type) => switch (type) {
        ChangeType.pathUpdated => Icons.alt_route,
        ChangeType.stopAdded => Icons.add_location,
        ChangeType.stopRemoved => Icons.location_off,
        ChangeType.stopRenamed => Icons.edit_location,
        ChangeType.stopMoved => Icons.swap_horiz,
        ChangeType.scheduleUpdated => Icons.schedule,
        ChangeType.scheduleAdded => Icons.add_alarm,
        ChangeType.scheduleRemoved => Icons.alarm_off,
        ChangeType.infoUpdated => Icons.info_outline,
        ChangeType.statusChanged => Icons.verified,
        ChangeType.created => Icons.add_circle_outline,
        ChangeType.verified => Icons.verified,
        ChangeType.officialized => Icons.star,
      };
}
