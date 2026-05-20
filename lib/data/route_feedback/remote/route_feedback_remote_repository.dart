import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_feedback_model.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/route_feedback_repository.dart';

/// Implementación remota sobre Supabase. `create` integra la cola
/// offline (F3.3) con la misma semántica que IncidentReport.
class RouteFeedbackRemoteRepository implements RouteFeedbackRepository {
  RouteFeedbackRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:RouteFeedback:Remote';

  @override
  Future<List<RouteFeedbackModel>> byAuthor(String authorId) async {
    try {
      final rows = await _client
          .from('route_feedback')
          .select()
          .eq('author_id', authorId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'byAuthor($authorId)');
    }
  }

  @override
  Future<List<RouteFeedbackModel>> forRoute(String routeId) async {
    try {
      final rows = await _client
          .from('route_feedback')
          .select()
          .eq('route_id', routeId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'forRoute($routeId)');
    }
  }

  @override
  Future<RouteFeedbackModel> create(RouteFeedbackModel feedback) async {
    final withId = feedback.id.isEmpty
        ? feedback.copyWith(id: generateUuidV4())
        : feedback;
    final payload = _toDbRow(withId);

    try {
      final row = await _client
          .from('route_feedback')
          .insert(payload)
          .select()
          .single();
      return _fromRow(row);
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'create');
    } catch (e) {
      AppLogger.warn(_logTag, 'create network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: withId.id,
          kind: PendingActionKind.createRouteFeedback,
          payload: payload,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return withId;
    }
  }

  @override
  Future<List<RouteFeedbackModel>> listAll() async {
    try {
      final rows = await _client
          .from('route_feedback')
          .select()
          .order('created_at', ascending: false);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'listAll');
    }
  }

  @override
  Future<RouteFeedbackModel> updateStatus(String id, String status) async {
    final dbStatus = status == 'resolved' ? 'applied' : status;
    final payload = <String, dynamic>{
      'status': dbStatus,
      if (status == 'resolved')
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final row = await _client
          .from('route_feedback')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return _fromRow(row);
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'updateStatus($id)');
    } catch (e) {
      AppLogger.warn(_logTag, 'updateStatus network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: id,
          kind: PendingActionKind.updateFeedbackStatus,
          payload: <String, dynamic>{'id': id, 'status': status},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      rethrow;
    }
  }

  RouteFeedbackModel _fromRow(Map<String, dynamic> row) {
    final attachments = (row['attachments'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];
    return RouteFeedbackModel(
      id: row['id'] as String,
      userId: row['author_id'] as String? ?? '',
      routeId: row['route_id'] as String? ?? '',
      stopId: row['stop_id'] as String?,
      feedbackType: _typeFromDbKind(row['kind'] as String? ?? 'other'),
      description: row['description'] as String? ?? '',
      photoUrls: attachments,
      status:
          _statusFromDbStatus(row['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> _toDbRow(RouteFeedbackModel m) {
    return <String, dynamic>{
      'id': m.id,
      'kind': _dbKindFor(m.feedbackType),
      'status': _dbStatusFor(m.status),
      if (m.routeId.isNotEmpty) 'route_id': m.routeId,
      // stop_id: igual que en IncidentReport — el modelo guarda el
      // texto del mock ('JER-001'), no UUID. Lo omitimos hasta que
      // el caller resuelva el id real via StopRepository.
      'description': m.description,
      if (m.photoUrls.isNotEmpty) 'attachments': m.photoUrls,
      'author_id': m.userId,
      'created_at': m.createdAt.toIso8601String(),
    };
  }

  /// FeedbackType (12 valores en el modelo) → feedback_kind DB (4):
  /// stop_change, schedule_error, info_correction, other.
  static String _dbKindFor(FeedbackType t) => switch (t) {
        FeedbackType.stopMissing ||
        FeedbackType.stopRemoved ||
        FeedbackType.stopName ||
        FeedbackType.stopLocation ||
        FeedbackType.stopOrder =>
          'stop_change',
        FeedbackType.scheduleOutdated ||
        FeedbackType.scheduleMissing ||
        FeedbackType.scheduleAdded =>
          'schedule_error',
        FeedbackType.generalInfo ||
        FeedbackType.suggestion ||
        FeedbackType.positive ||
        FeedbackType.routePath =>
          'info_correction',
      };

  static FeedbackType _typeFromDbKind(String dbKind) => switch (dbKind) {
        'stop_change' => FeedbackType.stopLocation,
        'schedule_error' => FeedbackType.scheduleOutdated,
        'info_correction' => FeedbackType.generalInfo,
        _ => FeedbackType.generalInfo,
      };

  /// FeedbackStatus (6 valores) → feedback_status DB (4): open,
  /// in_review, applied, rejected.
  static String _dbStatusFor(FeedbackStatus s) => switch (s) {
        FeedbackStatus.submitted => 'open',
        FeedbackStatus.inReview => 'in_review',
        FeedbackStatus.accepted || FeedbackStatus.applied => 'applied',
        FeedbackStatus.rejected || FeedbackStatus.duplicate => 'rejected',
      };

  static FeedbackStatus _statusFromDbStatus(String s) => switch (s) {
        'open' => FeedbackStatus.submitted,
        'in_review' => FeedbackStatus.inReview,
        'applied' => FeedbackStatus.applied,
        'rejected' => FeedbackStatus.rejected,
        _ => FeedbackStatus.submitted,
      };

  RouteFeedbackRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return RouteFeedbackRepositoryException(
          error: RouteFeedbackRepositoryError.notFound,
          message: 'Feedback not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return RouteFeedbackRepositoryException(
          error: RouteFeedbackRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      if (code != null && code.startsWith('23')) {
        return RouteFeedbackRepositoryException(
          error: RouteFeedbackRepositoryError.validation,
          message: 'Constraint violation: ${e.message}',
          cause: e,
          stackTrace: st,
        );
      }
      return RouteFeedbackRepositoryException(
        error: RouteFeedbackRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return RouteFeedbackRepositoryException(
      error: RouteFeedbackRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
