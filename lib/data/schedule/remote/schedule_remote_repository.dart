import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/schedule_model.dart';
import '../domain/schedule_repository.dart';

/// Implementación remota de [ScheduleRepository] sobre Supabase.
class ScheduleRemoteRepository implements ScheduleRepository {
  ScheduleRemoteRepository(this._client);

  final SupabaseClient _client;

  static const _logTag = 'Repo:Schedule:Remote';

  @override
  Future<List<ScheduleModel>> forRoute(
    String routeId, {
    DayType? dayType,
  }) async {
    try {
      var query =
          _client.from('schedules').select().eq('route_id', routeId);
      if (dayType != null) {
        query = query.eq('day_type', dayType.name);
      }
      final rows = await query.order('departure_time');
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'forRoute($routeId, $dayType)');
    }
  }

  @override
  Future<List<ScheduleModel>> nextDepartures(
      String routeId, int count) async {
    final now = DateTime.now();
    final dayType = _todayDayType(now);
    final hhmm = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:00';
    try {
      final rows = await _client
          .from('schedules')
          .select()
          .eq('route_id', routeId)
          .eq('day_type', dayType.name)
          .gte('departure_time', hhmm)
          .order('departure_time')
          .limit(count);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'nextDepartures($routeId, $count)');
    }
  }

  ScheduleModel _fromRow(Map<String, dynamic> row) {
    // `departure_time` viene como 'HH:MM:SS'. El modelo guarda 'HH:MM'
    // — recortamos los segundos.
    final raw = row['departure_time'] as String;
    final hhmm = raw.length >= 5 ? raw.substring(0, 5) : raw;
    return ScheduleModel(
      id: row['id'] as String,
      routeId: row['route_id'] as String,
      departureTime: hhmm,
      dayType: DayType.fromString(row['day_type'] as String? ?? 'weekday'),
    );
  }

  static DayType _todayDayType(DateTime now) {
    return switch (now.weekday) {
      DateTime.saturday => DayType.saturday,
      DateTime.sunday => DayType.sundayHoliday,
      _ => DayType.weekday,
    };
  }

  ScheduleRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == '42501') {
        return ScheduleRepositoryException(
          error: ScheduleRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return ScheduleRepositoryException(
        error: ScheduleRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return ScheduleRepositoryException(
      error: ScheduleRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
