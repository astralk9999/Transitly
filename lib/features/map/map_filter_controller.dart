import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_logger.dart';
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
