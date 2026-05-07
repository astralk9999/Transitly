import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/operator_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/operator_repository.dart';
import 'local/operator_local_repository.dart';
import 'local/operator_mock_repository.dart';
import 'remote/operator_remote_repository.dart';

/// Implementa stale-while-revalidate sobre las capas local y remota.
/// La UI consume esta clase a través de [operatorRepositoryProvider]
/// y nunca se preocupa de qué backend está respondiendo.
///
/// Comportamiento por método:
/// - Si la cache devuelve algo no vacío → emite y refresca en
///   background.
/// - Si la cache está vacía → fuerza la llamada remota, cachea y
///   emite el resultado.
/// - Errores de red **no** se relanzan si hay datos cacheados; solo
///   se loguean como warning. La excepción tipada
///   [OperatorRepositoryException] sí burbujea cuando la cache está
///   vacía y la red falla.
class OperatorRepositorySwr implements OperatorRepository {
  OperatorRepositorySwr({required this.local, required this.remote});

  final OperatorLocalRepository local;
  final OperatorRemoteRepository remote;

  static const _logTag = 'Repo:Operator';

  @override
  Future<List<OperatorModel>> list() async {
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
    } on OperatorRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh list() failed', e);
    }
  }

  @override
  Future<OperatorModel?> byId(String id) async {
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
    } on OperatorRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh byId($id) failed', e);
    }
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    // La búsqueda geográfica autoritativa vive en el SQL; preferimos
    // remote para que aplique el GIST de bbox. Si la red falla,
    // caemos al cache local (lista completa, sin filtro radial).
    try {
      final fresh = await remote.nearby(center, radiusM: radiusM);
      await local.upsertAll(fresh);
      return fresh;
    } on OperatorRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'nearby() remote failed, returning cache', e);
      return local.nearby(center, radiusM: radiusM);
    }
  }
}

/// Provider Riverpod del repositorio de operadores.
///
/// Estrategia de selección:
/// - Si la sesión Supabase es `null` (modo invitado) → mock.
/// - Si hay sesión → SWR(local, remote).
///
/// Nota: hasta que F4 implemente el flujo de auth real, "sesión
/// nula" es la única vía de demostración de modo invitado.
final operatorRepositoryProvider = Provider<OperatorRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return OperatorMockRepository(mockData);
  }

  final box = ref.watch(operatorsBoxProvider);
  return OperatorRepositorySwr(
    local: OperatorLocalRepository(box),
    remote: OperatorRemoteRepository(client),
  );
});
