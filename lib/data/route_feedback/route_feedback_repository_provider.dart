import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/route_feedback_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/route_feedback_repository.dart';
import 'local/route_feedback_local_repository.dart';
import 'local/route_feedback_mock_repository.dart';
import 'remote/route_feedback_remote_repository.dart';

class RouteFeedbackRepositorySwr implements RouteFeedbackRepository {
  RouteFeedbackRepositorySwr({required this.local, required this.remote});

  final RouteFeedbackLocalRepository local;
  final RouteFeedbackRemoteRepository remote;

  static const _logTag = 'Repo:RouteFeedback';

  @override
  Future<List<RouteFeedbackModel>> byAuthor(String authorId) async {
    final cached = await local.byAuthor(authorId);
    if (cached.isNotEmpty) {
      unawaited(_refreshByAuthor(authorId));
      return cached;
    }
    final fresh = await remote.byAuthor(authorId);
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshByAuthor(String authorId) async {
    try {
      final fresh = await remote.byAuthor(authorId);
      await local.upsertAll(fresh);
    } on RouteFeedbackRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byAuthor($authorId)', e);
    }
  }

  @override
  Future<List<RouteFeedbackModel>> forRoute(String routeId) async {
    final cached = await local.forRoute(routeId);
    if (cached.isNotEmpty) {
      unawaited(_refreshForRoute(routeId));
      return cached;
    }
    final fresh = await remote.forRoute(routeId);
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshForRoute(String routeId) async {
    try {
      final fresh = await remote.forRoute(routeId);
      await local.upsertAll(fresh);
    } on RouteFeedbackRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh forRoute($routeId)', e);
    }
  }

  @override
  Future<RouteFeedbackModel> create(RouteFeedbackModel feedback) async {
    final saved = await remote.create(feedback);
    await local.upsert(saved);
    return saved;
  }

  @override
  Future<List<RouteFeedbackModel>> listAll() async {
    final cached = await local.listAll();
    if (cached.isNotEmpty) {
      unawaited(_refreshListAll());
      return cached;
    }
    final fresh = await remote.listAll();
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshListAll() async {
    try {
      final fresh = await remote.listAll();
      await local.upsertAll(fresh);
    } on RouteFeedbackRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh listAll', e);
    }
  }

  @override
  Future<RouteFeedbackModel> updateStatus(String id, String status) async {
    final updated = await remote.updateStatus(id, status);
    await local.upsert(updated);
    return updated;
  }
}

final routeFeedbackRepositoryProvider =
    Provider<RouteFeedbackRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return RouteFeedbackMockRepository(mockData);
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(routeFeedbackBoxProvider);
  final remote =
      RouteFeedbackRemoteRepository(client: client, queue: queue);

  // Registrar executor de drenado para createRouteFeedback.
  ref.read(offlineSyncServiceProvider).registerExecutor(
    PendingActionKind.createRouteFeedback,
    (payload) async {
      await client.from('route_feedback').insert(payload);
    },
  );

  ref.read(offlineSyncServiceProvider).registerExecutor(
    PendingActionKind.updateFeedbackStatus,
    (payload) async {
      final id = payload['id'] as String;
      final status = payload['status'] as String;
      await client.from('route_feedback').update(<String, dynamic>{
        'feedback_status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    },
  );

  return RouteFeedbackRepositorySwr(
    local: RouteFeedbackLocalRepository(box),
    remote: remote,
  );
});
