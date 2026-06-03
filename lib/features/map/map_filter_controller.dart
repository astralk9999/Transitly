import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_logger.dart';
import 'map_filter_state.dart';

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
    final s = Set<String>.from(state.disabledOperators);
    if (s.contains(opId)) {
      s.remove(opId);
    } else {
      s.add(opId);
    }
    state = state.copyWith(disabledOperators: s);
    _saveToPrefs();
  }

  void toggleKind(String kind) {
    final s = Set<String>.from(state.disabledKinds);
    if (s.contains(kind)) {
      s.remove(kind);
    } else {
      s.add(kind);
    }
    state = state.copyWith(disabledKinds: s);
    _saveToPrefs();
  }

  void toggleLine(String routeId) {
    final s = Set<String>.from(state.disabledLines);
    if (s.contains(routeId)) {
      s.remove(routeId);
    } else {
      s.add(routeId);
    }
    state = state.copyWith(disabledLines: s);
    _saveToPrefs();
  }

  void selectAllLines(List<String> allIds) {
    final s = Set<String>.from(state.disabledLines);
    s.removeAll(allIds);
    state = state.copyWith(disabledLines: s);
    _saveToPrefs();
  }

  void clearAllLines(List<String> allIds) {
    final s = Set<String>.from(state.disabledLines);
    s.addAll(allIds);
    state = state.copyWith(disabledLines: s);
    _saveToPrefs();
  }

  void selectAllOperators(List<String> allIds) {
    final s = Set<String>.from(state.disabledOperators);
    s.removeAll(allIds);
    state = state.copyWith(disabledOperators: s);
    _saveToPrefs();
  }

  void clearAllOperators(List<String> allIds) {
    final s = Set<String>.from(state.disabledOperators);
    s.addAll(allIds);
    state = state.copyWith(disabledOperators: s);
    _saveToPrefs();
  }

  void selectAllKinds(List<String> allIds) {
    final s = Set<String>.from(state.disabledKinds);
    s.removeAll(allIds);
    state = state.copyWith(disabledKinds: s);
    _saveToPrefs();
  }

  void clearAllKinds(List<String> allIds) {
    final s = Set<String>.from(state.disabledKinds);
    s.addAll(allIds);
    state = state.copyWith(disabledKinds: s);
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

  void setShowAllStops(bool v) {
    state = state.copyWith(showAllStops: v);
    _saveToPrefs();
  }

  void setRadiusMeters(double v) {
    state = state.copyWith(radiusMeters: v);
    _saveToPrefs();
  }

  void toggleZone(String zone) {
    final s = Set<String>.from(state.disabledZones);
    if (s.contains(zone)) {
      s.remove(zone);
    } else {
      s.add(zone);
    }
    state = state.copyWith(disabledZones: s);
    _saveToPrefs();
  }

  void selectAllZones(List<String> allIds) {
    final s = Set<String>.from(state.disabledZones);
    s.removeAll(allIds);
    state = state.copyWith(disabledZones: s);
    _saveToPrefs();
  }

  void clearAllZones(List<String> allIds) {
    final s = Set<String>.from(state.disabledZones);
    s.addAll(allIds);
    state = state.copyWith(disabledZones: s);
    _saveToPrefs();
  }

  void reset() {
    state = const MapFilterState();
    _saveToPrefs();
  }

  void applyState(MapFilterState next) {
    state = next;
    _saveToPrefs();
  }
}
