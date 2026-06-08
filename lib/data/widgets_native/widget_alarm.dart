import 'dart:convert';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import 'widget_data_writer.dart';

/// Refresco PERIÓDICO de los widgets en segundo plano, con el intervalo que el
/// usuario elige en "Frecuencia de refresco".
///
/// Cómo funciona (sin Hive ni Riverpod, para que valga en un isolate de fondo):
/// la app, al estar en primer plano, persiste en SharedPreferences el horario
/// COMPLETO de hoy por la parada habitual (ver [WidgetDataWriter.writeBackgroundSchedule]).
/// Cada tick de la alarma, este callback recalcula el próximo bus / "en
/// servicio" desde ese horario + el reloj del dispositivo y reescribe los
/// widgets. Así el dato se mantiene fresco cada N minutos aunque la app esté
/// cerrada, sin red.
class WidgetAlarm {
  WidgetAlarm._();

  static const _tag = 'WidgetAlarm';
  static const int alarmId = 42; // id fijo: reprogramar sustituye el anterior
  static bool _initialized = false;

  /// Inicializa el gestor de alarmas (idempotente). Se llama desde reschedule,
  /// así que no es obligatorio invocarlo aparte.
  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      await AndroidAlarmManager.initialize();
      _initialized = true;
    } catch (e) {
      AppLogger.warn(_tag, 'AndroidAlarmManager.initialize failed', e);
    }
  }

  /// (Re)programa el refresco periódico cada [minutes] minutos. Cancelar y
  /// volver a crear con el mismo id aplica el intervalo nuevo.
  static Future<void> reschedule(int minutes) async {
    if (kIsWeb) return;
    await init();
    final m = minutes.clamp(15, 180);
    try {
      await AndroidAlarmManager.cancel(alarmId);
      await AndroidAlarmManager.periodic(
        Duration(minutes: m),
        alarmId,
        widgetAlarmCallback,
        exact: false,
        wakeup: false,
        rescheduleOnReboot: true,
      );
      AppLogger.info(_tag, 'periodic widget refresh every ${m}min');
    } catch (e) {
      AppLogger.warn(_tag, 'reschedule failed', e);
    }
  }

  /// Cancela el refresco periódico (p. ej. al quitar el viaje habitual).
  static Future<void> cancel() async {
    if (kIsWeb) return;
    try {
      await AndroidAlarmManager.cancel(alarmId);
    } catch (_) {}
  }
}

/// Callback de la alarma (corre en un isolate de fondo). Debe ser top-level y
/// llevar la anotación vm:entry-point para que sobreviva al tree-shaking.
@pragma('vm:entry-point')
Future<void> widgetAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(WidgetDataWriter.kBgRoute);
    final stop = prefs.getString(WidgetDataWriter.kBgStop);
    final timesJson = prefs.getString(WidgetDataWriter.kBgTodayTimes);
    if (route == null || route.isEmpty || timesJson == null) return;

    final times = (jsonDecode(timesJson) as List).cast<String>();
    if (times.isEmpty) return;

    int minOf(String t) {
      final p = t.split(':');
      return (int.tryParse(p[0]) ?? 0) * 60 +
          (p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
    }

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final upcoming = times.where((t) => minOf(t) >= nowMin).toList()..sort();
    final inService = upcoming.isNotEmpty;
    final shown = (inService ? upcoming : times).take(4).toList();
    final eta = inService ? (minOf(upcoming.first) - nowMin) : 0;

    await WidgetDataWriter.writeNextBus(
      stopName: stop ?? route,
      routeCode: route,
      etaMinutes: eta,
      source: 'auto',
      updatedAt: now,
      inService: inService,
      nextDepartureTime: inService ? upcoming.first : times.first,
    );
    await WidgetDataWriter.writeMyLineStatus(
      routeCode: route,
      upcoming: shown.map((t) => {'time': t}).toList(),
      inService: inService,
    );
  } catch (_) {
    // Silencioso: el siguiente tick lo reintentará.
  }
}
