import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/bus_location.dart';
import '../domain/bus_location_repository.dart';
import 'bus_position_channel_manager.dart';

/// Implementación remota sobre Supabase con suscripción Realtime
/// multiplexada (F13). Usa [BusPositionChannelManager] para compartir
/// un único canal entre todas las rutas observadas.
class BusLocationRemoteRepository implements BusLocationRepository {
  BusLocationRemoteRepository(this._client)
      : _channelMgr = BusPositionChannelManager(_client);

  final SupabaseClient _client;
  final BusPositionChannelManager _channelMgr;

  static const _logTag = 'Repo:BusLocation:Remote';

  @override
  Future<BusLocation?> latestForRoute(String routeId) async {
    try {
      final row = await _client
          .from('bus_positions')
          .select()
          .eq('route_id', routeId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'latestForRoute($routeId)');
    }
  }

  @override
  Stream<BusLocation?> streamForRoute(String routeId) async* {
    try {
      final initial = await latestForRoute(routeId);
      yield initial;
    } catch (_) {
      yield null;
    }
    yield* _channelMgr.watch(routeId);
  }

  void dispose() {
    _channelMgr.dispose();
  }

  BusLocation _fromRow(Map<String, dynamic> row) {
    final geom = row['geom'] as Map<String, dynamic>?;
    final coords = (geom?['coordinates'] as List<dynamic>?) ?? const [];
    final lng = coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    final lat = coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;
    return BusLocation(
      lat: lat,
      lng: lng,
      bearing: (row['bearing'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(row['recorded_at'] as String),
      accuracy: null,
    );
  }

  BusLocationRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == '42501') {
        return BusLocationRepositoryException(
          error: BusLocationRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return BusLocationRepositoryException(
        error: BusLocationRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return BusLocationRepositoryException(
      error: BusLocationRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
