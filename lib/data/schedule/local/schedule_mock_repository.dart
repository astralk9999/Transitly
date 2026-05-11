import '../../../shared/models/enums.dart';
import '../../../shared/models/schedule_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/schedule_repository.dart';

/// Implementación de [ScheduleRepository] sobre [MockDataService].
/// El JSON mock tiene ~880 entradas de horario distribuidas en 20
/// rutas × 3 dayTypes.
class ScheduleMockRepository implements ScheduleRepository {
  ScheduleMockRepository(this._mockData);

  final MockDataService _mockData;

  @override
  Future<List<ScheduleModel>> forRoute(
    String routeId, {
    DayType? dayType,
  }) async {
    final list = _mockData.getSchedulesForRoute(routeId, dayType: dayType);
    final sorted = [...list]
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return sorted;
  }

  @override
  Future<List<ScheduleModel>> nextDepartures(
      String routeId, int count) async {
    return _mockData.getNextDepartures(routeId, '', count);
  }
}
