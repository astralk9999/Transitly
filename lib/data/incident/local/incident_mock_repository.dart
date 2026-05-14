import '../../../shared/models/incident_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/incident_repository.dart';

/// Implementación de [IncidentRepository] sobre [MockDataService].
/// La lista inicial del JSON mock es read-only; los `create` en
/// modo invitado se acumulan en una lista en memoria que vive solo
/// hasta el reinicio.
class IncidentMockRepository implements IncidentRepository {
  IncidentMockRepository(this._mockData);

  final MockDataService _mockData;
  final List<IncidentModel> _ephemeralCreates = <IncidentModel>[];
  final Map<String, IncidentModel> _modifications = <String, IncidentModel>{};

  Iterable<IncidentModel> get _all sync* {
    for (final i in _mockData.incidents) {
      yield _modifications[i.id] ?? i;
    }
    for (final i in _ephemeralCreates) {
      yield _modifications[i.id] ?? i;
    }
  }

  @override
  Future<List<IncidentModel>> byAuthor(String authorId) async {
    return _all
        .where((i) => i.reporterId == authorId)
        .toList(growable: false);
  }

  @override
  Future<List<IncidentModel>> forRoute(String routeId) async {
    return _all
        .where((i) => i.routeId == routeId)
        .toList(growable: false);
  }

  @override
  Future<IncidentModel> create(IncidentModel incident) async {
    _ephemeralCreates.add(incident);
    return incident;
  }

  @override
  Future<List<IncidentModel>> listAll() async {
    return _all.toList(growable: false);
  }

  @override
  Future<IncidentModel> updateStatus(String id, String status) async {
    final existing = _all.firstWhere((i) => i.id == id);
    final updated = existing.copyWith(status: status);
    _modifications[id] = updated;
    return updated;
  }
}
