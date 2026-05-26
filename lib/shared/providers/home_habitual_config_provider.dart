import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeHabitualConfig {
  final String? routeId;
  final String? stopId;

  const HomeHabitualConfig({this.routeId, this.stopId});

  bool get isConfigured => routeId != null && stopId != null;
}

class HomeHabitualConfigNotifier extends StateNotifier<HomeHabitualConfig> {
  HomeHabitualConfigNotifier() : super(const HomeHabitualConfig()) {
    _load();
  }

  static const _boxName = 'home_habitual_config';
  static const _routeKey = 'routeId';
  static const _stopKey = 'stopId';

  Future<void> _load() async {
    final box = await Hive.openBox<String>(_boxName);
    final routeId = box.get(_routeKey);
    final stopId = box.get(_stopKey);
    state = HomeHabitualConfig(routeId: routeId, stopId: stopId);
  }

  Future<void> save(String routeId, String stopId) async {
    state = HomeHabitualConfig(routeId: routeId, stopId: stopId);
    await _persist();
  }

  Future<void> clear() async {
    state = const HomeHabitualConfig();
    await _persist();
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<String>(_boxName);
    if (state.routeId != null) {
      await box.put(_routeKey, state.routeId!);
    } else {
      await box.delete(_routeKey);
    }
    if (state.stopId != null) {
      await box.put(_stopKey, state.stopId!);
    } else {
      await box.delete(_stopKey);
    }
  }
}

final homeHabitualConfigProvider =
    StateNotifierProvider<HomeHabitualConfigNotifier, HomeHabitualConfig>(
        (ref) => HomeHabitualConfigNotifier());
