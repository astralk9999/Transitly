import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/transit_button.dart';
import '../map_filter_controller.dart';
import '../map_filter_state.dart';
import 'zone_company_line_tree.dart';

void showMapFilterSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  final mockData = ref.read(mockDataServiceProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final f = ref.watch(mapFilterControllerProvider);
          final ctrl = ref.read(mapFilterControllerProvider.notifier);
          final l10n = AppLocalizations.of(context);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: c.bgRoot,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(ctx).padding.bottom,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Mostrar líneas'),
                  _OperatorTree(
                    c: c, f: f, ctrl: ctrl, mockData: mockData,
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Zonas'),
                  const ZoneCompanyLineTree(),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterRouteSource),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: l10n.mapFilterOfficial,
                        selected: f.showOfficial,
                        c: c,
                        onTap: () =>
                            ctrl.setShowOfficial(!f.showOfficial),
                      ),
                      _FilterChip(
                        label: l10n.mapFilterCommunity,
                        selected: f.showCommunity,
                        c: c,
                        onTap: () =>
                            ctrl.setShowCommunity(!f.showCommunity),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterUpcoming),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 60]
                        .map((m) => _FilterChip(
                              label: l10n.mapFilterMinutes(m),
                              selected: f.nextMinutes == m,
                              c: c,
                              onTap: () => ctrl.setNextMinutes(
                                  f.nextMinutes == m ? 0 : m),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterAccessibility),
                  _FilterChip(
                    label: l10n.mapFilterOnlyAccessible,
                    selected: f.onlyAccessible,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyAccessible(!f.onlyAccessible),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterFavorites),
                  _FilterChip(
                    label: l10n.mapFilterOnlyFavorites,
                    selected: f.onlyFavorites,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyFavorites(!f.onlyFavorites),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Paradas'),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Mostrar paradas',
                            style: TransitTypography.bodyPrimary(c.textHi)),
                      ),
                      Switch.adaptive(
                        value: f.showAllStops,
                        activeTrackColor: c.accent,
                        onChanged: (v) => ctrl.setShowAllStops(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: l10n.actionReset.toUpperCase(),
                          isPrimary: false,
                          isSmall: true,
                          onPressed: ctrl.reset,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TransitButton(
                          label: l10n.actionApply.toUpperCase(),
                          isSmall: true,
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
    );
  }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.c,
    this.onTap,
  });
  final String label;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.2) : c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.accent.withValues(alpha: 0.6) : c.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.accent : c.textLo,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _OperatorZoneChips extends StatelessWidget {
  const _OperatorZoneChips({
    required this.c, required this.f, required this.ctrl, required this.mockData,
  });
  final TransitColorScheme c;
  final MapFilterState f;
  final MapFilterController ctrl;
  final MockDataService mockData;

  @override
  Widget build(BuildContext context) {
    final operators = mockData.getOperators();
    final zoneNames = operators.map((op) => op.name).toSet().toList()..sort();

    if (zoneNames.isEmpty) {
      return Text('Sin zonas', style: TextStyle(color: c.textLo, fontSize: 12));
    }

    final allActive = zoneNames.every((z) => !f.disabledZones.contains(z));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => ctrl.selectAllZones(zoneNames),
              child: Text('Todas', style: TextStyle(color: allActive ? c.accent : c.textLo, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ctrl.clearAllZones(zoneNames),
              child: Text('Ninguna', style: TextStyle(color: allActive ? c.textLo : c.accent, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: zoneNames.map((zone) {
            final active = !f.disabledZones.contains(zone);
            return GestureDetector(
              onTap: () => ctrl.toggleZone(zone),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? c.accent.withValues(alpha: 0.2) : c.bgRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? c.accent.withValues(alpha: 0.6) : c.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  zone,
                  style: TextStyle(
                    color: active ? c.accent : c.textLo,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.c, required this.title});
  final TransitColorScheme c;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TransitTypography.sectionTitle(c.textMid)),
    );
  }
}

class _OperatorTree extends StatelessWidget {
  const _OperatorTree({
    required this.c, required this.f, required this.ctrl, required this.mockData,
  });
  final TransitColorScheme c;
  final MapFilterState f;
  final MapFilterController ctrl;
  final MockDataService mockData;

  bool _isAllLinesVisible(List<String> routeIds) {
    return routeIds.every((id) => !f.disabledLines.contains(id));
  }

  bool _isNoneLinesVisible(List<String> routeIds) {
    return routeIds.every((id) => f.disabledLines.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final routes = mockData.routes;
    final serviceTypes = ServiceType.values;
    final allLineIds = routes.map((r) => r.id).toList();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: _isAllLinesVisible(allLineIds) ? true
                    : _isNoneLinesVisible(allLineIds) ? false : null,
                tristate: true,
                activeColor: c.accent,
                onChanged: (v) {
                  if (v == true) {
                    ctrl.selectAllLines(allLineIds);
                  } else {
                    ctrl.clearAllLines(allLineIds);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('COMUJESA',
                  style: TransitTypography.bodyPrimary(c.textHi)),
            ),
            GestureDetector(
              onTap: () => ctrl.selectAllLines(allLineIds),
              child: Text('Todas',
                  style: TransitTypography.bodySmall(c.accent)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ctrl.clearAllLines(allLineIds),
              child: Text('Ninguna',
                  style: TransitTypography.bodySmall(c.textMid)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final kind in serviceTypes)
          _KindBlock(
            kind: kind,
            routes: routes.where((r) => r.serviceType == kind).toList(),
            f: f,
            c: c,
            ctrl: ctrl,
          ),
      ],
    );
  }
}

class _KindBlock extends StatefulWidget {
  const _KindBlock({
    required this.kind, required this.routes, required this.f,
    required this.c, required this.ctrl,
  });
  final ServiceType kind;
  final List<dynamic> routes;
  final MapFilterState f;
  final TransitColorScheme c;
  final MapFilterController ctrl;

  @override
  State<_KindBlock> createState() => _KindBlockState();
}

class _KindBlockState extends State<_KindBlock> {
  bool _expanded = false;

  bool _isAllVisible(List<String> ids) {
    return ids.every((id) => !widget.f.disabledLines.contains(id));
  }

  bool _isNoneVisible(List<String> ids) {
    return ids.every((id) => widget.f.disabledLines.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routes.isEmpty) return const SizedBox.shrink();
    final c = widget.c;
    final ctrl = widget.ctrl;
    final f = widget.f;
    final kind = widget.kind;
    final routes = widget.routes;
    final lineIds =
        routes.map((r) => (r as dynamic).id as String).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          // Cabecera de la zona: checkbox tri-state + nombre + chevron
          // (colapsa/expande las lineas) + atajos Todas/Ninguna.
          Row(
            children: [
              SizedBox(
                width: 24, height: 24,
                child: Checkbox(
                  value: _isAllVisible(lineIds) ? true
                      : _isNoneVisible(lineIds) ? false : null,
                  tristate: true,
                  activeColor: c.accent,
                  onChanged: (v) {
                    if (v == true) {
                      ctrl.selectAllLines(lineIds);
                    } else {
                      ctrl.clearAllLines(lineIds);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Tap en el nombre = colapsa/expande.
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _expanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(Icons.chevron_right,
                              size: 18, color: c.textMid),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(kind.label,
                              style: TransitTypography.bodySecondary(
                                  c.textHi)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ctrl.selectAllLines(lineIds),
                child: Text('Todas',
                    style: TransitTypography.bodySmall(c.accent)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ctrl.clearAllLines(lineIds),
                child: Text('Ninguna',
                    style: TransitTypography.bodySmall(c.textMid)),
              ),
            ],
          ),
          // Lineas hijas: solo si _expanded. Cada una con su badge en
          // el color real de la linea.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                for (final r in routes)
                  CheckboxListTile(
                    value: !f.disabledLines
                        .contains((r as dynamic).id as String),
                    activeColor: c.accent,
                    dense: true,
                    contentPadding:
                        const EdgeInsets.only(left: 24, right: 0),
                    secondary: Container(
                      width: 44,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ((r as dynamic).routeColor as Color)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              ((r as dynamic).routeColor as Color)
                                  .withValues(alpha: 0.60),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        (r as dynamic).code as String,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TransitTypography.routeCodeSmall(
                            (r as dynamic).routeColor as Color),
                      ),
                    ),
                    title: Text(
                      (r as dynamic).name as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    onChanged: (_) =>
                        ctrl.toggleLine((r as dynamic).id as String),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
