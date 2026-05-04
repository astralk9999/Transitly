import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data_service.dart';
import '../../models/enums.dart';
import '../../models/schedule_model.dart';

/// Número de salidas devueltas si el caller no especifica `count`.
const int defaultUpcomingCount = 3;

/// Salidas ordenadas por hora para una ruta y tipo de día.
///
/// Si [count] es `null`, devuelve todas las salidas del día ordenadas
/// (caso del wizard "Iniciar ruta", que muestra el día completo). Si
/// [count] es un entero, devuelve las primeras N — útil para vistas
/// resumen tipo "Próximas salidas (3)".
final upcomingDeparturesForRouteProvider = Provider.family<
    List<ScheduleModel>,
    ({String routeId, int? count, DayType dayType})>((ref, args) {
  final mockData = ref.watch(mockDataServiceProvider);
  final all =
      mockData.getSchedulesForRoute(args.routeId, dayType: args.dayType);
  final sorted = [...all]
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  if (args.count == null) return sorted;
  return sorted.take(args.count!).toList();
});

/// Frecuencia media en minutos entre salidas de [routeId] en un día
/// laborable. `null` si la ruta tiene menos de 2 salidas (frecuencia no
/// definida).
///
/// Calcula: ordena horas → suma diferencias entre consecutivas →
/// divide entre N-1 → redondea.
final routeFrequencyProvider =
    Provider.family<int?, String>((ref, routeId) {
  final mockData = ref.watch(mockDataServiceProvider);
  final schedules =
      mockData.getSchedulesForRoute(routeId, dayType: DayType.weekday);
  if (schedules.length < 2) return null;
  final times = schedules
      .map((s) {
        final parts = s.departureTime.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      })
      .toList()
    ..sort();
  var totalDiff = 0;
  for (var i = 1; i < times.length; i++) {
    totalDiff += times[i] - times[i - 1];
  }
  return (totalDiff / (times.length - 1)).round();
});
