import '../../../shared/models/enums.dart';
import '../../../shared/models/route_feedback_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/route_feedback_repository.dart';

/// Implementación de [RouteFeedbackRepository] sobre [MockDataService]
/// para modo invitado.
class RouteFeedbackMockRepository implements RouteFeedbackRepository {
  RouteFeedbackMockRepository(this._mockData);

  final MockDataService _mockData;
  final List<RouteFeedbackModel> _ephemeralCreates = <RouteFeedbackModel>[];
  final Map<String, RouteFeedbackModel> _modifications = <String, RouteFeedbackModel>{};

  Iterable<RouteFeedbackModel> get _all sync* {
    for (final f in _mockData.feedbacks) {
      yield _modifications[f.id] ?? f;
    }
    for (final f in _ephemeralCreates) {
      yield _modifications[f.id] ?? f;
    }
  }

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

  @override
  Future<List<RouteFeedbackModel>> listAll() async {
    return _all.toList(growable: false);
  }

  @override
  Future<RouteFeedbackModel> updateStatus(String id, String status) async {
    final existing = _all.firstWhere((f) => f.id == id);
    final fbStatus = _feedbackStatusFromString(status);
    final updated = existing.copyWith(status: fbStatus);
    _modifications[id] = updated;
    return updated;
  }

  static FeedbackStatus _feedbackStatusFromString(String s) => switch (s) {
        'open' => FeedbackStatus.submitted,
        'in_review' => FeedbackStatus.inReview,
        'resolved' || 'applied' => FeedbackStatus.applied,
        'rejected' => FeedbackStatus.rejected,
        _ => FeedbackStatus.submitted,
      };
}
