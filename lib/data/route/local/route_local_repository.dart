import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';
import '../domain/route_repository.dart';

/// Cache local de rutas sobre Hive. Convención de claves:
///   `route:<id>` — fila completa.
class RouteLocalRepository implements RouteRepository {
  RouteLocalRepository(this._box);

  final Box<RouteModel> _box;

  static String _key(String id) => 'route:$id';

  @override
  Future<List<RouteModel>> byOperator(String operatorId) async {
    return _box.values
        .where((r) => r.operatorId == operatorId)
        .toList(growable: false);
  }

  @override
  Future<RouteModel?> byId(String id) async => _box.get(_key(id));

  @override
  Stream<RouteModel?> watch(String id) async* {
    yield await byId(id);
  }

  @override
  Future<List<RouteModel>> community(String ownerId) async {
    // RouteModel no expone owner_id (heredado del JSON mock). El SWR
    // delega siempre al remoto para esta query.
    return const [];
  }

  @override
  Future<List<RouteModel>> intersectingBbox(LatLng sw, LatLng ne) async {
    // RouteModel no expone geom (las polylines viven en
    // MapDataCache, no en el modelo). Cache local no puede filtrar
    // por bbox — el SWR delega al remoto.
    return const [];
  }

  Future<void> upsert(RouteModel route) async {
    await _box.put(_key(route.id), route);
  }

  Future<void> upsertAll(Iterable<RouteModel> routes) async {
    final entries = <String, RouteModel>{
      for (final r in routes) _key(r.id): r,
    };
    await _box.putAll(entries);
  }

  Future<void> deleteById(String id) async {
    await _box.delete(_key(id));
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
