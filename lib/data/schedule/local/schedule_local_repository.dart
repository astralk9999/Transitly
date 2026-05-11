import 'package:hive/hive.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/schedule_model.dart';
import '../domain/schedule_repository.dart';

/// Cache local de horarios. Convención de claves:
///   `schedule:<routeId>:<dayType>:<departureTime>`
/// Permite filtrar por ruta+día sin barrer la caja entera.
class ScheduleLocalRepository implements ScheduleRepository {
  ScheduleLocalRepository(this._box);

  final Box<ScheduleModel> _box;

  static String _key(ScheduleModel s) =>
      'schedule:${s.routeId}:${s.dayType.name}:${s.departureTime}';

  static String _prefix(String routeId, [DayType? dayType]) =>
      dayType == null
          ? 'schedule:$routeId:'
          : 'schedule:$routeId:${dayType.name}:';

  @override
  Future<List<ScheduleModel>> forRoute(
    String routeId, {
    DayType? dayType,
  }) async {
    final prefix = _prefix(routeId, dayType);
    final result = <ScheduleModel>[];
    for (final key in _box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final v = _box.get(key);
        if (v != null) result.add(v);
      }
    }
    result.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return result;
  }

  @override
  Future<List<ScheduleModel>> nextDepartures(
      String routeId, int count) async {
    final now = DateTime.now();
    final dayType = _todayDayType(now);
    final nowHhmm = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final all = await forRoute(routeId, dayType: dayType);
    return all
        .where((s) => s.departureTime.compareTo(nowHhmm) >= 0)
        .take(count)
        .toList(growable: false);
  }

  Future<void> upsert(ScheduleModel s) async {
    await _box.put(_key(s), s);
  }

  Future<void> upsertAll(Iterable<ScheduleModel> items) async {
    final entries = <String, ScheduleModel>{
      for (final s in items) _key(s): s,
    };
    await _box.putAll(entries);
  }

  Future<void> clear() async => _box.clear();

  static DayType _todayDayType(DateTime now) {
    return switch (now.weekday) {
      DateTime.saturday => DayType.saturday,
      DateTime.sunday => DayType.sundayHoliday,
      _ => DayType.weekday,
    };
  }
}
