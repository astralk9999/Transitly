import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/operator_model.dart';
import '../domain/operator_repository.dart';

/// Implementación remota de [OperatorRepository] sobre Supabase.
/// Lee de la tabla `operators` y de la función SQL `nearby_operators`
/// (F2.5).
class OperatorRemoteRepository implements OperatorRepository {
  OperatorRemoteRepository(this._client);

  final SupabaseClient _client;

  static const _logTag = 'Repo:Operator:Remote';

  @override
  Future<List<OperatorModel>> list() async {
    try {
      final rows = await _client.from('operators').select();
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'list');
    }
  }

  @override
  Future<OperatorModel?> byId(String id) async {
    try {
      final row = await _client
          .from('operators')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'byId($id)');
    }
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    try {
      final result = await _client.rpc(
        'nearby_operators',
        params: <String, dynamic>{
          'p_lat': center.latitude,
          'p_lng': center.longitude,
          'p_radius_m': radiusM.toInt(),
        },
      );
      return (result as List<dynamic>)
          .map((e) => _fromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw _mapError(e, st, 'nearby');
    }
  }

  /// Mapea una fila de Supabase al modelo Dart. La tabla `operators`
  /// tiene más columnas que [OperatorModel] (slug, country, gtfs_url,
  /// bbox, etc.); las omitidas se ignoran o se usan como fallback.
  OperatorModel _fromRow(Map<String, dynamic> row) => OperatorModel(
        id: row['id'] as String,
        name: row['name'] as String,
        shortName: (row['slug'] as String?)?.toUpperCase() ??
            row['name'] as String,
        region: row['region'] as String? ?? '',
        website: row['website'] as String? ?? '',
        // La tabla operators no almacena phone — mantener el campo
        // del modelo vacío hasta que F8 expanda el schema.
        phone: '',
      );

  OperatorRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return OperatorRepositoryException(
          error: OperatorRepositoryError.notFound,
          message: 'Operator not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return OperatorRepositoryException(
          error: OperatorRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return OperatorRepositoryException(
        error: OperatorRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return OperatorRepositoryException(
      error: OperatorRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
