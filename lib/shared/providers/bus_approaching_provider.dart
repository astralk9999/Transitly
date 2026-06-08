import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_data_service.dart';
import '../../data/notification/local_push_service.dart';
import 'route_lookup_providers.dart';
import 'theme_notifier.dart';
import 'user_favorites_provider.dart';

/// Vigila las paradas favoritas y dispara una notificación cuando un bus de
/// una línea que pasa por ellas está a ≤ X minutos (según la preferencia
/// "bus llegando" del perfil) y dentro de la franja horaria activa.
///
/// Antes el toggle existía pero NO había lógica que disparara el aviso; este
/// provider lo cablea. Se revisa cada minuto.
final busApproachingNotifierProvider = Provider<void>((ref) {
  // En web no hay notificaciones nativas; no montamos el vigilante.
  if (kIsWeb) return;

  final notified = <String>{}; // clave parada|ruta|salida ya avisada
  Timer? timer;

  void check() {
    final prefs = ref.read(themeNotifierProvider);
    if (!prefs.notifBusApproaching) return;
    if (!_inActiveWindow(prefs.busApproachingActiveStart,
        prefs.busApproachingActiveEnd)) {
      return;
    }
    final threshold = prefs.busApproachingMinutesAhead;
    final favStops = ref.read(userFavoriteStopsProvider);
    if (favStops.isEmpty) return;

    final mock = ref.read(mockDataServiceProvider);
    final stopToRoutes = ref.read(stopToRouteCodesProvider);
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    for (final stopId in favStops) {
      final stop = mock.getStopById(stopId);
      if (stop == null) continue;
      final routes = stopToRoutes[stopId] ?? const <String>[];
      for (final routeId in routes) {
        final deps = mock.getNextDepartures(routeId, stopId, 1);
        if (deps.isEmpty) continue;
        final dep = deps.first;
        final p = dep.departureTime.split(':');
        if (p.length < 2) continue;
        final depMin = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        final eta = depMin - nowMin;
        if (eta <= 0 || eta > threshold) continue;

        final key = '$stopId|$routeId|${dep.departureTime}';
        if (notified.contains(key)) continue;
        notified.add(key);

        final route = mock.getRouteById(routeId);
        final code = route?.code ?? routeId;
        LocalPushService.instance.show(
          id: key.hashCode & 0x7fffffff,
          title: 'Tu bus está llegando',
          body: 'Línea $code llega en $eta min a ${stop.name}.',
        );
      }
    }

    // Limpieza: descarta avisos de salidas ya pasadas para no crecer.
    notified.removeWhere((k) {
      final parts = k.split('|');
      if (parts.length < 3) return true;
      final hp = parts[2].split(':');
      if (hp.length < 2) return true;
      final m = (int.tryParse(hp[0]) ?? 0) * 60 + (int.tryParse(hp[1]) ?? 0);
      return m < nowMin - 2;
    });
  }

  // Revisa al activarse y luego cada minuto.
  check();
  timer = Timer.periodic(const Duration(minutes: 1), (_) => check());
  ref.onDispose(() => timer?.cancel());
});

bool _inActiveWindow(String start, String end) {
  int toMin(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return -1;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }
  final now = DateTime.now();
  final m = now.hour * 60 + now.minute;
  final s = toMin(start), e = toMin(end);
  if (s < 0 || e < 0) return true;
  return s <= e ? (m >= s && m < e) : (m >= s || m < e);
}
