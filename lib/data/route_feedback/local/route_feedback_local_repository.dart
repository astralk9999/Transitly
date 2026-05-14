import 'package:hive/hive.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/route_feedback_model.dart';
import '../domain/route_feedback_repository.dart';

/// Cache local de feedbacks. Convención: `feedback:<id>`.
class RouteFeedbackLocalRepository implements RouteFeedbackRepository {
  RouteFeedbackLocalRepository(this._box);

  final Box<RouteFeedbackModel> _box;

  static String _key(String id) => 'feedback:$id';

  @override
  Future<List<RouteFeedbackModel>> byAuthor(String authorId) async {
    return _box.values
        .where((f) => f.userId == authorId)
        .toList(growable: false);
  }

  @override
  Future<List<RouteFeedbackModel>> forRoute(String routeId) async {
    return _box.values
        .where((f) => f.routeId == routeId)
        .toList(growable: false);
  }

  @override
  Future<RouteFeedbackModel> create(RouteFeedbackModel feedback) async {
    await _box.put(_key(feedback.id), feedback);
    return feedback;
  }

  @override
  Future<List<RouteFeedbackModel>> listAll() async {
    return _box.values.toList(growable: false);
  }

  @override
  Future<RouteFeedbackModel> updateStatus(String id, String status) async {
    final existing = _box.get(_key(id));
    if (existing == null) {
      throw RouteFeedbackRepositoryException(
        error: RouteFeedbackRepositoryError.notFound,
        message: 'Feedback not found: $id',
      );
    }
    final fbStatus = _feedbackStatusFromString(status);
    final updated = existing.copyWith(status: fbStatus);
    await _box.put(_key(id), updated);
    return updated;
  }

  static FeedbackStatus _feedbackStatusFromString(String s) => switch (s) {
        'open' => FeedbackStatus.submitted,
        'in_review' => FeedbackStatus.inReview,
        'resolved' || 'applied' => FeedbackStatus.applied,
        'rejected' => FeedbackStatus.rejected,
        _ => FeedbackStatus.submitted,
      };

  Future<void> upsert(RouteFeedbackModel f) async {
    await _box.put(_key(f.id), f);
  }

  Future<void> upsertAll(Iterable<RouteFeedbackModel> items) async {
    final entries = <String, RouteFeedbackModel>{
      for (final f in items) _key(f.id): f,
    };
    await _box.putAll(entries);
  }

  Future<void> clear() async => _box.clear();
}
