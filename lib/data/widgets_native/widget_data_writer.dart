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

  /// "HH:mm" en hora local, para mostrar "Actualizado HH:mm" en el widget.
  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static Future<void> writeNextBus({
    required String stopName,
    required String routeCode,
    required int etaMinutes,
    required String source,
    required DateTime updatedAt,
    bool inService = true,
    String? nextDepartureTime,
  }) async {
    if (kIsWeb) return; // los widgets nativos no existen en web
    // Cuando la línea no circula ahora (fuera de horario), no mostramos un ETA
    // engañoso ("360 min"): mostramos la próxima salida o un guion.
    final timeLabel = inService
        ? '$etaMinutes min'
        : (nextDepartureTime != null ? 'Próx. $nextDepartureTime' : 'Fuera de servicio');
    final payload = jsonEncode({
      'time': timeLabel,
      'stop': stopName,
      'source': source,
      'inService': inService,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedLabel': _hhmm(updatedAt),
      'etaMinutes': inService ? etaMinutes : -1,
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
    bool inService = true,
  }) async {
    if (kIsWeb) return;
    // "En servicio" solo si la línea circula AHORA (hay salidas hoy pendientes).
    // Antes se marcaba en servicio con cualquier salida del horario, aunque
    // fuera de madrugada para una línea que no opera.
    final now = DateTime.now();
    final status = inService ? 'En servicio' : 'Fuera de servicio';
    final times = upcoming.map((d) => d['time'] as String).toList();
    final summary = !inService
        ? (times.isEmpty
            ? 'Sin servicio ahora'
            : 'Reanuda: ${times.first}')
        : (times.isEmpty
            ? 'Sin próximas salidas'
            : 'Próximos: ${times.take(3).join(' · ')}');
    final payload = jsonEncode({
      'routeCode': routeCode,
      'status': status,
      'inService': inService,
      'summary': summary,
      'updatedAt': now.toIso8601String(),
      'updatedLabel': _hhmm(now),
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
