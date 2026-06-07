import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/app_logger.dart';

/// Singleton para mostrar notificaciones del sistema Android desde
/// dentro de la app, sin pasar por FCM. Se usa cuando un aviso geo o
/// global llega para que el usuario lo vea aunque la app esté en
/// segundo plano (con la app abierta también, como fallback visible).
class LocalPushService {
  LocalPushService._();
  static final LocalPushService instance = LocalPushService._();

  static const _channelId = 'transitly_alerts';
  static const _channelName = 'Avisos';
  static const _channelDesc =
      'Avisos importantes de Transitly (geo, globales)';
  static const _logTag = 'LocalPush';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      // Icono pequeño = silueta monocroma (la barra de estado solo admite
      // iconos de un color; un mipmap a color se vería como un cuadro
      // blanco). El logo a color va como largeIcon en cada notificación.
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
      // Android 13+: pide permiso POST_NOTIFICATIONS al usuario.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      AppLogger.warn(_logTag, 'init failed', e);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? severity,
  }) async {
    if (!_ready) await init();
    final isCritical = severity == 'critical';
    final accent = severity == 'critical'
        ? const Color(0xFFB71C1C)
        : severity == 'warning'
            ? const Color(0xFFFF9800)
            : const Color(0xFF6C4FD8);
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: isCritical ? Importance.max : Importance.high,
            priority: isCritical ? Priority.max : Priority.high,
            category: AndroidNotificationCategory.message,
            // Icono pequeño monocromo (la barra de estado lo tinta con
            // `color`).
            icon: 'ic_notification',
            // Logo a color a la derecha. Usamos un PNG real en
            // drawable-nodpi (no el @mipmap/ic_launcher, que en API 26+ es
            // adaptativo/XML y reventaba al decodificarse como bitmap).
            largeIcon: const DrawableResourceAndroidBitmap(
                '@drawable/ic_notification_large'),
            // Texto expandible (varias líneas) con título en negrita.
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: '<b>$title</b>',
              htmlFormatContentTitle: true,
              summaryText: 'Transitly',
              htmlFormatSummaryText: true,
            ),
            color: accent,
            ticker: title,
          ),
        ),
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'show failed', e);
    }
  }
}
