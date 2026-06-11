import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/providers/user_routes_for_map_provider.dart';
import '../map_filter_controller.dart';
import '../map_filter_state.dart';

/// Entrada de línea uniforme para el árbol (oficial o comunitaria). El toggle
/// usa [id] sobre `disabledRouteIds`, que es lo que el mapa filtra realmente.
class _Line {
  _Line(this.id, this.code, this.name, this.color);
  final String id;
  final String code;
  final String name;
  final Color color;
}

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
    final opName = {for (final o in operators) o.id: o.name};
    final opRegion = {
      for (final o in operators) o.id: o.region.isNotEmpty ? o.region : 'Otras zonas'
    };

    // Líneas oficiales agrupadas por zona → operador.
    final officialByZone = <String, Map<String, List<_Line>>>{};
    for (final r in mockData.routes) {
      final zone = opRegion[r.operatorId] ?? 'Otras zonas';
      officialByZone
          .putIfAbsent(zone, () => {})
          .putIfAbsent(r.operatorId, () => [])
          .add(_Line(r.id, r.code, r.name, r.routeColor));
    }

    // Líneas comunitarias (mías) agrupadas por su zona/region.
    final community =
        ref.watch(communityFilterRoutesProvider).valueOrNull ?? const [];
    final communityByZone = <String, List<_Line>>{};
    for (final cr in community) {
      final zone = cr.region ?? 'Comunidad';
      communityByZone
          .putIfAbsent(zone, () => [])
          .add(_Line(cr.id, cr.code, cr.name, cr.color));
    }

    // Zonas de la BD (ampliable): las nuevas aparecen aunque no tengan líneas.
    final dbZones = ref.watch(filterZonesProvider).valueOrNull ?? const [];

    final zones = <String>{
      ...officialByZone.keys,
      ...communityByZone.keys,
      ...dbZones,
    }.toList()
      ..sort();

    final q = _query.trim();
    final hasQuery = q.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          final officialOps = officialByZone[zone] ?? const {};
          final communityLines = communityByZone[zone] ?? const <_Line>[];

          // Todas las líneas de la zona (para el toggle tri-estado de zona).
          final allZoneLines = <_Line>[
            for (final list in officialOps.values) ...list,
            ...communityLines,
          ];
          final zoneMatch = _matches(zone, q);

          // Aplica búsqueda.
          bool lineMatch(_Line l) =>
              zoneMatch || _matches('${l.code} ${l.name}', q);
          final visibleOfficialOps = <String, List<_Line>>{};
          for (final entry in officialOps.entries) {
            final ls = entry.value
                .where((l) =>
                    lineMatch(l) || _matches(opName[entry.key] ?? '', q))
                .toList();
            if (ls.isNotEmpty) visibleOfficialOps[entry.key] = ls;
          }
          final visibleCommunity =
              communityLines.where(lineMatch).toList();

          final isEmptyZone = allZoneLines.isEmpty;
          if (hasQuery &&
              visibleOfficialOps.isEmpty &&
              visibleCommunity.isEmpty &&
              !zoneMatch) {
            return const SizedBox.shrink();
          }

          final allDis = allZoneLines.isNotEmpty &&
              allZoneLines.every((l) => f.disabledRouteIds.contains(l.id));
          final noneDis =
              allZoneLines.every((l) => !f.disabledRouteIds.contains(l.id));

          return ExpansionTile(
            initiallyExpanded: hasQuery || true,
            key: PageStorageKey('zone-$zone-${hasQuery ? "q" : ""}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.only(left: 12),
            iconColor: c.accent,
            collapsedIconColor: c.textMid,
            title: Row(
              children: [
                _TriStateCheckbox(
                  value: isEmptyZone
                      ? true
                      : (noneDis ? true : (allDis ? false : null)),
                  c: c,
                  onChanged: allZoneLines.isEmpty
                      ? null
                      : (v) => ctrl.setRoutesEnabled(
                          allZoneLines.map((l) => l.id), v == true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text(zone, style: TransitTypography.heading(c.textHi)),
                ),
                if (isEmptyZone)
                  Text('sin líneas',
                      style: TransitTypography.bodySmall(c.textLo)),
              ],
            ),
            children: [
              // Operadores oficiales de la zona.
              ...visibleOfficialOps.entries.map((e) => _opNode(
                    c,
                    ctrl,
                    f,
                    title: opName[e.key] ?? 'Operador',
                    nodeKey: 'op-${e.key}',
                    lines: e.value,
                    hasQuery: hasQuery,
                  )),
              // Líneas comunitarias de la zona.
              if (visibleCommunity.isNotEmpty)
                _opNode(
                  c,
                  ctrl,
                  f,
                  title: 'Comunidad',
                  nodeKey: 'comm-$zone',
                  lines: visibleCommunity,
                  hasQuery: hasQuery,
                  icon: Icons.groups_outlined,
                ),
            ],
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

  Widget _opNode(
    TransitColorScheme c,
    MapFilterController ctrl,
    MapFilterState f, {
    required String title,
    required String nodeKey,
    required List<_Line> lines,
    required bool hasQuery,
    IconData? icon,
  }) {
    final allDis = lines.every((l) => f.disabledRouteIds.contains(l.id));
    final noneDis = lines.every((l) => !f.disabledRouteIds.contains(l.id));
    return ExpansionTile(
      key: PageStorageKey('$nodeKey-${hasQuery ? "q" : ""}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(left: 16),
      iconColor: c.accent,
      collapsedIconColor: c.textMid,
      initiallyExpanded: hasQuery || lines.length <= 5,
      title: Row(
        children: [
          _TriStateCheckbox(
            value: noneDis ? true : (allDis ? false : null),
            c: c,
            onChanged: (v) =>
                ctrl.setRoutesEnabled(lines.map((l) => l.id), v == true),
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[
            Icon(icon, size: 16, color: c.textMid),
            const SizedBox(width: 6),
          ],
          Expanded(
            child:
                Text(title, style: TransitTypography.bodyPrimary(c.textHi)),
          ),
        ],
      ),
      children: lines.map((line) {
        final disabled = f.disabledRouteIds.contains(line.id);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          dense: true,
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: disabled ? c.textLo : line.color,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            '${line.code} · ${line.name}',
            style: TransitTypography.bodySmall(disabled ? c.textLo : c.textHi),
          ),
          trailing: Checkbox(
            value: !disabled,
            activeColor: c.accent,
            visualDensity: VisualDensity.compact,
            onChanged: (_) => ctrl.toggleRouteId(line.id),
          ),
          onTap: () => ctrl.toggleRouteId(line.id),
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
      onTap: onChanged == null
          ? null
          : () {
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
