import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/incident_model.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/incident_repository.dart';

/// Implementación remota de [IncidentRepository] sobre Supabase.
///
/// El método `create` integra la cola offline: si Supabase devuelve
/// un error sin clasificar (típicamente network / DNS / timeout),
/// el incident se serializa al schema DB y se encola en
/// `pending_actions`. Al UI se le devuelve el incident con un UUID
/// estable, así puede mostrarlo y refrescar el cache local sin
/// esperar la confirmación del servidor.
class IncidentRemoteRepository implements IncidentRepository {
  IncidentRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:Incident:Remote';

  @override
  Future<List<IncidentModel>> byAuthor(String authorId) async {
    try {
      final rows = await _client
          .from('incidents')
          .select()
          .eq('author_id', authorId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'byAuthor($authorId)');
    }
  }

  @override
  Future<List<IncidentModel>> forRoute(String routeId) async {
    try {
      final rows = await _client
          .from('incidents')
          .select()
          .eq('route_id', routeId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'forRoute($routeId)');
    }
  }

  @override
  Future<IncidentModel> create(IncidentModel incident) async {
    // Asegurar id estable. Si el caller no lo pone, generamos uno;
    // así el mismo id sirve para la copia optimista local, la
    // entrada en cola y el insert remoto.
    final withId =
        incident.id.isEmpty ? incident.copyWith(id: generateUuidV4()) : incident;
    final payload = _toDbRow(withId);

    try {
      final row = await _client
          .from('incidents')
          .insert(payload)
          .select()
          .single();
      return _fromRow(row);
    } on PostgrestException catch (e, st) {
      // Permisos o validación: NO encolar — el reintento no
      // arreglaría nada.
      throw _mapError(e, st, 'create');
    } catch (e) {
      AppLogger.warn(_logTag, 'create network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: withId.id,
          kind: PendingActionKind.createIncident,
          payload: payload,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return withId;
    }
  }

  @override
  Future<List<IncidentModel>> listAll() async {
    try {
      final rows = await _client
          .from('incidents')
          .select()
          .order('created_at', ascending: false);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'listAll');
    }
  }

  @override
  Future<IncidentModel> updateStatus(String id, String status) async {
    final payload = <String, dynamic>{
      'status': status,
      if (status == 'resolved')
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final row = await _client
          .from('incidents')
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
          kind: PendingActionKind.updateIncidentStatus,
          payload: <String, dynamic>{'id': id, 'status': status},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      rethrow;
    }
  }

  /// Convierte una fila Supabase a [IncidentModel].
  IncidentModel _fromRow(Map<String, dynamic> row) {
    return IncidentModel(
      id: row['id'] as String,
      reporterId: row['author_id'] as String? ?? '',
      routeId: row['route_id'] as String? ?? '',
      stopId: row['stop_id'] as String?,
      incidentType: _typeFromDbKind(row['kind'] as String? ?? 'other'),
      category: IncidentModel.fromJson(<String, dynamic>{
        'id': '', 'reportedBy': '', 'lineCode': '',
        'type': _typeFromDbKind(row['kind'] as String? ?? 'other').name,
        'status': '', 'confirmations': 0,
        'reportedAt': row['created_at'] as String,
      }).category,
      comment: row['description'] as String?,
      status: row['status'] as String? ?? 'open',
      confirmations: 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Mapeo IncidentModel → fila para la tabla `incidents`. El schema
  /// DB tiene menos columnas que el modelo Dart (no almacena
  /// category, confirmations, ni stopName-as-text); el extra se omite.
  Map<String, dynamic> _toDbRow(IncidentModel m) {
    return <String, dynamic>{
      'id': m.id,
      'kind': _dbKindFor(m.incidentType),
      'status': _dbStatusFor(m.status),
      if (m.routeId.isNotEmpty) 'route_id': m.routeId,
      // stop_id es UUID en DB; si el modelo trae un código tipo
      // 'JER-001' (legacy mock), lo omitimos — el caller debería
      // resolver el UUID vía StopRepository antes de crear.
      if (m.comment != null && m.comment!.isNotEmpty)
        'description': m.comment,
      'author_id': m.reporterId,
      'created_at': m.createdAt.toIso8601String(),
    };
  }

  /// Colapsa los 10+ valores de `IncidentType` al enum DB de 5
  /// (`incident_kind`: delay, no_show, congestion, accident, other).
  static String _dbKindFor(IncidentType t) => switch (t) {
        IncidentType.delay => 'delay',
        IncidentType.busNoShow => 'no_show',
        IncidentType.busFull => 'congestion',
        // El resto (detour, dangerousDriving, stopBlocked,
        // shelterDamaged, signageMissing, scheduleWrong,
        // accessibilityIssue, etc.) cae en 'other'. F15 podría
        // refinar.
        _ => 'other',
      };

  /// Mapea el string del modelo al enum DB incident_status. Por
  /// defecto 'open' — único valor inicial razonable.
  static String _dbStatusFor(String s) {
    const allowed = {'open', 'in_review', 'resolved', 'rejected'};
    return allowed.contains(s) ? s : 'open';
  }

  static IncidentType _typeFromDbKind(String dbKind) => switch (dbKind) {
        'delay' => IncidentType.delay,
        'no_show' => IncidentType.busNoShow,
        'congestion' => IncidentType.busFull,
        'accident' => IncidentType.dangerousDriving,
        _ => IncidentType.busNoShow,
      };

  IncidentRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return IncidentRepositoryException(
          error: IncidentRepositoryError.notFound,
          message: 'Incident not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return IncidentRepositoryException(
          error: IncidentRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      if (code != null && code.startsWith('23')) {
        return IncidentRepositoryException(
          error: IncidentRepositoryError.validation,
          message: 'Constraint violation: ${e.message}',
          cause: e,
          stackTrace: st,
        );
      }
      return IncidentRepositoryException(
        error: IncidentRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return IncidentRepositoryException(
      error: IncidentRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
