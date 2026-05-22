import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/bus_location.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/bus_location_repository.dart';
import 'local/bus_location_local_repository.dart';
import 'local/bus_location_mock_repository.dart';
import 'remote/bus_location_remote_repository.dart';

/// SWR específico para BusLocation. La cache es in-memory con TTL
/// corto — si la entrada está dentro del TTL devolvemos cache; si
/// no, vamos al remoto y guardamos la respuesta para los próximos
/// 60s.
class BusLocationRepositorySwr implements BusLocationRepository {
  BusLocationRepositorySwr({required this.local, required this.remote});

  final BusLocationLocalRepository local;
  final BusLocationRemoteRepository remote;

  static const _logTag = 'Repo:BusLocation';

  @override
  Future<BusLocation?> latestForRoute(String routeId) async {
    final cached = await local.latestForRoute(routeId);
    if (cached != null) return cached;
    try {
      final fresh = await remote.latestForRoute(routeId);
      if (fresh != null) local.upsert(routeId, fresh);
      return fresh;
    } on BusLocationRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'latestForRoute remote failed', e);
      return null;
    }
  }

  /// Emite cache → delega al stream Realtime del remote repo.
  /// El remote repo abre una suscripción Supabase Realtime sobre
  /// `bus_positions` filtrada por `route_id` (F13).
  @override
  Stream<BusLocation?> streamForRoute(String routeId) async* {
    final cached = await local.latestForRoute(routeId);
    if (cached != null) yield cached;
    yield* remote.streamForRoute(routeId);
  }
}

final busLocationRepositoryProvider =
    Provider.autoDispose<BusLocationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return BusLocationMockRepository(mockData);
  }

  final remote = BusLocationRemoteRepository(client);
  final swr = BusLocationRepositorySwr(
    local: BusLocationLocalRepository(),
    remote: remote,
  );

  ref.onDispose(() => remote.dispose());

  return swr;
});
