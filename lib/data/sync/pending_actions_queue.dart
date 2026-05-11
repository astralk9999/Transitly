import 'dart:async';

import 'package:hive/hive.dart';

import '../../core/utils/app_logger.dart';
import 'pending_action.dart';

/// Cola FIFO de mutaciones pendientes sobre Hive. Persiste las
/// entradas serializadas como JSON; al leer, las parsea de vuelta a
/// [PendingAction]. La caja principal contiene acciones reintentables;
/// la dead letter recoge las que han superado [maxAttempts].
class PendingActionsQueue {
  PendingActionsQueue({
    required this.box,
    required this.deadBox,
  });

  final Box<Map<dynamic, dynamic>> box;
  final Box<Map<dynamic, dynamic>> deadBox;

  /// Tope de reintentos antes de mover a dead letter.
  static const int maxAttempts = 10;

  static const _logTag = 'OfflineSync:Queue';

  /// Encola una nueva acción. La clave Hive es [PendingAction.id]
  /// para permitir update-on-failure sin duplicados.
  Future<void> enqueue(PendingAction action) async {
    await box.put(action.id, action.toJson());
    AppLogger.info(_logTag, 'enqueued ${action.kind.name} (${action.id})');
  }

  /// Devuelve la acción más antigua sin retirarla.
  Future<PendingAction?> peek() async {
    if (box.isEmpty) return null;
    final actions = await list();
    return actions.isEmpty ? null : actions.first;
  }

  /// Lista todas las acciones en orden FIFO (más antigua primero).
  Future<List<PendingAction>> list() async {
    final result = <PendingAction>[];
    for (final raw in box.values) {
      result.add(_decode(raw));
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// Marca una acción como ejecutada con éxito y la retira de la cola.
  Future<void> remove(String id) async {
    await box.delete(id);
  }

  /// Aumenta el contador de fallos y guarda el error. Si supera
  /// [maxAttempts], mueve a la dead letter y limpia de la cola
  /// principal — el drainer la salta a partir de ese momento.
  Future<void> markFailure(PendingAction action, Object error) async {
    final updated = action.copyWith(
      attempts: action.attempts + 1,
      lastError: error.toString(),
    );
    if (updated.attempts > maxAttempts) {
      await deadBox.put(updated.id, updated.toJson());
      await box.delete(updated.id);
      AppLogger.warn(_logTag,
          'moved to dead letter: ${updated.kind.name} (${updated.id}) — ${updated.attempts} attempts');
    } else {
      await box.put(updated.id, updated.toJson());
      AppLogger.warn(_logTag,
          '${updated.kind.name} (${updated.id}) failed; attempt ${updated.attempts}/$maxAttempts');
    }
  }

  /// Conteo en vivo de acciones pendientes. Emite el valor inicial y
  /// cada vez que la caja cambia.
  Stream<int> get pendingCountStream {
    final controller = StreamController<int>.broadcast();
    controller.add(box.length);
    final sub = box.watch().listen((_) => controller.add(box.length));
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  int get pendingCount => box.length;
  int get deadLetterCount => deadBox.length;

  Future<List<PendingAction>> listDeadLetter() async {
    final result = <PendingAction>[];
    for (final raw in deadBox.values) {
      result.add(_decode(raw));
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Future<void> clearAll() async {
    await box.clear();
    await deadBox.clear();
  }

  static PendingAction _decode(Map<dynamic, dynamic> raw) {
    return PendingAction.fromJson(Map<String, dynamic>.from(raw));
  }
}
