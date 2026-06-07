import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

/// Horas de paso por línea para un tipo de día concreto.
class LineTimes {
  LineTimes({
    required this.routeId,
    required this.code,
    required this.color,
    required this.times,
  });

  final String routeId;
  final String code;
  final String color;
  final List<String> times; // "HH:MM" ordenadas
}

/// Horario completo de una parada: por tipo de día, las líneas que pasan con
/// todas sus horas. Vacío si no hay datos exactos cargados (o sin red).
class StopTimetable {
  StopTimetable(this.byDay);

  /// 'weekday' | 'saturday' | 'sunday_holiday' -> líneas con sus horas.
  final Map<String, List<LineTimes>> byDay;

  bool get isEmpty => byDay.values.every((l) => l.isEmpty);

  List<LineTimes> forDay(String dayType) => byDay[dayType] ?? const [];

  /// Tipos de día con al menos una hora (para pintar solo pestañas útiles).
  List<String> get availableDays =>
      byDay.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();
}

const _logTag = 'StopTimetable';

/// Llama a la RPC `stop_timetable_by_name` y agrupa por día y línea. Tolerante
/// a fallos (sin red / sin sesión) → devuelve un horario vacío.
final stopTimetableProvider =
    FutureProvider.family.autoDispose<StopTimetable, String>((ref, stopName) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final res = await client.rpc('stop_timetable_by_name', params: {
      'p_name': stopName,
    });
    final rows = (res as List).cast<Map<String, dynamic>>();

    // day -> code -> (meta + times)
    final byDay = <String, Map<String, LineTimes>>{};
    for (final r in rows) {
      final day = r['day_type'] as String? ?? 'weekday';
      final code = r['route_code'] as String? ?? '';
      final t = r['pass_time'] as String? ?? '';
      if (t.isEmpty) continue;
      final dayMap = byDay.putIfAbsent(day, () => {});
      final line = dayMap.putIfAbsent(
        code,
        () => LineTimes(
          routeId: r['route_id'] as String? ?? '',
          code: code,
          color: r['route_color'] as String? ?? '#977DDF',
          times: <String>[],
        ),
      );
      line.times.add(t.length >= 5 ? t.substring(0, 5) : t);
    }

    final out = <String, List<LineTimes>>{};
    for (final entry in byDay.entries) {
      final lines = entry.value.values.toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      for (final l in lines) {
        l.times.sort();
      }
      out[entry.key] = lines;
    }
    return StopTimetable(out);
  } catch (e) {
    AppLogger.warn(_logTag, 'rpc stop_timetable_by_name failed for "$stopName"', e);
    return StopTimetable(const {});
  }
});
