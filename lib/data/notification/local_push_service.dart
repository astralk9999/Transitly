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
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
            color: severity == 'critical'
                ? const Color(0xFFB71C1C)
                : severity == 'warning'
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF2196F3),
          ),
        ),
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'show failed', e);
    }
  }
}
