import 'dart:math' as math;

import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/operator_model.dart';
import '../domain/operator_repository.dart';

/// Implementación local de [OperatorRepository] sobre Hive. Cache
/// persistente entre sesiones; se rehidrata desde Supabase vía
/// stale-while-revalidate.
///
/// Convención de claves (ARCHITECTURE.md §6.4):
///   `op:<id>`  → fila completa.
class OperatorLocalRepository implements OperatorRepository {
  OperatorLocalRepository(this._box);

  final Box<OperatorModel> _box;

  static String _key(String id) => 'op:$id';

  @override
  Future<List<OperatorModel>> list() async {
    return _box.values.toList(growable: false);
  }

  @override
  Future<OperatorModel?> byId(String id) async {
    return _box.get(_key(id));
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    // Hive no tiene índice geográfico — barrido lineal sobre todos
    // los operadores cacheados. Asume |operators| pequeño (<100);
    // para datasets más grandes la fuente de verdad es la función
    // SQL `nearby_operators`.
    //
    // OperatorModel hoy no expone bbox (se ignora al cachear). Sin
    // bbox local, devolvemos la lista completa: el SWR refrescará
    // con el resultado real de la BD.
    return list();
  }

  /// Inserta o actualiza una entrada en cache.
  Future<void> upsert(OperatorModel op) async {
    await _box.put(_key(op.id), op);
  }

  /// Inserta o actualiza varias entradas en una sola tanda.
  Future<void> upsertAll(Iterable<OperatorModel> ops) async {
    final entries = <String, OperatorModel>{
      for (final op in ops) _key(op.id): op,
    };
    await _box.putAll(entries);
  }

  Future<void> deleteById(String id) async {
    await _box.delete(_key(id));
  }

  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Future<OperatorModel> create(OperatorModel op) async {
    await _box.put(_key(op.id), op);
    return op;
  }

  @override
  Future<OperatorModel> update(OperatorModel op) async {
    await _box.put(_key(op.id), op);
    return op;
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(_key(id));
  }

  /// Calcula distancia haversine entre dos puntos en metros. Helper
  /// para cuando OperatorModel exponga bbox y podamos filtrar
  /// localmente sin SQL.
  static double haversineMeters(LatLng a, LatLng b) {
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
