import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/offline_region.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/offline_region_repository.dart';
import 'local/offline_region_local_repository.dart';
import 'local/offline_region_mock_repository.dart';
import 'remote/offline_region_remote_repository.dart';

/// Implementa el patrón local-first para regiones offline: la cache
/// Hive es la fuente de verdad primaria. El backend Supabase se usa
/// solo para sincronizar entre dispositivos (background, best-effort).
class OfflineRegionRepositoryLocalFirst implements OfflineRegionRepository {
  OfflineRegionRepositoryLocalFirst({
    required this.local,
    required this.remote,
  });

  final OfflineRegionLocalRepository local;
  final OfflineRegionRemoteRepository remote;

  static const _logTag = 'Repo:OfflineRegion';

  @override
  Future<List<OfflineRegion>> forUser(String userId, {int? limit, int? offset}) async {
    final cached = await local.forUser(userId);
    if (cached.isEmpty) {
      unawaited(_pullFromRemote(userId));
    }
    return cached;
  }

  Future<void> _pullFromRemote(String userId) async {
    try {
      final remoteRegions = await remote.forUser(userId);
      if (remoteRegions.isNotEmpty) {
        await local.upsertAll(remoteRegions);
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'background pull from remote failed', e);
    }
  }

  @override
  Future<OfflineRegion> add(OfflineRegion region) async {
    final saved = await local.add(region);
    unawaited(_pushToRemote(region));
    return saved;
  }

  Future<void> _pushToRemote(OfflineRegion region) async {
    try {
      await remote.add(region);
    } catch (e) {
      AppLogger.warn(_logTag, 'background push add() failed', e);
    }
  }

  @override
  Future<void> delete(String regionId) async {
    await local.delete(regionId);
    unawaited(_deleteFromRemote(regionId));
  }

  Future<void> _deleteFromRemote(String regionId) async {
    try {
      await remote.delete(regionId);
    } catch (e) {
      AppLogger.warn(_logTag, 'background delete from remote failed', e);
    }
  }
}

final offlineRegionRepositoryProvider =
    Provider<OfflineRegionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return OfflineRegionMockRepository();
  }

  final box = ref.watch(offlineRegionsBoxProvider);
  return OfflineRegionRepositoryLocalFirst(
    local: OfflineRegionLocalRepository(box),
    remote: OfflineRegionRemoteRepository(client: client),
  );
});
