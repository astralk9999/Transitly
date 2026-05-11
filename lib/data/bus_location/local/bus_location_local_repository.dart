import '../../../shared/models/bus_location.dart';
import '../domain/bus_location_repository.dart';

/// Cache in-memory con TTL — sin Hive (los datos caducan en minutos,
/// no merece la pena pagar la latencia de serialización a disco).
/// El SWR llama a `upsert` cada vez que el remoto responde; las
/// lecturas dentro de [ttl] devuelven la entrada cacheada para
/// abrir el camino al stream/snapshot inmediatos.
class BusLocationLocalRepository implements BusLocationRepository {
  BusLocationLocalRepository({Duration? ttl})
      : ttl = ttl ?? const Duration(seconds: 60);

  final Duration ttl;
  final Map<String, _CachedLocation> _byRoute = <String, _CachedLocation>{};

  @override
  Future<BusLocation?> latestForRoute(String routeId) async {
    final entry = _byRoute[routeId];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) {
      _byRoute.remove(routeId);
      return null;
    }
    return entry.location;
  }

  @override
  Stream<BusLocation?> streamForRoute(String routeId) async* {
    yield await latestForRoute(routeId);
  }

  /// Guarda la posición devuelta por el remoto. El timestamp interno
  /// de la entrada es `now`, no `location.recordedAt` — el TTL mide
  /// frescura del fetch, no del dato.
  void upsert(String routeId, BusLocation location) {
    _byRoute[routeId] = _CachedLocation(location, DateTime.now());
  }

  void clear() => _byRoute.clear();
}

class _CachedLocation {
  const _CachedLocation(this.location, this.fetchedAt);
  final BusLocation location;
  final DateTime fetchedAt;
}
