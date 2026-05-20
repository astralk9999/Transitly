import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../shared/models/stop_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/stop_repository.dart';

/// Implementación de [StopRepository] sobre [MockDataService] para
/// modo invitado o tests sin Supabase. Usa los 598 stops de COMUJESA
/// del JSON mock.
class StopMockRepository implements StopRepository {
  StopMockRepository(this._mockData);

  final MockDataService _mockData;

  @override
  Future<List<StopModel>> nearby(
    LatLng center,
    {double radiusM = 1000, int limit = 50}
  ) async {
    // MockDataService.getNearbyStops solo acepta count. Pedimos un
    // poco más y filtramos por radio aquí.
    final candidates = _mockData.getNearbyStops(
      center.latitude,
      center.longitude,
      math.min(limit * 2, 200),
    );
    final result = <StopModel>[];
    for (final s in candidates) {
      if (result.length >= limit) break;
      final d = _distanceMeters(center, LatLng(s.lat, s.lng));
      if (d <= radiusM) result.add(s);
    }
    return result;
  }

  @override
  Future<StopModel?> byId(String id) async => _mockData.getStopById(id);

  @override
  Stream<StopModel?> watch(String id) async* {
    yield await byId(id);
  }

  @override
  Future<List<StopModel>> byOperator(String operatorId, {int? limit, int? offset}) async {
    // El JSON mock solo tiene un operador (COMUJESA). Si coincide
    // devolvemos todas las paradas; si no, vacío.
    return _mockData.operator_.id == operatorId
        ? _mockData.stops
        : const [];
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }
}
