import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeReferenceStopNotifier extends StateNotifier<String?> {
  HomeReferenceStopNotifier() : super(null) {
    _load();
  }

  static const _boxName = 'home_reference_stop';
  static const _key = 'stopId';

  Future<void> _load() async {
    final box = await Hive.openBox<String>(_boxName);
    state = box.get(_key);
  }

  Future<void> setStop(String id) async {
    state = id;
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, id);
  }

  Future<void> clear() async {
    state = null;
    final box = await Hive.openBox<String>(_boxName);
    await box.delete(_key);
  }
}

final homeReferenceStopProvider =
    StateNotifierProvider<HomeReferenceStopNotifier, String?>(
        (ref) => HomeReferenceStopNotifier());
