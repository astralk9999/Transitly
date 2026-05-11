import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/route_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/route_repository.dart';
import 'local/route_local_repository.dart';
import 'local/route_mock_repository.dart';
import 'remote/route_remote_repository.dart';

/// Stale-while-revalidate para rutas. Más matizado que Operator/Stop
/// porque la visibilidad la define RLS — un mismo `byId` puede
/// devolver `null` para un usuario y la fila completa para otro.
class RouteRepositorySwr implements RouteRepository {
  RouteRepositorySwr({required this.local, required this.remote});

  final RouteLocalRepository local;
  final RouteRemoteRepository remote;

  static const _logTag = 'Repo:Route';

  @override
  Future<List<RouteModel>> byOperator(String operatorId) async {
    final cached = await local.byOperator(operatorId);
    if (cached.isNotEmpty) {
      unawaited(_refreshByOperator(operatorId));
      return cached;
    }
    final fresh = await remote.byOperator(operatorId);
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshByOperator(String operatorId) async {
    try {
      final fresh = await remote.byOperator(operatorId);
      await local.upsertAll(fresh);
    } on RouteRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byOperator($operatorId)', e);
    }
  }

  @override
  Future<RouteModel?> byId(String id) async {
    final cached = await local.byId(id);
    if (cached != null) {
      unawaited(_refreshOne(id));
      return cached;
    }
    final fresh = await remote.byId(id);
    if (fresh != null) await local.upsert(fresh);
    return fresh;
  }

  Future<void> _refreshOne(String id) async {
    try {
      final fresh = await remote.byId(id);
      if (fresh != null) await local.upsert(fresh);
    } on RouteRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byId($id)', e);
    }
  }

  @override
  Stream<RouteModel?> watch(String id) async* {
    final cached = await local.byId(id);
    yield cached;
    try {
      final fresh = await remote.byId(id);
      if (fresh != null && fresh != cached) {
        await local.upsert(fresh);
        yield fresh;
      }
    } on RouteRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'watch($id) remote refresh failed', e);
    }
  }

  @override
  Future<List<RouteModel>> community(String ownerId) async {
    // Cache local no indexa por owner_id; delegamos siempre al
    // remoto y guardamos en cache para byId/byOperator.
    try {
      final fresh = await remote.community(ownerId);
      await local.upsertAll(fresh);
      return fresh;
    } on RouteRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'community($ownerId) remote failed', e);
      rethrow;
    }
  }

  @override
  Future<List<RouteModel>> intersectingBbox(LatLng sw, LatLng ne) async {
    try {
      final fresh = await remote.intersectingBbox(sw, ne);
      await local.upsertAll(fresh);
      return fresh;
    } on RouteRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'intersectingBbox remote failed', e);
      // Sin filtro local — devolvemos cache completa para que el
      // mapa siga renderizando algo.
      final cached = await local.byOperator('');
      return cached.isEmpty ? <RouteModel>[] : cached;
    }
  }
}

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return RouteMockRepository(mockData);
  }

  final box = ref.watch(routesBoxProvider);
  return RouteRepositorySwr(
    local: RouteLocalRepository(box),
    remote: RouteRemoteRepository(client),
  );
});
