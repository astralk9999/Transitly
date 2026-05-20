import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/route_repository.dart';

/// Implementación de [RouteRepository] sobre [MockDataService] para
/// modo invitado. El JSON mock contiene 20 rutas oficiales de
/// COMUJESA; no soporta comunidad ni bbox real (todas las rutas
/// están en Jerez).
class RouteMockRepository implements RouteRepository {
  RouteMockRepository(this._mockData);

  final MockDataService _mockData;

  @override
  Future<List<RouteModel>> byOperator(String operatorId, {int? limit, int? offset}) async {
    return _mockData.operator_.id == operatorId
        ? _mockData.routes
        : const [];
  }

  @override
  Future<RouteModel?> byId(String id) async => _mockData.getRouteById(id);

  @override
  Stream<RouteModel?> watch(String id) async* {
    yield await byId(id);
  }

  @override
  Future<List<RouteModel>> community(String ownerId) async => const [];

  @override
  Future<List<RouteModel>> intersectingBbox(LatLng sw, LatLng ne) async {
    // El mock asume todas las rutas en Jerez. Si el bbox solapa con
    // la zona, devolvemos todas; si no, vacío. Comprobación grosera
    // por centro.
    final centerLat = (sw.latitude + ne.latitude) / 2;
    final centerLng = (sw.longitude + ne.longitude) / 2;
    const jerezBoxHalfDeg = 0.3;
    if ((centerLat - 36.685).abs() < jerezBoxHalfDeg &&
        (centerLng - (-6.126)).abs() < jerezBoxHalfDeg) {
      return _mockData.routes;
    }
    return const [];
  }
}
