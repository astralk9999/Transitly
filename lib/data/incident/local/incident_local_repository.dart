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
}
