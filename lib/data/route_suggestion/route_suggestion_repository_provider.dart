import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/route_suggestion_repository.dart';
import 'local/route_suggestion_local_repository.dart';
import 'local/route_suggestion_mock_repository.dart';
import 'remote/route_suggestion_remote_repository.dart';

class RouteSuggestionRepositorySwr implements RouteSuggestionRepository {
  RouteSuggestionRepositorySwr({required this.local, required this.remote});

  final RouteSuggestionLocalRepository local;
  final RouteSuggestionRemoteRepository remote;

  static const _logTag = 'Repo:RouteSuggestion';

  @override
  Future<List<RouteSuggestionModel>> list({int? limit, int? offset}) async {
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
    } on RouteSuggestionRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh list()', e);
    }
  }

  @override
  Future<RouteSuggestionModel?> byId(String id) async {
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
    } on RouteSuggestionRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byId($id)', e);
    }
  }

  @override
  Future<RouteSuggestionModel> create(
      RouteSuggestionModel suggestion) async {
    final saved = await remote.create(suggestion);
    await local.upsert(saved);
    return saved;
  }

  /// Aplica el voto optimista a la cache local primero (incremento
  /// inmediato visible en UI) y luego pide al remoto el total real.
  /// Si la red falla, remote.castVote ya encoló y devuelve -1;
  /// dejamos el voto local incrementado.
  @override
  Future<int> castVote(String suggestionId) async {
    final localTotal = await local.castVote(suggestionId);
    try {
      final serverTotal = await remote.castVote(suggestionId);
      if (serverTotal >= 0) {
        // Reconciliar: el server puede haber rechazado el voto
        // duplicado y devuelto el total previo. Ajustamos.
        final cached = await local.byId(suggestionId);
        if (cached != null && cached.voteCount != serverTotal) {
          await local.upsert(cached.copyWith(voteCount: serverTotal));
        }
        return serverTotal;
      }
      // serverTotal == -1: encolado offline. Mantenemos el optimista.
      return localTotal;
    } on RouteSuggestionRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'castVote remote failed', e);
      return localTotal;
    }
  }

  @override
  Future<RouteSuggestionModel> updateStatus(String id, String status) async {
    final updated = await remote.updateStatus(id, status);
    await local.upsert(updated);
    return updated;
  }
}

final routeSuggestionRepositoryProvider =
    Provider<RouteSuggestionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return RouteSuggestionMockRepository(mockData);
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(routeSuggestionsBoxProvider);
  final remote =
      RouteSuggestionRemoteRepository(client: client, queue: queue);

  // Executors para drenado offline.
  final sync = ref.read(offlineSyncServiceProvider);
  sync.registerExecutor(
    PendingActionKind.createRouteSuggestion,
    (payload) async {
      await client.from('route_suggestions').insert(payload);
    },
  );
  sync.registerExecutor(
    PendingActionKind.voteSuggestion,
    (payload) async {
      await client.rpc('cast_suggestion_vote', params: payload);
    },
  );

  return RouteSuggestionRepositorySwr(
    local: RouteSuggestionLocalRepository(box),
    remote: remote,
  );
});
