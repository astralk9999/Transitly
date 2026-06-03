import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../map_filter_controller.dart';

class ZoneCompanyLineTree extends ConsumerWidget {
  const ZoneCompanyLineTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final f = ref.watch(mapFilterControllerProvider);
    final ctrl = ref.read(mapFilterControllerProvider.notifier);
    final mockData = ref.read(mockDataServiceProvider);

    final operators = mockData.getOperators();
    final routes = mockData.routes;

    final byZone = <String, List<String>>{};
    for (final op in operators) {
      final zone = op.region.isNotEmpty ? op.region : 'Otras zonas';
      byZone.putIfAbsent(zone, () => []).add(op.id);
    }
    final zones = byZone.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: zones.map((zone) {
        final opIds = byZone[zone]!;
        final opsInZone = operators.where((op) => opIds.contains(op.id)).toList();
        final routesInZone = routes.where(
          (r) => opIds.contains(r.operatorId),
        ).toList();
        if (routesInZone.isEmpty) return const SizedBox.shrink();

        final allDis = routesInZone.every((r) => f.disabledRouteIds.contains(r.id));
        final noneDis = routesInZone.every((r) => !f.disabledRouteIds.contains(r.id));

        return ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          childrenPadding: const EdgeInsets.only(left: 12),
          iconColor: c.accent,
          collapsedIconColor: c.textMid,
          title: Row(
            children: [
              _TriStateCheckbox(
                value: noneDis ? true : (allDis ? false : null),
                c: c,
                onChanged: (v) => ctrl.setRoutesEnabled(
                  routesInZone.map((r) => r.id),
                  v == true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(zone, style: TransitTypography.heading(c.textHi)),
              ),
            ],
          ),
          children: opsInZone.map((op) {
            final opRoutes = routes.where((r) => r.operatorId == op.id).toList();
            if (opRoutes.isEmpty) return const SizedBox.shrink();

            final allOpDis = opRoutes.every((r) => f.disabledRouteIds.contains(r.id));
            final noneOpDis = opRoutes.every((r) => !f.disabledRouteIds.contains(r.id));

            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              childrenPadding: const EdgeInsets.only(left: 16),
              iconColor: c.accent,
              collapsedIconColor: c.textMid,
              initiallyExpanded: opRoutes.length <= 5,
              title: Row(
                children: [
                  _TriStateCheckbox(
                    value: noneOpDis ? true : (allOpDis ? false : null),
                    c: c,
                    onChanged: (v) => ctrl.setRoutesEnabled(
                      opRoutes.map((r) => r.id),
                      v == true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(op.name, style: TransitTypography.bodyPrimary(c.textHi)),
                  ),
                ],
              ),
              children: opRoutes.map((route) {
                final disabled = f.disabledRouteIds.contains(route.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: disabled ? c.textLo : route.routeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    '${route.code} · ${route.name}',
                    style: TransitTypography.bodySmall(
                      disabled ? c.textLo : c.textHi,
                    ),
                  ),
                  trailing: Checkbox(
                    value: !disabled,
                    activeColor: c.accent,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => ctrl.toggleRouteId(route.id),
                  ),
                  onTap: () => ctrl.toggleRouteId(route.id),
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _TriStateCheckbox extends StatelessWidget {
  const _TriStateCheckbox({required this.value, required this.c, this.onChanged});
  final bool? value;
  final TransitColorScheme c;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final next = value == false ? true : false;
        onChanged?.call(next);
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null ? c.accent : c.textLo,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          color: value == true ? c.accent : Colors.transparent,
        ),
        child: value == true
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : value == null
                ? Icon(Icons.remove, size: 14, color: c.textLo)
                : null,
      ),
    );
  }
}
