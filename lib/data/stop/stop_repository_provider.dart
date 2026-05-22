import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/stop_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/stop_repository.dart';
import 'local/stop_local_repository.dart';
import 'local/stop_mock_repository.dart';
import 'remote/stop_remote_repository.dart';

/// Stale-while-revalidate sobre cache local + Supabase para paradas.
class StopRepositorySwr implements StopRepository {
  StopRepositorySwr({required this.local, required this.remote});

  final StopLocalRepository local;
  final StopRemoteRepository remote;

  static const _logTag = 'Repo:Stop';

  @override
  Future<List<StopModel>> nearby(
    LatLng center, {
    double radiusM = 1000,
    int limit = 50,
  }) async {
    final cached = await local.nearby(center, radiusM: radiusM, limit: limit);
    if (cached.isNotEmpty) {
      unawaited(_refreshNearby(center, radiusM: radiusM, limit: limit));
      return cached;
    }
    final fresh = await remote.nearby(center, radiusM: radiusM, limit: limit);
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshNearby(
    LatLng center, {
    required double radiusM,
    required int limit,
  }) async {
    try {
      final fresh = await remote.nearby(center, radiusM: radiusM, limit: limit);
      await local.upsertAll(fresh);
    } on StopRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh nearby() failed', e);
    }
  }

  @override
  Future<StopModel?> byId(String id) async {
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
    } on StopRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byId($id) failed', e);
    }
  }

  @override
  Stream<StopModel?> watch(String id) async* {
    final cached = await local.byId(id);
    yield cached;
    try {
      final fresh = await remote.byId(id);
      if (fresh != null && fresh != cached) {
        await local.upsert(fresh);
        yield fresh;
      }
    } on StopRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'watch($id) remote refresh failed', e);
    }
  }

  @override
  Future<List<StopModel>> byOperator(String operatorId, {int? limit, int? offset}) async {
    // Cache local no indexa por operador (StopModel sin operatorId);
    // vamos directos al remoto y guardamos para byId().
    try {
      final fresh = await remote.byOperator(operatorId);
      await local.upsertAll(fresh);
      return fresh;
    } on StopRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'byOperator() remote failed', e);
      rethrow;
    }
  }
}

/// Provider Riverpod del repositorio de paradas.
final stopRepositoryProvider = Provider.autoDispose<StopRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return StopMockRepository(mockData);
  }

  final box = ref.watch(stopsBoxProvider);
  return StopRepositorySwr(
    local: StopLocalRepository(box),
    remote: StopRemoteRepository(client),
  );
});
