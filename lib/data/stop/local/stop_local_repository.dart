import 'dart:math' as math;

import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/stop_model.dart';
import '../domain/stop_repository.dart';

/// Cache Hive de paradas. Convención de claves:
///   `stop:<id>`              → fila completa
///   `stop:byOp:<operatorId>` → lista deserializable de StopModel,
///                              guardada como String JSON en otra
///                              caja (no aquí). Por ahora mantenemos
///                              solo el inverted index de IDs en
///                              memoria al cargar.
class StopLocalRepository implements StopRepository {
  StopLocalRepository(this._box);

  final Box<StopModel> _box;

  static String _key(String id) => 'stop:$id';

  @override
  Future<List<StopModel>> nearby(
    LatLng center,
    {double radiusM = 1000, int limit = 50}
  ) async {
    final all = _box.values.toList(growable: false);
    final withDist = <_StopWithDistance>[
      for (final s in all)
        _StopWithDistance(s, _haversineMeters(center, LatLng(s.lat, s.lng))),
    ];
    withDist.removeWhere((e) => e.distance > radiusM);
    withDist.sort((a, b) => a.distance.compareTo(b.distance));
    return withDist
        .take(limit)
        .map((e) => e.stop)
        .toList(growable: false);
  }

  @override
  Future<StopModel?> byId(String id) async => _box.get(_key(id));

  @override
  Stream<StopModel?> watch(String id) async* {
    yield await byId(id);
    // Hive expone Box.watch(key:) si quisiéramos escuchar cambios en
    // la cache. La capa SWR ya emite el fresh cuando el remoto
    // responde, así que no añadimos otra fuente aquí.
  }

  @override
  Future<List<StopModel>> byOperator(String operatorId, {int? limit, int? offset}) async {
    // El StopModel actual no expone operatorId (heredado del JSON
    // mock), así que esta cache no puede filtrar por operador. La
    // capa SWR delega siempre al remoto para esta query.
    return const [];
  }

  Future<void> upsert(StopModel stop) async {
    await _box.put(_key(stop.id), stop);
  }

  Future<void> upsertAll(Iterable<StopModel> stops) async {
    final entries = <String, StopModel>{
      for (final s in stops) _key(s.id): s,
    };
    await _box.putAll(entries);
  }

  Future<void> deleteById(String id) async {
    await _box.delete(_key(id));
  }

  Future<void> clear() async {
    await _box.clear();
  }

  static double _haversineMeters(LatLng a, LatLng b) {
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

class _StopWithDistance {
  const _StopWithDistance(this.stop, this.distance);
  final StopModel stop;
  final double distance;
}
