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

  /// Hoy: emite cache (si existe) → emite fresh del remoto → cierra.
  /// F13 sustituirá la segunda emisión por una suscripción
  /// Realtime que emite cada `INSERT` en `bus_positions` filtrado por
  /// `route_id`.
  @override
  Stream<BusLocation?> streamForRoute(String routeId) async* {
    final cached = await local.latestForRoute(routeId);
    if (cached != null) yield cached;
    try {
      final fresh = await remote.latestForRoute(routeId);
      if (fresh != null) {
        local.upsert(routeId, fresh);
        if (fresh != cached) yield fresh;
      } else if (cached == null) {
        yield null;
      }
    } on BusLocationRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'streamForRoute remote failed', e);
    }
  }
}

final busLocationRepositoryProvider =
    Provider<BusLocationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return BusLocationMockRepository(mockData);
  }

  return BusLocationRepositorySwr(
    local: BusLocationLocalRepository(),
    remote: BusLocationRemoteRepository(client),
  );
});
