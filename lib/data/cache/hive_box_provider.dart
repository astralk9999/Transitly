import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../shared/models/alert_model.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/models/user_preferences.dart';
import 'hive_init.dart';

/// Providers que exponen las cajas Hive abiertas en
/// [HiveInit.bootstrap]. Asumen que el bootstrap ya corrió en
/// `main.dart`; si se accede desde un test que no inicializa Hive,
/// añadir un `.overrideWithValue(...)` con un mock.
///
/// **Convención de claves.** Documentada en `ARCHITECTURE.md §6.4`:
/// `<scope>:<id>` para colecciones de un mismo dominio. Ejemplos:
/// - `op:comujesa:route:L1` — ruta L1 del operador COMUJESA.
/// - `op:comujesa:stop:JER-001` — parada con `officialCode` JER-001.
/// - `user:<uid>:fav:<stopId>` — favorita de un usuario sobre un stop.
/// - `user:<uid>:pref` — preferencias del usuario (singleton por uid).
///
/// Mantener el prefijo permite filtrar/borrar por scope sin tener
/// que listar la caja entera.

final routesBoxProvider = Provider<Box<RouteModel>>(
  (_) => Hive.box<RouteModel>(HiveBoxes.routes),
);

final stopsBoxProvider = Provider<Box<StopModel>>(
  (_) => Hive.box<StopModel>(HiveBoxes.stops),
);

final schedulesBoxProvider = Provider<Box<ScheduleModel>>(
  (_) => Hive.box<ScheduleModel>(HiveBoxes.schedules),
);

final operatorsBoxProvider = Provider<Box<OperatorModel>>(
  (_) => Hive.box<OperatorModel>(HiveBoxes.operators),
);

final userPreferencesBoxProvider = Provider<Box<UserPreferences>>(
  (_) => Hive.box<UserPreferences>(HiveBoxes.userPreferences),
);

final offlineRegionsBoxProvider = Provider<Box<OfflineRegion>>(
  (_) => Hive.box<OfflineRegion>(HiveBoxes.offlineRegions),
);

final alertsBoxProvider = Provider<Box<AlertModel>>(
  (_) => Hive.box<AlertModel>(HiveBoxes.alerts),
);

final incidentsBoxProvider = Provider<Box<IncidentModel>>(
  (_) => Hive.box<IncidentModel>(HiveBoxes.incidents),
);

/// Cola de mutaciones offline. Las entradas son `PendingAction`
/// serializadas a JSON (ver `lib/data/sync/pending_action.dart`).
final pendingActionsBoxProvider = Provider<Box<Map<dynamic, dynamic>>>(
  (_) => Hive.box<Map<dynamic, dynamic>>(HiveBoxes.pendingActions),
);

/// Tabla muerta de mutaciones tras 10 fallos. La UI puede listarla
/// para que el usuario decida reintentar o descartar.
final deadLetterActionsBoxProvider = Provider<Box<Map<dynamic, dynamic>>>(
  (_) => Hive.box<Map<dynamic, dynamic>>(HiveBoxes.deadLetterActions),
);

/// Metadatos de sesión Auth (último uid, expiraciones, banderas).
final authSessionMetaBoxProvider = Provider<Box<Map<dynamic, dynamic>>>(
  (_) => Hive.box<Map<dynamic, dynamic>>(HiveBoxes.authSessionMeta),
);
