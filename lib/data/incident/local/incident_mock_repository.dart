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

  Iterable<IncidentModel> get _all =>
      [..._mockData.incidents, ..._ephemeralCreates];

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
}
