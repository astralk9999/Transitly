import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserFavoritesNotifier extends StateNotifier<Set<String>> {
  UserFavoritesNotifier() : super(<String>{}) {
    _load();
  }

  static const _boxName = 'userFavorites';
  static const _key = 'lines';

  Future<void> _load() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    if (!mounted) return;
    final raw = box.get(_key, defaultValue: <String>[]) ?? <String>[];
    state = Set<String>.from(raw);
  }

  Future<void> addLine(String routeId) async {
    state = {...state, routeId};
    await _persist();
  }

  Future<void> removeLine(String routeId) async {
    state = {...state}..remove(routeId);
    await _persist();
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    await box.put(_key, state.toList());
  }

  bool isFavorite(String routeId) => state.contains(routeId);
}

final userFavoritesProvider =
    StateNotifierProvider<UserFavoritesNotifier, Set<String>>(
        (ref) => UserFavoritesNotifier());

class UserFavoriteStopsNotifier extends StateNotifier<Set<String>> {
  UserFavoriteStopsNotifier() : super(<String>{}) {
    _load();
  }

  static const _boxName = 'userFavorites';
  static const _key = 'stops';

  Future<void> _load() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    if (!mounted) return;
    final raw = box.get(_key, defaultValue: <String>[]) ?? <String>[];
    state = Set<String>.from(raw);
  }

  Future<void> addStop(String stopId) async {
    state = {...state, stopId};
    await _persist();
  }

  Future<void> removeStop(String stopId) async {
    state = {...state}..remove(stopId);
    await _persist();
  }

  Future<void> toggleStop(String stopId) async {
    if (state.contains(stopId)) {
      await removeStop(stopId);
    } else {
      await addStop(stopId);
    }
  }

  bool isStopFavorite(String stopId) => state.contains(stopId);

  Future<void> _persist() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    await box.put(_key, state.toList());
  }
}

final userFavoriteStopsProvider =
    StateNotifierProvider<UserFavoriteStopsNotifier, Set<String>>(
        (ref) => UserFavoriteStopsNotifier());
