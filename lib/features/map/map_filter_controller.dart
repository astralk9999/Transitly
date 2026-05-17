import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/transit_button.dart';
import 'map_filter_state.dart';

/// Persiste y expone el estado de los filtros del mapa en
/// shared_preferences (baja frecuencia de lectura/escritura,
/// no justifica una caja Hive dedicada).
final mapFilterControllerProvider =
    StateNotifierProvider<MapFilterController, MapFilterState>((ref) {
  return MapFilterController();
});

class MapFilterController extends StateNotifier<MapFilterState> {
  MapFilterController() : super(const MapFilterState()) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'map_filters';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = MapFilterState.fromJson(json);
      }
    } catch (e) {
      AppLogger.warn('MapFilter',
          'failed to load filters from prefs — using defaults', e);
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  void setShowOfficial(bool v) {
    state = state.copyWith(showOfficial: v);
    _saveToPrefs();
  }

  void setShowCommunity(bool v) {
    state = state.copyWith(showCommunity: v);
    _saveToPrefs();
  }

  void toggleOperator(String opId) {
    final ops = Set<String>.from(state.activeOperators);
    if (ops.contains(opId)) {
      ops.remove(opId);
    } else {
      ops.add(opId);
    }
    state = state.copyWith(activeOperators: ops);
    _saveToPrefs();
  }

  void toggleKind(String kind) {
    final kinds = Set<String>.from(state.activeKinds);
    if (kinds.contains(kind)) {
      kinds.remove(kind);
    } else {
      kinds.add(kind);
    }
    state = state.copyWith(activeKinds: kinds);
    _saveToPrefs();
  }

  void setNextMinutes(int minutes) {
    state = state.copyWith(nextMinutes: minutes);
    _saveToPrefs();
  }

  void setOnlyAccessible(bool v) {
    state = state.copyWith(onlyAccessible: v);
    _saveToPrefs();
  }

  void setOnlyFavorites(bool v) {
    state = state.copyWith(onlyFavorites: v);
    _saveToPrefs();
  }

  void setRadiusMeters(double v) {
    state = state.copyWith(radiusMeters: v);
    _saveToPrefs();
  }

  void reset() {
    state = const MapFilterState();
    _saveToPrefs();
  }

  /// Aplica un estado completo de filtros (usado por los presets
  /// guardados en [FilterPresetsScreen]).
  void applyState(MapFilterState next) {
    state = next;
    _saveToPrefs();
  }
}

/// Bottom sheet de filtros del mapa. Se invoca desde [MapControls.onFilter].
void showMapFilterSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final f = ref.watch(mapFilterControllerProvider);
          final ctrl = ref.read(mapFilterControllerProvider.notifier);

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
              padding: const EdgeInsets.all(16),
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
                  Text('Filtros del mapa',
                      style: TransitTypography.heading(c.textHi)),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Origen de la ruta'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Oficiales',
                        selected: f.showOfficial,
                        c: c,
                        onTap: () =>
                            ctrl.setShowOfficial(!f.showOfficial),
                      ),
                      _FilterChip(
                        label: 'Comunitarias',
                        selected: f.showCommunity,
                        c: c,
                        onTap: () =>
                            ctrl.setShowCommunity(!f.showCommunity),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Próximas salidas'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 60]
                        .map((m) => _FilterChip(
                              label: '$m min',
                              selected: f.nextMinutes == m,
                              c: c,
                              onTap: () => ctrl.setNextMinutes(
                                  f.nextMinutes == m ? 0 : m),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Accesibilidad'),
                  _FilterChip(
                    label: 'Solo accesibles',
                    selected: f.onlyAccessible,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyAccessible(!f.onlyAccessible),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Favoritos'),
                  _FilterChip(
                    label: 'Solo favoritos',
                    selected: f.onlyFavorites,
                    c: c,
                    onTap: () => ctrl.setOnlyFavorites(!f.onlyFavorites),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: 'RESTABLECER',
                          isPrimary: false,
                          isSmall: true,
                          onPressed: ctrl.reset,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TransitButton(
                          label: 'APLICAR',
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.2) : c.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.accent : c.textMid,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
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
      child: Text(title,
          style: TransitTypography.sectionTitle(c.textMid)),
    );
  }
}
