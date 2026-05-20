import 'package:hive/hive.dart';

import '../../../shared/models/incident_model.dart';
import '../domain/incident_repository.dart';

/// Cache local de incidents. Convención de claves: `incident:<id>`.
class IncidentLocalRepository implements IncidentRepository {
  IncidentLocalRepository(this._box);

  final Box<IncidentModel> _box;

  static String _key(String id) => 'incident:$id';

  @override
  Future<List<IncidentModel>> byAuthor(String authorId) async {
    return _box.values
        .where((i) => i.reporterId == authorId)
        .toList(growable: false);
  }

  @override
  Future<List<IncidentModel>> forRoute(String routeId) async {
    return _box.values
        .where((i) => i.routeId == routeId)
        .toList(growable: false);
  }

  @override
  Future<IncidentModel> create(IncidentModel incident) async {
    await _box.put(_key(incident.id), incident);
    return incident;
  }

  @override
  Future<List<IncidentModel>> listAll({int? limit, int? offset}) async {
    return _box.values.toList(growable: false);
  }

  @override
  Future<IncidentModel> updateStatus(String id, String status) async {
    final existing = _box.get(_key(id));
    if (existing == null) {
      throw IncidentRepositoryException(
        error: IncidentRepositoryError.notFound,
        message: 'Incident not found: $id',
      );
    }
    final updated = existing.copyWith(status: status);
    await _box.put(_key(id), updated);
    return updated;
  }

  Future<void> upsert(IncidentModel incident) async {
    await _box.put(_key(incident.id), incident);
  }

  Future<void> upsertAll(Iterable<IncidentModel> items) async {
    final entries = <String, IncidentModel>{
      for (final i in items) _key(i.id): i,
    };
    await _box.putAll(entries);
  }

  Future<void> clear() async => _box.clear();

  @override
  Stream<IncidentModel?> watch(String id) async* {
    final cached = _box.get(_key(id));
    if (cached != null) yield cached;
  }
}
