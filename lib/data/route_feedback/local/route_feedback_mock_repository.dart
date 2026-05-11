import '../../../shared/models/route_feedback_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/route_feedback_repository.dart';

/// Implementación de [RouteFeedbackRepository] sobre [MockDataService]
/// para modo invitado.
class RouteFeedbackMockRepository implements RouteFeedbackRepository {
  RouteFeedbackMockRepository(this._mockData);

  final MockDataService _mockData;
  final List<RouteFeedbackModel> _ephemeralCreates = <RouteFeedbackModel>[];

  Iterable<RouteFeedbackModel> get _all =>
      [..._mockData.feedbacks, ..._ephemeralCreates];

  @override
  Future<List<RouteFeedbackModel>> byAuthor(String authorId) async {
    return _all
        .where((f) => f.userId == authorId)
        .toList(growable: false);
  }

  @override
  Future<List<RouteFeedbackModel>> forRoute(String routeId) async {
    return _all
        .where((f) => f.routeId == routeId)
        .toList(growable: false);
  }

  @override
  Future<RouteFeedbackModel> create(RouteFeedbackModel feedback) async {
    _ephemeralCreates.add(feedback);
    return feedback;
  }
}
