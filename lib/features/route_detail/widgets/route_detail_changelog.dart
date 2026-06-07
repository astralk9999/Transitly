import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/admin/admin_routes_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';

/// "Cambios recientes" de una ruta, leídos de `route_changelog` (BD real).
/// Cada edición de la ruta/paradas/horarios desde el panel de gestión
/// inserta una entrada (p.ej. "Horario actualizado · días laborables",
/// "Parada añadida: Esteve"). Si no hay entradas (o el id no es un UUID
/// de ruta real) muestra el estado vacío.
class RouteDetailChangelog extends ConsumerWidget {
  const RouteDetailChangelog({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return FutureBuilder<List<RouteChangeRow>>(
      future: ref.read(adminRoutesRepositoryProvider).listChangelog(routeId),
      builder: (context, snap) {
        final entries = snap.data ?? const <RouteChangeRow>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(AppLocalizations.of(context).sectionRecentChanges,
                  style: TransitTypography.sectionTitle(c.textMid)),
            ),
            const SizedBox(height: 8),
            if (snap.connectionState == ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('…',
                    style: TransitTypography.bodySecondary(c.textMid)),
              )
            else if (entries.isEmpty)
              Text(AppLocalizations.of(context).routeChangelogEmpty,
                  style: TransitTypography.bodySecondary(c.textMid))
            else
              ...entries.map((e) => _item(c, e)),
          ],
        );
      },
    );
  }

  Widget _item(TransitColorScheme c, RouteChangeRow entry) {
    final type = ChangeType.fromString(entry.changeType);
    final date = '${entry.createdAt.day.toString().padLeft(2, '0')}/'
        '${entry.createdAt.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_iconFor(type), size: 16, color: c.textMid),
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
