import 'mock_data_service.dart';
import '../../shared/models/stop_model.dart';

extension MockDataServiceExt on MockDataService {
  List<StopModel> getUniqueStopsForRoute(String routeId) {
    final seen = <String>{};
    final result = <StopModel>[];
    for (final s in getStopsForRoute(routeId)) {
      if (seen.add(s.id)) result.add(s);
    }
    return result;
  }
}
