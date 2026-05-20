import 'package:hive/hive.dart';

import '../../../shared/models/route_feedback_model.dart';
import '../domain/route_feedback_repository.dart';
import '../route_feedback_helpers.dart';

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
  Future<List<RouteFeedbackModel>> listAll({int? limit, int? offset}) async {
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
    final fbStatus = feedbackStatusFromString(status);
    final updated = existing.copyWith(status: fbStatus);
    await _box.put(_key(id), updated);
    return updated;
  }

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

  @override
  Stream<RouteFeedbackModel?> watch(String id) async* {
    final cached = _box.get(_key(id));
    if (cached != null) yield cached;
  }
}
