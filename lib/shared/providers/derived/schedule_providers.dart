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
