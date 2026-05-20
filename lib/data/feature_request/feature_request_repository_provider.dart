import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/feature_request.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/feature_request_repository.dart';
import 'local/feature_request_local_repository.dart';
import 'local/feature_request_mock_repository.dart';
import 'remote/feature_request_remote_repository.dart';

class FeatureRequestRepositorySwr implements FeatureRequestRepository {
  FeatureRequestRepositorySwr({required this.local, required this.remote});

  final FeatureRequestLocalRepository local;
  final FeatureRequestRemoteRepository remote;

  static const _logTag = 'Repo:FeatureRequest';

  @override
  Future<List<FeatureRequest>> list({int? limit, int? offset}) async {
    final cached = await local.list();
    if (cached.isNotEmpty) {
      unawaited(_refreshList());
      return cached;
    }
    final fresh = await remote.list();
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshList() async {
    try {
      final fresh = await remote.list();
      await local.upsertAll(fresh);
    } on FeatureRequestRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh list()', e);
    }
  }

  @override
  Future<FeatureRequest?> byId(String id) async {
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
    } on FeatureRequestRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byId($id)', e);
    }
  }

  @override
  Future<FeatureRequest> create(FeatureRequest request) async {
    final saved = await remote.create(request);
    await local.upsert(saved);
    return saved;
  }

  @override
  Future<int> castVote(String requestId) async {
    final localTotal = await local.castVote(requestId);
    try {
      final serverTotal = await remote.castVote(requestId);
      if (serverTotal >= 0) {
        final cached = await local.byId(requestId);
        if (cached != null && cached.votes != serverTotal) {
          await local.upsert(cached.copyWith(votes: serverTotal));
        }
        return serverTotal;
      }
      return localTotal;
    } on FeatureRequestRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'castVote remote failed', e);
      return localTotal;
    }
  }
}

final featureRequestRepositoryProvider =
    Provider<FeatureRequestRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return FeatureRequestMockRepository(mockData);
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(featureRequestsBoxProvider);
  final remote =
      FeatureRequestRemoteRepository(client: client, queue: queue);

  final sync = ref.read(offlineSyncServiceProvider);
  sync.registerExecutor(
    PendingActionKind.createFeatureRequest,
    (payload) async {
      await client.from('feature_requests').insert(payload);
    },
  );
  sync.registerExecutor(
    PendingActionKind.voteFeatureRequest,
    (payload) async {
      await client.rpc('cast_feature_request_vote', params: payload);
    },
  );

  return FeatureRequestRepositorySwr(
    local: FeatureRequestLocalRepository(box),
    remote: remote,
  );
});
