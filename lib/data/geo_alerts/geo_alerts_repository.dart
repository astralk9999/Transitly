import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/geo_alert_model.dart';
import '../supabase/supabase_client_provider.dart';

/// Sub P2-#55: repositorio para `geo_alerts`.
class GeoAlertsRepository {
  GeoAlertsRepository(this._client);
  final SupabaseClient _client;

  /// Lee todos los avisos activos (no expirados). El filtrado por
  /// distancia se hace en cliente.
  Future<List<GeoAlertModel>> listActive() async {
    try {
      final rows = await _client
          .from('geo_alerts')
          .select()
          .eq('active', true)
          .order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map((r) => GeoAlertModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warn('GeoAlertsRepo', 'listActive failed', e);
      return const [];
    }
  }

  /// Admin: lista TODOS incluso inactivos.
  Future<List<GeoAlertModel>> listAllForAdmin() async {
    final rows = await _client
        .from('geo_alerts')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => GeoAlertModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<GeoAlertModel> create(GeoAlertModel alert) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated');
    final row = await _client
        .from('geo_alerts')
        .insert(alert.toInsertJson(uid))
        .select()
        .single();
    return GeoAlertModel.fromJson(row);
  }

  Future<void> setActive(String id, bool active) async {
    await _client.from('geo_alerts').update({'active': active}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('geo_alerts').delete().eq('id', id);
  }
}

final geoAlertsRepositoryProvider = Provider<GeoAlertsRepository>((ref) {
  return GeoAlertsRepository(ref.watch(supabaseClientProvider));
});

/// Stream de avisos activos. Se invalida al cambiar la sesión.
final activeGeoAlertsProvider =
    FutureProvider<List<GeoAlertModel>>((ref) async {
  return ref.watch(geoAlertsRepositoryProvider).listActive();
});
