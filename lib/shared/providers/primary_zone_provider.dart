import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map/map_config.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import 'auth_provider.dart';

/// Zona principal del usuario (profiles.primary_zone_id) resuelta a su
/// [ZoneRow] con perímetro. `null` si no hay sesión o no eligió ninguna.
final primaryZoneProvider = FutureProvider<ZoneRow?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState is AuthAuthenticated ? authState.user.id : null;
  if (userId == null) return null;
  try {
    final prof = await client
        .from('profiles')
        .select('primary_zone_id')
        .eq('id', userId)
        .maybeSingle();
    final zoneId = prof?['primary_zone_id'] as String?;
    if (zoneId == null) return null;
    final zones =
        await AdminRoutesRepository(client).listZones(includePending: true);
    for (final z in zones) {
      if (z.id == zoneId) return z;
    }
  } catch (_) {}
  return null;
});

/// Centro por defecto del mapa cuando NO hay ubicación del usuario: el centro
/// de su zona principal si la tiene con perímetro; si no, Jerez (COMUJESA).
final defaultMapCenterProvider = Provider<LatLng>((ref) {
  final zone = ref.watch(primaryZoneProvider).valueOrNull;
  if (zone != null && zone.hasGeometry) {
    return LatLng(zone.centerLat!, zone.centerLng!);
  }
  return MapConfig.defaultCenter;
});
