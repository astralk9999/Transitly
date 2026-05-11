import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_model.dart';
import '../domain/route_repository.dart';

/// Implementación remota de [RouteRepository] sobre Supabase.
class RouteRemoteRepository implements RouteRepository {
  RouteRemoteRepository(this._client);

  final SupabaseClient _client;

  static const _logTag = 'Repo:Route:Remote';

  @override
  Future<List<RouteModel>> byOperator(String operatorId) async {
    try {
      final rows = await _client
          .from('routes')
          .select()
          .eq('operator_id', operatorId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'byOperator($operatorId)');
    }
  }

  @override
  Future<RouteModel?> byId(String id) async {
    try {
      final row = await _client
          .from('routes')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'byId($id)');
    }
  }

  @override
  Stream<RouteModel?> watch(String id) async* {
    yield await byId(id);
    // F13: subscribe a `public:routes:id=eq.<id>` y emite cambios.
  }

  @override
  Future<List<RouteModel>> community(String ownerId) async {
    try {
      final rows = await _client
          .from('routes')
          .select()
          .eq('source', 'community')
          .eq('owner_id', ownerId);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'community($ownerId)');
    }
  }

  @override
  Future<List<RouteModel>> intersectingBbox(LatLng sw, LatLng ne) async {
    try {
      // EWKT con SRID 4326 — Postgres parsea sin necesidad de cast
      // explícito. El polígono se cierra repitiendo el primer vértice.
      final wkt = 'SRID=4326;POLYGON((${sw.longitude} ${sw.latitude},'
          ' ${ne.longitude} ${sw.latitude},'
          ' ${ne.longitude} ${ne.latitude},'
          ' ${sw.longitude} ${ne.latitude},'
          ' ${sw.longitude} ${sw.latitude}))';
      final result = await _client.rpc(
        'routes_intersecting_bbox',
        params: <String, dynamic>{'p_bbox': wkt},
      );
      return (result as List<dynamic>)
          .map((e) => _fromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw _mapError(e, st, 'intersectingBbox');
    }
  }

  /// Convierte una fila Supabase de `routes` al [RouteModel] de la app.
  ///
  /// El schema tiene más columnas que el modelo (geom, gtfs_route_id,
  /// description, owner_id, …); las omitidas se ignoran o se usan
  /// como fuente para campos derivados.
  RouteModel _fromRow(Map<String, dynamic> row) {
    final meta = (row['metadata'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final colorHex = row['color'] as String?;
    final routeColor = colorHex != null && colorHex.isNotEmpty
        ? _parseHexColor(colorHex)
        : const Color(0xFF888888);
    final statusStr = row['status'] as String? ?? 'official';

    return RouteModel(
      id: row['id'] as String,
      operatorId: row['operator_id'] as String? ?? '',
      code: row['code'] as String? ?? '',
      name: row['name'] as String,
      serviceType: ServiceType.fromString(
        meta['serviceType'] as String? ?? 'urban',
      ),
      routeColor: routeColor,
      isCircular: meta['isCircular'] as bool? ?? false,
      status: RouteStatus.fromString(statusStr),
      active: statusStr != 'suspended',
    );
  }

  static Color _parseHexColor(String hex) {
    var clean = hex.startsWith('#') ? hex.substring(1) : hex;
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }

  RouteRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return RouteRepositoryException(
          error: RouteRepositoryError.notFound,
          message: 'Route not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return RouteRepositoryException(
          error: RouteRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return RouteRepositoryException(
        error: RouteRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return RouteRepositoryException(
      error: RouteRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
