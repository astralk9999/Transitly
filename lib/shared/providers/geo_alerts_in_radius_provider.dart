import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/geo_alerts/geo_alerts_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../models/geo_alert_model.dart';
import 'auth_provider.dart';
import 'user_favorites_provider.dart';
import 'user_location_provider.dart';

const _logTag = 'GeoAlertsInRadius';
const _seenBoxName = 'geo_alerts_seen';
const _seenKey = 'ids';

bool _alertAppliesToUser(
    GeoAlertModel a, Set<String> userFavoriteRoutes) {
  // affectedRouteIds vacío → aplica a TODOS los usuarios.
  if (a.affectedRouteIds.isEmpty) return true;
  // Si tiene rutas y el usuario tiene favoritas, basta con que coincida
  // alguna. Si el usuario no tiene favoritas pero el aviso tiene
  // rutas, lo mostramos también (no podemos descartar).
  if (userFavoriteRoutes.isEmpty) return true;
  return a.affectedRouteIds.any(userFavoriteRoutes.contains);
}

bool _userInRadius(LatLng userPos, GeoAlertModel a) {
  const dist = Distance();
  final d = dist.as(LengthUnit.Meter, userPos,
      LatLng(a.centerLat, a.centerLng));
  return d <= a.radiusM;
}

/// Lista de avisos activos cuyo radio contiene la posición del usuario
/// y, si tienen rutas asociadas, aplican a sus favoritas.
///
/// Devuelve lista vacía si no hay ubicación o no hay coincidencias.
final geoAlertsInRadiusProvider = Provider<List<GeoAlertModel>>((ref) {
  final pos = ref.watch(userLocationLatLngProvider);
  if (pos == null) return const [];
  final alertsAsync = ref.watch(activeGeoAlertsProvider);
  final alerts = alertsAsync.valueOrNull ?? const [];
  final favoriteRoutes = ref.watch(userFavoritesProvider);
  return alerts
      .where((a) =>
          _userInRadius(pos, a) &&
          _alertAppliesToUser(a, favoriteRoutes))
      .toList();
});

/// Listener que, cada vez que la lista de avisos relevantes cambia,
/// detecta IDs nuevos (no notificados previamente) e inserta una fila
/// en `notifications` para que aparezcan en el inbox del usuario.
///
/// Persiste los IDs ya notificados en una box de Hive para no spamear
/// la misma alerta cada vez que el usuario reabre la app.
final geoAlertsAutoNotifyProvider = Provider<void>((ref) {
  ref.listen<List<GeoAlertModel>>(geoAlertsInRadiusProvider,
      (prev, next) async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;
    final client = ref.read(supabaseClientProvider);

    Box<List<dynamic>>? box;
    try {
      box = await Hive.openBox<List<dynamic>>(_seenBoxName);
    } catch (e) {
      AppLogger.warn(_logTag, 'open hive box failed', e);
      return;
    }
    final seen = Set<String>.from(
        (box.get(_seenKey, defaultValue: <String>[]) ?? <String>[])
            .map((e) => e.toString()));

    for (final a in next) {
      if (seen.contains(a.id)) continue;
      seen.add(a.id);
      try {
        await client.from('notifications').insert({
          'user_id': userId,
          'type': 'custom',
          'payload': {
            'title': a.title,
            'body': a.body,
            'severity': a.severity.name,
            'alert_id': a.id,
            'kind': 'geo_alert',
          },
        });
      } catch (e) {
        AppLogger.warn(
            _logTag, 'insert notification failed for ${a.id}', e);
      }
    }

    // Limpiamos IDs que ya no están vigentes (avisos eliminados o
    // desactivados) para que si vuelven a activarse, vuelvan a notificar.
    final stillActive = next.map((a) => a.id).toSet();
    seen.removeWhere((id) =>
        !stillActive.contains(id) &&
        !(prev?.map((a) => a.id).contains(id) ?? false));

    await box.put(_seenKey, seen.toList());
  }, fireImmediately: true);
});
