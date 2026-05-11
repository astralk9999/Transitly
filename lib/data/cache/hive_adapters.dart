import 'package:hive/hive.dart';

import '../../shared/models/alert_model.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/models/user_preferences.dart';

/// TypeAdapters para guardar modelos `@freezed` en Hive.
///
/// **Estrategia.** Los modelos de F1 ya tienen `fromJson`/`toJson`
/// (manuales en lote 1+2, generados por `json_serializable` en F1.3).
/// Cada adapter delega en esos métodos y solo se ocupa de mover el
/// `Map<String, dynamic>` a través del `BinaryReader`/`BinaryWriter`
/// de Hive. Sin codegen extra, sin acoplar el modelo a Hive.
///
/// **Asignación de typeIds.** Estable y append-only — nunca reasignar
/// un `typeId` ya usado, aunque se elimine el modelo. Los nuevos
/// modelos cogen el siguiente entero libre.
///
/// | typeId | Modelo            |
/// |-------:|-------------------|
/// |   0    | RouteModel        |
/// |   1    | StopModel         |
/// |   2    | ScheduleModel     |
/// |   3    | OperatorModel     |
/// |   4    | UserPreferences   |
/// |   5    | OfflineRegion     |
/// |   6    | AlertModel        |
/// |   7    | IncidentModel     |
///
/// Si añades un modelo cacheable nuevo: extiende esta tabla, crea su
/// adapter abajo y registra en `HiveAdapters.registerAll()`.

abstract class HiveAdapters {
  HiveAdapters._();

  /// Llamar una sola vez al arrancar la app, antes de abrir cajas.
  /// Idempotente: Hive ignora un registro repetido del mismo typeId.
  static void registerAll() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(_RouteModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(_StopModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(_ScheduleModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(_OperatorModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(_UserPreferencesAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(_OfflineRegionAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(_AlertModelAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(_IncidentModelAdapter());
  }
}

/// Helper para mover un `Map<String, dynamic>` a través del binario de
/// Hive sin perder los tipos anidados. Hive no expone API directa para
/// `Map<String, dynamic>`; serializamos como `Map<dynamic, dynamic>` y
/// hacemos el cast al leer.
Map<String, dynamic> _readJsonMap(BinaryReader reader) {
  final raw = reader.read();
  if (raw is Map) return Map<String, dynamic>.from(raw);
  throw StateError('Expected Map in Hive payload, got ${raw.runtimeType}');
}

class _RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final int typeId = 0;

  @override
  RouteModel read(BinaryReader reader) =>
      RouteModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, RouteModel obj) =>
      writer.write(obj.toJson());
}

class _StopModelAdapter extends TypeAdapter<StopModel> {
  @override
  final int typeId = 1;

  @override
  StopModel read(BinaryReader reader) =>
      StopModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, StopModel obj) =>
      writer.write(obj.toJson());
}

class _ScheduleModelAdapter extends TypeAdapter<ScheduleModel> {
  @override
  final int typeId = 2;

  @override
  ScheduleModel read(BinaryReader reader) =>
      ScheduleModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, ScheduleModel obj) =>
      writer.write(obj.toJson());
}

class _OperatorModelAdapter extends TypeAdapter<OperatorModel> {
  @override
  final int typeId = 3;

  @override
  OperatorModel read(BinaryReader reader) =>
      OperatorModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, OperatorModel obj) =>
      writer.write(obj.toJson());
}

class _UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 4;

  @override
  UserPreferences read(BinaryReader reader) =>
      UserPreferences.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, UserPreferences obj) =>
      writer.write(obj.toJson());
}

class _OfflineRegionAdapter extends TypeAdapter<OfflineRegion> {
  @override
  final int typeId = 5;

  @override
  OfflineRegion read(BinaryReader reader) =>
      OfflineRegion.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, OfflineRegion obj) =>
      writer.write(obj.toJson());
}

class _AlertModelAdapter extends TypeAdapter<AlertModel> {
  @override
  final int typeId = 6;

  @override
  AlertModel read(BinaryReader reader) =>
      AlertModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, AlertModel obj) =>
      writer.write(obj.toJson());
}

class _IncidentModelAdapter extends TypeAdapter<IncidentModel> {
  @override
  final int typeId = 7;

  @override
  IncidentModel read(BinaryReader reader) =>
      IncidentModel.fromJson(_readJsonMap(reader));

  @override
  void write(BinaryWriter writer, IncidentModel obj) =>
      writer.write(obj.toJson());
}
