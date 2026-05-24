import 'dart:async';
import 'dart:math' as math;

import '../../core/utils/app_logger.dart';
import 'pending_action.dart';
import 'pending_actions_queue.dart';

/// Función que un repositorio remoto registra para que la cola sepa
/// cómo aplicar su tipo de acción. Recibe el payload tal como se
/// encoló y devuelve sin error si la mutación se aplicó.
typedef PendingActionExecutor =
    Future<void> Function(Map<String, dynamic> payload);

/// Drainer de la cola de acciones offline.
///
/// Patrón:
/// - Cada repositorio remoto con escrituras llama a
///   [registerExecutor] al ser instanciado.
/// - Cuando la app vuelve a estar online, alguien invoca [drainNow].
/// - El drainer recorre la cola FIFO, intenta ejecutar el `kind`
///   correspondiente con backoff exponencial entre fallos. Si no hay
///   ejecutor registrado para un `kind`, salta el resto del drenado
///   (probablemente la feature aún no aterrizó).
///
/// Backoff: 1s, 2s, 4s, 8s, 16s, 32s, max 60s. Se calcula a partir
/// del número de intentos de la propia acción tras marcar fallo.
class OfflineSyncService {
  OfflineSyncService({required this.queue});

  final PendingActionsQueue queue;

  final Map<PendingActionKind, PendingActionExecutor> _executors = {};
  bool _draining = false;

  static const _logTag = 'OfflineSync';

  /// Conecta un `kind` con la función que lo ejecuta. Idempotente:
  /// volver a registrar sobrescribe.
  void registerExecutor(
    PendingActionKind kind,
    PendingActionExecutor executor,
  ) {
    _executors[kind] = executor;
    AppLogger.info(_logTag, 'executor registered: ${kind.name}');
  }

  /// Intenta drenar toda la cola en orden FIFO. Si ya hay un drenado
  /// en curso, devuelve inmediatamente — concurrencia controlada
  /// por el flag [_draining].
  Future<void> drainNow() async {
    if (_draining) {
      AppLogger.info(_logTag, 'drain already in progress');
      return;
    }
    _draining = true;
    try {
      while (true) {
        final action = await queue.peek();
        if (action == null) {
          AppLogger.info(_logTag, 'queue empty');
          break;
        }
        final executor = _executors[action.kind];
        if (executor == null) {
          AppLogger.warn(_logTag,
              'no executor for ${action.kind.name} (id=${action.id}); discarding to avoid blocking drain');
          await queue.remove(action.id);
          continue;
        }
        try {
          await executor(action.payload);
          await queue.remove(action.id);
          AppLogger.info(_logTag,
              'applied ${action.kind.name} (${action.id})');
        } catch (e) {
          AppLogger.warn(_logTag,
              'apply ${action.kind.name} (${action.id}) failed', e);
          await queue.markFailure(action, e);
          // Backoff: paramos el drenado en este ciclo. El siguiente
          // disparo (al volver online o por timer) intentará otra
          // vez con la cuenta de intentos actualizada.
          await Future<void>.delayed(_backoff(action.attempts + 1));
          break;
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Duración del backoff exponencial, cap a 60s.
  static Duration _backoff(int attempts) {
    final raw = math.pow(2, math.max(0, attempts - 1)).toInt();
    final seconds = math.min(60, raw);
    return Duration(seconds: seconds);
  }
}
