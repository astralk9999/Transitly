import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/providers/home_habitual_config_provider.dart';
import '../mock/mock_data_service.dart';
import 'widget_data_writer.dart';

/// Sub-F P1-04: refresca los datos de los 3 widgets nativos.
///
/// La lógica es la misma que ejecuta `_widgetBackgroundCallback` en main.dart
/// (invocado por home_widget desde el lado Kotlin cuando Android decide
/// actualizar el widget), pero expuesta como método público para que el botón
/// "Refrescar ahora" del panel de apariencia pueda forzar la actualización en
/// foreground.
class WidgetRefreshService {
  const WidgetRefreshService._();

  static const _tag = 'WidgetRefresh';

  /// Lee la línea habitual del usuario, calcula próximas salidas mock y las
  /// escribe en los 3 widgets. Devuelve `true` si escribió datos.
  static Future<bool> refreshNow(ProviderContainer container) async {
    try {
      final mockData = container.read(mockDataServiceProvider);
      final cfg = container.read(homeHabitualConfigProvider);
      if (!cfg.isConfigured) {
        AppLogger.debug(_tag, 'refreshNow skipped — no habitual config');
        return false;
      }
      final route = mockData.getRouteById(cfg.routeId!);
      if (route == null) return false;

      // Salidas reales de HOY pendientes: si las hay, la línea está EN
      // SERVICIO ahora. Si no, usamos getNextDepartures (que cae a mañana)
      // solo para mostrar a qué hora reanuda, pero marcando fuera de servicio.
      final todayDeps =
          mockData.getUpcomingTodayDepartures(cfg.routeId!, cfg.stopId!, 4);
      final inService = todayDeps.isNotEmpty;
      final deps = inService
          ? todayDeps
          : mockData.getNextDepartures(cfg.routeId!, cfg.stopId!, 4);
      if (deps.isEmpty) return false;

      final first = deps.first;
      final now = DateTime.now();
      final parts = first.departureTime.split(':');
      final depHour = int.tryParse(parts[0]) ?? 0;
      final depMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final depMinutes = depHour * 60 + depMin;
      final nowMinutes = now.hour * 60 + now.minute;
      var eta = depMinutes - nowMinutes;
      if (eta < 0) eta += 24 * 60;

      final stop = mockData.getStopById(cfg.stopId!);

      await WidgetDataWriter.writeNextBus(
        stopName: stop?.name ?? cfg.stopId!,
        routeCode: route.code,
        etaMinutes: eta,
        source: 'manual',
        updatedAt: now,
        inService: inService,
        nextDepartureTime: first.departureTime,
      );
      await WidgetDataWriter.writeMyLineStatus(
        routeCode: route.code,
        upcoming: deps.map((d) => {'time': d.departureTime}).toList(),
        inService: inService,
      );
      // Persiste el horario COMPLETO de hoy para el refresco periódico en
      // segundo plano (recalcula el próximo bus cada N min sin la app abierta).
      await WidgetDataWriter.writeBackgroundSchedule(
        routeCode: route.code,
        stopName: stop?.name ?? cfg.stopId!,
        todayTimes: mockData.getTodayStopTimesAll(cfg.routeId!, cfg.stopId!),
      );
      AppLogger.info(_tag,
          'refreshNow ok — inService=$inService eta=${eta}min route=${route.code}');
      return true;
    } catch (e) {
      AppLogger.warn(_tag, 'refreshNow failed', e);
      return false;
    }
  }
}
