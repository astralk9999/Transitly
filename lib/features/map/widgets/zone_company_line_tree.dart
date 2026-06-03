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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: operators.map((op) {
        final opRoutes = routes.where((r) => r.operatorId == op.id).toList();
        if (opRoutes.isEmpty) return const SizedBox.shrink();

        final allDisabled = opRoutes.every((r) => f.disabledRouteIds.contains(r.id));
        final noneDisabled = opRoutes.every((r) => !f.disabledRouteIds.contains(r.id));

        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          childrenPadding: const EdgeInsets.only(left: 16),
          iconColor: c.accent,
          collapsedIconColor: c.textMid,
          title: Row(
            children: [
              _TriStateCheckbox(
                value: noneDisabled ? true : (allDisabled ? false : null),
                c: c,
                onChanged: (v) {
                  if (v == true || v == null) {
                    ctrl.setRoutesEnabled(opRoutes.map((r) => r.id), true);
                  } else {
                    ctrl.setRoutesEnabled(opRoutes.map((r) => r.id), false);
                  }
                },
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
        final next = value == true ? false : (value == false ? null : true);
        onChanged?.call(next);
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null ? c.accent : c.textLo,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          color: value == true ? c.accent : Colors.transparent,
        ),
        child: value == true
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : value == null
                ? Icon(Icons.remove, size: 14, color: c.textLo)
                : null,
      ),
    );
  }
}
