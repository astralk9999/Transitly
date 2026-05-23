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
