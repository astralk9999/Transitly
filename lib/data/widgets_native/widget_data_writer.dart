import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

class WidgetDataWriter {
  static const _tag = 'WidgetDataWriter';
  static const _appGroupId = 'group.com.transitly.transitly';
  static const _nextBusPrefix = 'next_bus';
  static const _lineStatusPrefix = 'line_status';

  const WidgetDataWriter._();

  static Future<void> writeNextBus({
    required String stopName,
    required String routeCode,
    required int etaMinutes,
    required String source,
    required DateTime updatedAt,
  }) async {
    if (kIsWeb) return; // los widgets nativos no existen en web
    final payload = jsonEncode({
      'time': '$etaMinutes min',
      'stop': stopName,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
      'etaMinutes': etaMinutes,
    });

    final prefs = await SharedPreferences.getInstance();
    final key = '${_nextBusPrefix}_$routeCode';
    await prefs.setString(key, payload);
    await prefs.setString('widget_fav_line', routeCode);

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData('widget_fav_line', routeCode);
      await HomeWidget.saveWidgetData(key, payload);
      await HomeWidget.updateWidget(
        name: 'NextBusWidgetProvider',
        androidName: 'NextBusWidgetProvider',
      );
    } catch (e) {
      AppLogger.warn(_tag, 'home_widget writeNextBus failed', e);
    }

    AppLogger.debug(_tag, 'writeNextBus saved (key=$key)');
  }

  static Future<void> writeMyLineStatus({
    required String routeCode,
    required List<Map<String, dynamic>> upcoming,
  }) async {
    if (kIsWeb) return;
    final status = upcoming.isNotEmpty ? 'En servicio' : 'Sin datos';
    final updatedAt = DateTime.now().toIso8601String();
    final times = upcoming.map((d) => d['time'] as String).toList();
    final summary = times.isEmpty
        ? 'Sin próximas salidas'
        : 'Próximos: ${times.take(3).join(' · ')}';
    final payload = jsonEncode({
      'routeCode': routeCode,
      'status': status,
      'summary': summary,
      'updatedAt': updatedAt,
      'upcoming': upcoming,
    });

    final prefs = await SharedPreferences.getInstance();
    final key = '${_lineStatusPrefix}_$routeCode';
    await prefs.setString(key, payload);
    await prefs.setString('widget_my_line', routeCode);

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData('widget_my_line', routeCode);
      await HomeWidget.saveWidgetData(key, payload);
      await HomeWidget.updateWidget(
        name: 'MyLineWidgetProvider',
        androidName: 'MyLineWidgetProvider',
      );
    } catch (e) {
      AppLogger.warn(_tag, 'home_widget writeMyLineStatus failed', e);
    }

    AppLogger.debug(_tag, 'writeMyLineStatus saved (key=$key)');
  }

  static Future<void> writeNfcBalance({
    required double balance,
    required DateTime scannedAt,
  }) async {
    if (kIsWeb) return;
    final payload = jsonEncode({
      'balance': balance,
      'scannedAt': scannedAt.millisecondsSinceEpoch ~/ 1000,
    });

    const key = 'nfc_balance_v1';

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData(key, payload);
      await HomeWidget.updateWidget(
        name: 'NfcBalanceWidgetProvider',
        androidName: 'NfcBalanceWidgetProvider',
      );
    } catch (e) {
      AppLogger.warn(_tag, 'home_widget writeNfcBalance failed', e);
    }

    AppLogger.debug(_tag, 'writeNfcBalance saved');
  }

  static Future<void> writeTheme({
    required String accent,
    required String bgRoot,
    required String textHi,
  }) async {
    if (kIsWeb) return;
    final payload = jsonEncode({
      'accent': accent,
      'bgRoot': bgRoot,
      'textHi': textHi,
    });

    const key = 'theme_v1';

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData(key, payload);
      await HomeWidget.updateWidget(
        name: 'NextBusWidgetProvider',
        androidName: 'NextBusWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'MyLineWidgetProvider',
        androidName: 'MyLineWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'NfcBalanceWidgetProvider',
        androidName: 'NfcBalanceWidgetProvider',
      );
    } catch (e) {
      AppLogger.warn(_tag, 'home_widget writeTheme failed', e);
    }

    AppLogger.debug(_tag, 'writeTheme saved');
  }
}
