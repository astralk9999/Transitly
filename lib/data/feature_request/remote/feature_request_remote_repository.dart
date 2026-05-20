import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/models/feature_request.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/feature_request_repository.dart';

/// Implementación remota sobre Supabase. El schema de
/// `feature_requests` casa 1:1 con [FeatureRequest] (los enums
/// `feature_request_kind` y `feature_request_status` usan los
/// mismos nombres camelCase que los enums Dart), así que el
/// `toJson`/`fromJson` autogenerado por `json_serializable`
/// funciona sin transformación.
class FeatureRequestRemoteRepository implements FeatureRequestRepository {
  FeatureRequestRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:FeatureRequest:Remote';

  @override
  Future<List<FeatureRequest>> list({int? limit, int? offset}) async {
    try {
      dynamic query = _client.from('feature_requests').select().order('created_at', ascending: false);
      if (offset != null && limit != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }
      final rows = await query;
      return (rows as List<dynamic>).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'list');
    }
  }

  @override
  Future<FeatureRequest?> byId(String id) async {
    try {
      final row = await _client
          .from('feature_requests')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'byId($id)');
    }
  }

  @override
  Future<FeatureRequest> create(FeatureRequest request) async {
    final withId = request.id.isEmpty
        ? request.copyWith(id: generateUuidV4())
        : request;
    final payload = _toDbRow(withId);

    try {
      final row = await _client
          .from('feature_requests')
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
          kind: PendingActionKind.createFeatureRequest,
          payload: payload,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return withId;
    }
  }

  @override
  Future<int> castVote(String requestId) async {
    try {
      final result = await _client.rpc(
        'cast_feature_request_vote',
        params: <String, dynamic>{'p_request_id': requestId},
      );
      return (result as num).toInt();
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'castVote($requestId)');
    } catch (e) {
      AppLogger.warn(_logTag, 'castVote network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: 'vote-feature-$requestId-${DateTime.now().millisecondsSinceEpoch}',
          kind: PendingActionKind.voteFeatureRequest,
          payload: <String, dynamic>{'p_request_id': requestId},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return -1;
    }
  }

  FeatureRequest _fromRow(Map<String, dynamic> row) {
    // El JSON de Postgrest mapea camelCase de enums tal cual; el
    // `_$FeatureRequestFromJson` lo digiere. Solo aplanamos las
    // columnas con nombres distintos (author_id, admin_notes,
    // assignee_id, created_at) a las claves que el modelo espera.
    return FeatureRequest.fromJson(<String, dynamic>{
      'id': row['id'],
      'title': row['title'],
      'description': row['description'] ?? '',
      'submittedBy': row['author_id'],
      'category': row['kind'],
      'priority': row['priority'],
      'status': row['status'],
      'votes': row['votes'],
      if (row['payload'] != null) 'payload': row['payload'],
      'createdAt': row['created_at'],
      'updatedAt': row['created_at'], // no hay updated_at en la tabla
      if (row['admin_notes'] != null) 'adminNotes': row['admin_notes'],
      if (row['assignee_id'] != null) 'assigneeId': row['assignee_id'],
    });
  }

  Map<String, dynamic> _toDbRow(FeatureRequest r) {
    return <String, dynamic>{
      'id': r.id,
      'kind': r.category.name,
      'status': r.status.name,
      'priority': r.priority.name,
      'title': r.title,
      'description': r.description,
      if (r.payload != null) 'payload': r.payload,
      'votes': r.votes,
      'author_id': r.submittedBy,
      if (r.adminNotes != null) 'admin_notes': r.adminNotes,
      if (r.assigneeId != null) 'assignee_id': r.assigneeId,
      'created_at': r.createdAt.toIso8601String(),
    };
  }

  FeatureRequestRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return FeatureRequestRepositoryException(
          error: FeatureRequestRepositoryError.notFound,
          message: 'Feature request not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return FeatureRequestRepositoryException(
          error: FeatureRequestRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      if (code != null && code.startsWith('23')) {
        return FeatureRequestRepositoryException(
          error: FeatureRequestRepositoryError.validation,
          message: 'Constraint violation: ${e.message}',
          cause: e,
          stackTrace: st,
        );
      }
      return FeatureRequestRepositoryException(
        error: FeatureRequestRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return FeatureRequestRepositoryException(
      error: FeatureRequestRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
