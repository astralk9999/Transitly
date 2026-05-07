import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/models/user_preferences.dart';
import 'hive_adapters.dart';

/// Nombres de cajas Hive de Transitly.
///
/// Mantener constantes en lugar de strings sueltos: previene typos
/// silenciosos al leer/escribir la caja equivocada.
abstract class HiveBoxes {
  HiveBoxes._();

  static const routes = 'routes';
  static const stops = 'stops';
  static const schedules = 'schedules';
  static const operators = 'operators';
  static const userPreferences = 'user_preferences';
  static const offlineRegions = 'offline_regions';
  static const alerts = 'alerts';

  /// Cola de mutaciones offline. Cada entrada es un `Map<String,
  /// dynamic>` con la forma del payload (definida en F3.3).
  static const pendingActions = 'pending_actions';

  /// Metadatos de la sesión Auth (último uid, expiración tokens, …).
  /// Sirve para mostrar UI placeholder mientras Supabase rehidrata.
  static const authSessionMeta = 'auth_session_meta';
}

/// Inicializa Hive (registro de adapters + apertura de cajas).
///
/// Se llama desde `main.dart` entre `Env.load()` y
/// `Supabase.initialize()`. Si alguna caja está corrupta o la
/// versión del adapter cambió de forma incompatible, se loguea el
/// fallo y se borra la caja: prefiero perder el caché a romper el
/// arranque.
abstract class HiveInit {
  HiveInit._();

  static const _logTag = 'HiveCache';

  static Future<void> bootstrap() async {
    await Hive.initFlutter();
    HiveAdapters.registerAll();
    await _openAll();
  }

  static Future<void> _openAll() async {
    await _open<RouteModel>(HiveBoxes.routes);
    await _open<StopModel>(HiveBoxes.stops);
    await _open<ScheduleModel>(HiveBoxes.schedules);
    await _open<OperatorModel>(HiveBoxes.operators);
    await _open<UserPreferences>(HiveBoxes.userPreferences);
    await _open<OfflineRegion>(HiveBoxes.offlineRegions);
    await _open<AlertModel>(HiveBoxes.alerts);

    // Cajas sin tipo fijado: cada entrada es `Map<dynamic, dynamic>`
    // serializable directamente por Hive (los maps se cargan así por
    // limitación del binario; el cast a `Map<String, dynamic>` se hace
    // en el repositorio que consume cada entrada).
    await _open<Map<dynamic, dynamic>>(HiveBoxes.pendingActions);
    await _open<Map<dynamic, dynamic>>(HiveBoxes.authSessionMeta);

    AppLogger.info(_logTag, 'opened ${Hive.box(HiveBoxes.routes).path != null ? "all" : "?"} boxes');
  }

  static Future<Box<T>> _open<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e, st) {
      AppLogger.error(_logTag, 'open box "$name" failed; deleting and retrying', e, st);
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name);
    }
  }

  /// Cierra todas las cajas y libera handles. Útil en tests para
  /// limpiar entre runs sin reiniciar el binding.
  static Future<void> dispose() async {
    await Hive.close();
  }
}
