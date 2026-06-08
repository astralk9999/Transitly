import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../data/notification/local_push_service.dart';
import '../../data/notification/notification_repository_provider.dart';
import '../../data/reputation/reputation_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../models/app_notification.dart';
import 'theme_notifier.dart';
import 'user_provider.dart';

const _logTag = 'Provider:NotificationStream';

/// ¿Debe entregarse esta notificación según las preferencias del usuario?
/// (toggles del perfil + horas de silencio). Centraliza el respeto a las
/// preferencias, que antes se ignoraban al disparar la notificación local.
bool _allowedByPrefs(ThemeNotifier prefs, AppNotification n) {
  // Horas de silencio: si están activas y la hora actual cae dentro, no se
  // muestra (salvo críticas, que siempre pasan).
  final isCritical = n.payload['severity'] == 'critical';
  if (prefs.quietHoursEnabled && !isCritical) {
    final s = prefs.quietHoursStart, e = prefs.quietHoursEnd;
    if (s != null && e != null && _inQuietHours(s, e)) return false;
  }
  // Toggle por tipo.
  switch (n.type) {
    case AppNotificationType.incidentResolved:
      return prefs.notifIncidentResolved;
    case AppNotificationType.routePromoted:
      return prefs.notifRoutePromoted;
    case AppNotificationType.busApproachingFavorite:
      return prefs.notifBusApproaching;
    case AppNotificationType.featureRequestReplied:
      return prefs.notifFeatureRequestReplied;
    default:
      // Avisos de zona llegan como 'custom' con kind geo/zone.
      final kind = n.payload['kind'] as String?;
      if (kind == 'geo' || kind == 'zone' || kind == 'zone_recommendation') {
        return prefs.notifZoneAlerts;
      }
      return true; // XP/rango, share y genéricos siempre
  }
}

bool _inQuietHours(String start, String end) {
  int toMin(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return -1;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }
  final now = DateTime.now();
  final m = now.hour * 60 + now.minute;
  final s = toMin(start), e = toMin(end);
  if (s < 0 || e < 0) return false;
  // Rango que cruza medianoche (p.ej. 22:00–07:00).
  return s <= e ? (m >= s && m < e) : (m >= s || m < e);
}

/// Stream of [AppNotification] objects for the currently authenticated
/// user, delivered via Supabase Realtime.
///
/// When the user is not authenticated the stream emits an empty list and
/// does not open a Realtime channel.
// autoDispose: el canal Supabase Realtime se cierra cuando ninguna
// pantalla observa el provider (el ref.onDispose de abajo se dispara).
final notificationStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return Stream.value(const <AppNotification>[]);
  }

  final repo = ref.watch(notificationRepositoryProvider);

  final controller = StreamController<List<AppNotification>>();

  repo.forUser(userId).then((notifications) {
    if (!controller.isClosed) controller.add(notifications);
  }).catchError((Object e) {
    AppLogger.warn(_logTag, 'initial fetch failed', e);
  });

  final channel = client
      .channel('notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          AppLogger.debug(
              _logTag, 'realtime insert (id=${payload.newRecord['id']})');
          repo.forUser(userId).then((notifications) {
            if (!controller.isClosed) controller.add(notifications);
          }).catchError((Object e) {
            AppLogger.warn(_logTag, 'refresh after insert failed', e);
          });
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Activable provider que escucha el stream de notificaciones y, cuando
/// aparece una nueva (id no visto antes), dispara una notificación
/// nativa del sistema vía [LocalPushService]. No produce valor.
final pushBridgeProvider = Provider<void>((ref) {
  final seen = <String>{};
  // La primera emisión es el fetch inicial (notificaciones previas a abrir
  // la app). No disparamos push por ellas; solo poblamos `seen` para que
  // las que lleguen DESPUÉS por Realtime sí salten.
  var primed = false;
  ref.listen<AsyncValue<List<AppNotification>>>(notificationStreamProvider,
      (prev, next) {
    final list = next.valueOrNull;
    if (list == null) return;
    if (!primed) {
      primed = true;
      for (final n in list) {
        seen.add(n.id);
      }
      return;
    }
    // Solo notificar las NO leídas para no spamear al re-suscribir.
    final prefs = ref.read(themeNotifierProvider);
    final fresh = list.where((n) => !n.read && !seen.contains(n.id)).toList();
    for (final n in fresh) {
      seen.add(n.id);
      // Respeta las preferencias del usuario (toggles + horas de silencio).
      if (!_allowedByPrefs(prefs, n)) continue;
      final title = (n.payload['title'] as String?) ?? _defaultTitle(n);
      final body = (n.payload['body'] as String?) ?? '';
      final severity = n.payload['severity'] as String?;
      // Hash estable a int para el ID nativo (signed 32 bit).
      final id = n.id.hashCode & 0x7fffffff;
      _LocalPushSink.show(id: id, title: title, body: body, severity: severity);
    }
    // Limpia ids viejos para no crecer indefinidamente.
    if (seen.length > 200) {
      seen.removeWhere((id) => !list.any((n) => n.id == id));
    }
  }, fireImmediately: true);
});

/// Cuando llega una notificación de XP ganado o subida de rango por
/// Realtime, refresca el perfil/reputación para que el rango y los puntos
/// se actualicen al instante (antes solo se veían al entrar a Reputación).
final reputationLiveRefreshProvider = Provider<void>((ref) {
  final seen = <String>{};
  var primed = false;
  ref.listen<AsyncValue<List<AppNotification>>>(notificationStreamProvider,
      (prev, next) {
    final list = next.valueOrNull;
    if (list == null) return;
    if (!primed) {
      primed = true;
      for (final n in list) {
        seen.add(n.id);
      }
      return;
    }
    final fresh = list.where((n) =>
        !seen.contains(n.id) &&
        (n.type == AppNotificationType.xpEarned ||
            n.type == AppNotificationType.rankUp));
    if (fresh.isNotEmpty) {
      for (final n in fresh) {
        seen.add(n.id);
      }
      ref.invalidate(userProfileFromSupabaseProvider);
      ref.invalidate(userReputationProvider);
    }
  }, fireImmediately: true);
});

String _defaultTitle(AppNotification n) {
  switch (n.type) {
    case AppNotificationType.xpEarned:
      return '+XP ganado';
    case AppNotificationType.rankUp:
      return 'Subiste de rango';
    case AppNotificationType.incidentResolved:
      return 'Incidencia resuelta';
    case AppNotificationType.routePromoted:
      return 'Ruta promocionada';
    case AppNotificationType.shareReceived:
      return 'Compartido contigo';
    case AppNotificationType.featureRequestReplied:
      return 'Respuesta a tu sugerencia';
    case AppNotificationType.busApproachingFavorite:
      return 'Bus acercándose';
    case AppNotificationType.custom:
      return 'Aviso';
  }
}

class _LocalPushSink {
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? severity,
  }) async {
    await LocalPushService.instance.show(
        id: id, title: title, body: body, severity: severity);
  }
}

/// Derived count of unread notifications from the stream.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationStreamProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.read).length;
});
