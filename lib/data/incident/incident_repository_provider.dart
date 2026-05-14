import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/incident_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/incident_repository.dart';
import 'local/incident_local_repository.dart';
import 'local/incident_mock_repository.dart';
import 'remote/incident_remote_repository.dart';

/// SWR para incidents — cache-first en lecturas; en `create`, escribe
/// primero al remoto y, si responde, guarda en cache. Si el remoto
/// no devolvió por red, el remoto ya encoló la mutación y devolvió
/// la copia optimista; el SWR persiste esa copia en cache.
class IncidentRepositorySwr implements IncidentRepository {
  IncidentRepositorySwr({required this.local, required this.remote});

  final IncidentLocalRepository local;
  final IncidentRemoteRepository remote;

  static const _logTag = 'Repo:Incident';

  @override
  Future<List<IncidentModel>> byAuthor(String authorId) async {
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
    } on IncidentRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byAuthor($authorId)', e);
    }
  }

  @override
  Future<List<IncidentModel>> forRoute(String routeId) async {
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
    } on IncidentRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh forRoute($routeId)', e);
    }
  }

  @override
  Future<IncidentModel> create(IncidentModel incident) async {
    // El remoto se encarga de generar el id estable y de encolar si
    // hay error de red. Sea cual sea el camino, guardamos en cache
    // local para que las lecturas siguientes vean la mutación.
    final saved = await remote.create(incident);
    await local.upsert(saved);
    return saved;
  }

  @override
  Future<List<IncidentModel>> listAll() async {
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
    } on IncidentRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh listAll', e);
    }
  }

  @override
  Future<IncidentModel> updateStatus(String id, String status) async {
    final updated = await remote.updateStatus(id, status);
    await local.upsert(updated);
    return updated;
  }
}

/// Provider Riverpod del repositorio de incidents. Registra al
/// vuelo el executor de drenado para `createIncident` — la primera
/// vez que alguien lee el provider, la cola queda lista para drenar
/// inserts pendientes en cuanto vuelva la red.
final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return IncidentMockRepository(mockData);
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(incidentsBoxProvider);
  final remote = IncidentRemoteRepository(client: client, queue: queue);

  // Registrar handler para drenar createIncident al volver online.
  // Idempotente: el service usa Map[kind] = executor; volver a
  // registrar sobrescribe sin efectos colaterales.
  ref.read(offlineSyncServiceProvider).registerExecutor(
    PendingActionKind.createIncident,
    (payload) async {
      await client.from('incidents').insert(payload);
    },
  );

  return IncidentRepositorySwr(
    local: IncidentLocalRepository(box),
    remote: remote,
  );
});
