import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/connectivity_provider.dart';
import '../cache/hive_box_provider.dart';
import 'offline_sync_service.dart';
import 'pending_actions_queue.dart';

/// Cola única de acciones pendientes para toda la app.
final pendingActionsQueueProvider = Provider<PendingActionsQueue>((ref) {
  final box = ref.watch(pendingActionsBoxProvider);
  final deadBox = ref.watch(deadLetterActionsBoxProvider);
  return PendingActionsQueue(box: box, deadBox: deadBox);
});

/// Conteo en vivo de acciones pendientes. Usado por
/// [OfflineBanner] para enseñar el badge.
final pendingActionsCountProvider = StreamProvider<int>((ref) {
  final queue = ref.watch(pendingActionsQueueProvider);
  return queue.pendingCountStream;
});

/// Servicio singleton del drainer. Escucha `isOfflineProvider` y
/// dispara `drainNow()` cuando la app vuelve a estar online.
///
/// Los repositorios con escrituras llaman a `registerExecutor` sobre
/// la instancia devuelta por este provider — típicamente en su
/// propio Riverpod provider o en una clase de bootstrap de la
/// feature.
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final queue = ref.watch(pendingActionsQueueProvider);
  final service = OfflineSyncService(queue: queue);

  // Al pasar de offline → online, drenamos. La primera lectura del
  // provider arranca el listener; siguientes overrides en tests
  // pueden cancelar con onDispose si reemplazan la instancia.
  ref.listen<bool>(isOfflineProvider, (prev, current) {
    if (prev == true && current == false) {
      service.drainNow();
    }
  });

  return service;
});
