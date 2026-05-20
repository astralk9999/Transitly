import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/stop_model.dart';
import '../../sync/realtime_channel_manager.dart';
import '../domain/stop_repository.dart';

/// Implementación remota de [StopRepository] sobre Supabase.
///
/// Mapea el schema de la tabla `stops` (geom POINT, accessibility
/// JSONB, metadata JSONB) al [StopModel] de la app, que vive con un
/// formato simplificado de campos planos heredado del JSON mock.
class StopRemoteRepository implements StopRepository {
  StopRemoteRepository(this._client) : _chManager = RealtimeChannelManager(_client);

  final SupabaseClient _client;
  final RealtimeChannelManager _chManager;

  static const _logTag = 'Repo:Stop:Remote';

  void dispose() {
    _chManager.dispose();
  }

  @override
  Future<List<StopModel>> nearby(
    LatLng center, {
    double radiusM = 1000,
    int limit = 50,
  }) async {
    try {
      final result = await _client.rpc(
        'nearby_stops',
        params: <String, dynamic>{
          'p_lat': center.latitude,
          'p_lng': center.longitude,
          'p_radius_m': radiusM.toInt(),
          'p_limit': limit,
        },
      );
      return (result as List<dynamic>)
          .map((e) => _fromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw _mapError(e, st, 'nearby');
    }
  }

  @override
  Future<StopModel?> byId(String id) async {
    try {
      final row = await _client
          .from('stops')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'byId($id)');
    }
  }

  @override
  Stream<StopModel?> watch(String id) async* {
    try {
      final initial = await byId(id);
      yield initial;
    } catch (_) {
      yield null;
    }
    await for (final row in _chManager.watch(
      channelPrefix: 'stop',
      table: 'stops',
      entityId: id,
      events: [PostgresChangeEvent.all],
    )) {
      yield _fromRow(row);
    }
  }

  @override
  Future<List<StopModel>> byOperator(String operatorId, {int? limit, int? offset}) async {
    try {
      dynamic query = _client
          .from('stops')
          .select()
          .eq('operator_id', operatorId)
          .order('name');
      if (offset != null && limit != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }
      final rows = await query;
      return (rows as List<dynamic>).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'byOperator($operatorId)');
    }
  }

  /// Convierte una fila Supabase de `stops` al [StopModel] de la app.
  ///
  /// Notas:
  /// - `geom` viene como GeoJSON: `{type: 'Point', coordinates: [lng, lat]}`.
  /// - `accessibility` y `metadata` son JSONB; los flags planos del
  ///   StopModel viven dentro.
  /// - Si el modelo Dart no expone una columna del schema (zoneId,
  ///   gtfs_stop_id), se ignora.
  StopModel _fromRow(Map<String, dynamic> row) {
    final geom = row['geom'] as Map<String, dynamic>?;
    final coords = (geom?['coordinates'] as List<dynamic>?) ?? const [0.0, 0.0];
    final lng = (coords.isNotEmpty ? coords[0] as num : 0).toDouble();
    final lat = (coords.length > 1 ? coords[1] as num : 0).toDouble();

    final access = (row['accessibility'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final meta = (row['metadata'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    return StopModel(
      id: row['id'] as String,
      name: row['name'] as String,
      officialCode: row['code'] as String? ?? '',
      lat: lat,
      lng: lng,
      municipality: meta['municipality'] as String? ?? '',
      zoneId: meta['zoneId'] as String?,
      hasShelter: access['hasShelter'] as bool? ?? false,
      hasBench: access['hasBench'] as bool? ?? false,
      isAccessible: access['isAccessible'] as bool? ?? false,
      hasDisplay: access['hasDisplay'] as bool? ?? false,
      photoUrl: meta['photoUrl'] as String?,
      notes: meta['notes'] as String?,
    );
  }

  StopRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return StopRepositoryException(
          error: StopRepositoryError.notFound,
          message: 'Stop not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return StopRepositoryException(
          error: StopRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return StopRepositoryException(
        error: StopRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return StopRepositoryException(
      error: StopRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
