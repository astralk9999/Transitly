import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

class WidgetDataWriter {
  static const _tag = 'WidgetDataWriter';
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
    final prefs = await SharedPreferences.getInstance();
    final key = '${_nextBusPrefix}_$routeCode';
    final data = jsonEncode({
      'stopName': stopName,
      'routeCode': routeCode,
      'etaMinutes': etaMinutes,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    });
    await prefs.setString(key, data);
    AppLogger.debug(_tag, 'writeNextBus saved (key=$key)');
  }

  static Future<void> writeMyLineStatus({
    required String routeCode,
    required List<Map<String, dynamic>> upcoming,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lineStatusPrefix}_$routeCode';
    final data = jsonEncode({
      'routeCode': routeCode,
      'upcoming': upcoming,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(key, data);
    AppLogger.debug(_tag, 'writeMyLineStatus saved (key=$key)');
  }
}
