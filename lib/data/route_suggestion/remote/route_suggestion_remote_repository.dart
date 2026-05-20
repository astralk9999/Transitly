import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_suggestion_model.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/route_suggestion_repository.dart';

/// Implementación remota sobre Supabase. `create` y `castVote`
/// integran la cola offline (F3.3).
class RouteSuggestionRemoteRepository implements RouteSuggestionRepository {
  RouteSuggestionRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:RouteSuggestion:Remote';

  @override
  Future<List<RouteSuggestionModel>> list() async {
    try {
      final rows = await _client.from('route_suggestions').select();
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'list');
    }
  }

  @override
  Future<RouteSuggestionModel?> byId(String id) async {
    try {
      final row = await _client
          .from('route_suggestions')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'byId($id)');
    }
  }

  @override
  Future<RouteSuggestionModel> create(
      RouteSuggestionModel suggestion) async {
    final withId = suggestion.id.isEmpty
        ? suggestion.copyWith(id: generateUuidV4())
        : suggestion;
    final payload = _toDbRow(withId);

    try {
      final row = await _client
          .from('route_suggestions')
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
          kind: PendingActionKind.createRouteSuggestion,
          payload: payload,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return withId;
    }
  }

  @override
  Future<int> castVote(String suggestionId) async {
    try {
      final result = await _client.rpc(
        'cast_suggestion_vote',
        params: <String, dynamic>{'p_suggestion_id': suggestionId},
      );
      return (result as num).toInt();
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'castVote($suggestionId)');
    } catch (e) {
      AppLogger.warn(
          _logTag, 'castVote network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: 'vote-suggestion-$suggestionId-${DateTime.now().millisecondsSinceEpoch}',
          kind: PendingActionKind.voteSuggestion,
          payload: <String, dynamic>{'p_suggestion_id': suggestionId},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      // El total real lo aplicará el drainer; aquí devolvemos -1 para
      // que el SWR sepa que fue optimista y use cache + 1.
      return -1;
    }
  }

  @override
  Future<RouteSuggestionModel> updateStatus(String id, String status) async {
    try {
      final row = await _client
          .from('route_suggestions')
          .update(<String, dynamic>{
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'updateStatus($id)');
    }
  }

  RouteSuggestionModel _fromRow(Map<String, dynamic> row) {
    final originGeom = row['origin_geom'] as Map<String, dynamic>?;
    final destGeom = row['destination_geom'] as Map<String, dynamic>?;
    return RouteSuggestionModel(
      id: row['id'] as String,
      suggestedBy: row['author_id'] as String? ?? '',
      originText: '',
      destinationText: '',
      originLat: _coordOf(originGeom, 1),
      originLng: _coordOf(originGeom, 0),
      destinationLat: _coordOf(destGeom, 1),
      destinationLng: _coordOf(destGeom, 0),
      notes: row['motivation'] as String?,
      status:
          SuggestionStatus.fromString(row['status'] as String? ?? 'idea'),
      voteCount: (row['votes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static double? _coordOf(Map<String, dynamic>? geom, int index) {
    if (geom == null) return null;
    final coords = geom['coordinates'] as List<dynamic>?;
    if (coords == null || coords.length <= index) return null;
    return (coords[index] as num).toDouble();
  }

  /// Mapeo a fila de `route_suggestions`. origin_geom y
  /// destination_geom como EWKT — Postgres acepta.
  Map<String, dynamic> _toDbRow(RouteSuggestionModel s) {
    final originWkt = (s.originLat != null && s.originLng != null)
        ? 'SRID=4326;POINT(${s.originLng} ${s.originLat})'
        : null;
    final destWkt = (s.destinationLat != null && s.destinationLng != null)
        ? 'SRID=4326;POINT(${s.destinationLng} ${s.destinationLat})'
        : null;
    return <String, dynamic>{
      'id': s.id,
      if (originWkt != null) 'origin_geom': originWkt,
      if (destWkt != null) 'destination_geom': destWkt,
      'motivation': s.notes ?? '${s.originText} → ${s.destinationText}',
      'votes': s.voteCount,
      'status': _dbStatusFor(s.status),
      'author_id': s.suggestedBy,
      'created_at': s.createdAt.toIso8601String(),
    };
  }

  /// SuggestionStatus (7 valores) → suggestion_status DB (4): open,
  /// considered, accepted, rejected.
  static String _dbStatusFor(SuggestionStatus s) => switch (s) {
        SuggestionStatus.idea => 'open',
        SuggestionStatus.inReview ||
        SuggestionStatus.enriched =>
          'considered',
        SuggestionStatus.accepted ||
        SuggestionStatus.converted =>
          'accepted',
        SuggestionStatus.rejected ||
        SuggestionStatus.duplicate =>
          'rejected',
      };

  RouteSuggestionRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return RouteSuggestionRepositoryException(
          error: RouteSuggestionRepositoryError.notFound,
          message: 'Suggestion not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return RouteSuggestionRepositoryException(
          error: RouteSuggestionRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      if (code != null && code.startsWith('23')) {
        return RouteSuggestionRepositoryException(
          error: RouteSuggestionRepositoryError.validation,
          message: 'Constraint violation: ${e.message}',
          cause: e,
          stackTrace: st,
        );
      }
      return RouteSuggestionRepositoryException(
        error: RouteSuggestionRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return RouteSuggestionRepositoryException(
      error: RouteSuggestionRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
