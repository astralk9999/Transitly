import '../../../shared/models/bus_location.dart';
import '../../../shared/models/enums.dart';
import '../../mock/mock_data_service.dart';
import '../domain/bus_location_repository.dart';

/// Implementación de [BusLocationRepository] sobre [MockDataService].
/// Sintetiza un [BusLocation] desde el `ActiveTripModel` (lat, lng,
/// bearing, startedAt) que el JSON mock provee para 4 viajes activos
/// de demostración.
class BusLocationMockRepository implements BusLocationRepository {
  BusLocationMockRepository(this._mockData);

  final MockDataService _mockData;

  @override
  Future<BusLocation?> latestForRoute(String routeId) async {
    final trip = _mockData.activeTrips
        .where((t) =>
            t.routeId == routeId &&
            t.status != TripStatus.cancelled &&
            t.status != TripStatus.completed)
        .cast<dynamic>()
        .firstWhere((_) => true, orElse: () => null);
    if (trip == null) return null;
    final lat = trip.currentLat as double?;
    final lng = trip.currentLng as double?;
    if (lat == null || lng == null) return null;
    return BusLocation(
      lat: lat,
      lng: lng,
      bearing: trip.currentBearing as double?,
      recordedAt: (trip.startedAt as DateTime?) ?? DateTime.now(),
    );
  }

  @override
  Stream<BusLocation?> streamForRoute(String routeId) async* {
    yield await latestForRoute(routeId);
  }
}
