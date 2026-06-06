import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../map_filter_controller.dart';

class ZoneCompanyLineTree extends ConsumerStatefulWidget {
  const ZoneCompanyLineTree({super.key});

  @override
  ConsumerState<ZoneCompanyLineTree> createState() =>
      _ZoneCompanyLineTreeState();
}

class _ZoneCompanyLineTreeState extends ConsumerState<ZoneCompanyLineTree> {
  String _query = '';

  bool _matches(String haystack, String needle) {
    if (needle.isEmpty) return true;
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
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

    final q = _query.trim();
    final hasQuery = q.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador para escalabilidad cuando hay muchas zonas o líneas.
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TransitTypography.bodySecondary(c.textHi),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar zona, operador o línea',
              hintStyle: TransitTypography.bodySmall(c.textLo),
              prefixIcon: Icon(Icons.search, size: 18, color: c.textLo),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 16, color: c.textLo),
                      tooltip: 'Limpiar',
                      onPressed: () => setState(() => _query = ''),
                    ),
              filled: true,
              fillColor: c.bgRaised,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        ...zones.map((zone) {
          final opIds = byZone[zone]!;
          final opsInZone =
              operators.where((op) => opIds.contains(op.id)).toList();
          final routesInZone = routes
              .where((r) => opIds.contains(r.operatorId))
              .toList();
          if (routesInZone.isEmpty) return const SizedBox.shrink();

          // Filtro por query: una zona se muestra si su nombre matchea, o
          // si algún operador o ruta dentro matchea.
          final zoneMatch = _matches(zone, q);
          final routesMatching = routesInZone
              .where((r) =>
                  zoneMatch ||
                  _matches('${r.code} ${r.name}', q) ||
                  _matches(
                      opsInZone
                          .firstWhere((op) => op.id == r.operatorId)
                          .name,
                      q))
              .toList();
          if (hasQuery && routesMatching.isEmpty) {
            return const SizedBox.shrink();
          }

          final allDis =
              routesInZone.every((r) => f.disabledRouteIds.contains(r.id));
          final noneDis =
              routesInZone.every((r) => !f.disabledRouteIds.contains(r.id));

          return ExpansionTile(
            // Si hay búsqueda activa, fuerzo expandir para que los
            // resultados sean visibles inmediatamente.
            initiallyExpanded: hasQuery || true,
            key: PageStorageKey('zone-$zone-${hasQuery ? "q" : ""}'),
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
                  child:
                      Text(zone, style: TransitTypography.heading(c.textHi)),
                ),
              ],
            ),
            children: opsInZone.map((op) {
              final opRoutes = routes
                  .where((r) =>
                      r.operatorId == op.id &&
                      (zoneMatch ||
                          _matches(op.name, q) ||
                          _matches('${r.code} ${r.name}', q)))
                  .toList();
              if (opRoutes.isEmpty) return const SizedBox.shrink();

              final allOpDis = opRoutes
                  .every((r) => f.disabledRouteIds.contains(r.id));
              final noneOpDis = opRoutes
                  .every((r) => !f.disabledRouteIds.contains(r.id));

              return ExpansionTile(
                key: PageStorageKey(
                    'op-${op.id}-${hasQuery ? "q" : ""}'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                childrenPadding: const EdgeInsets.only(left: 16),
                iconColor: c.accent,
                collapsedIconColor: c.textMid,
                initiallyExpanded: hasQuery || opRoutes.length <= 5,
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
                      child: Text(op.name,
                          style: TransitTypography.bodyPrimary(c.textHi)),
                    ),
                  ],
                ),
                children: opRoutes.map((route) {
                  final disabled =
                      f.disabledRouteIds.contains(route.id);
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
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
        }),
        if (hasQuery)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Mostrando coincidencias para "$q"',
                style: TransitTypography.bodySmall(c.textLo),
              ),
            ),
          ),
      ],
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
