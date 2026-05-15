import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class PushService {
  final SupabaseClient _client;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  PushService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _messaging = FirebaseMessaging.instance,
      _localNotifications = FlutterLocalNotificationsPlugin();

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> registerToken(String userId) async {
    final token = await getToken();
    if (token == null) return;
    await _client.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': Platform.operatingSystem,
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> unregisterToken(String userId) async {
    final token = await getToken();
    if (token == null) return;
    await _client
        .from('device_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Future<void> setupForegroundHandler() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen((message) {
      _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'transitly_push',
            'Transitly Notifications',
            channelDescription: 'Push notifications from Transitly',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data['deeplink'] as String?,
      );
    });
  }

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    AppLogger.info('PushService', 'background message received');
  }
}
