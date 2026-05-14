import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/sync/offline_sync_provider.dart';
import '../providers/connectivity_provider.dart';

/// Banner que se asoma cuando la conectividad está caída o la cola
/// offline tiene mutaciones pendientes. Pensado para colocarse en lo
/// alto de cualquier Scaffold:
///
/// ```dart
/// Column(children: [
///   const OfflineBanner(),
///   Expanded(child: bodyContents),
/// ])
/// ```
///
/// Cuando no hay nada que reportar (online + cola vacía), se reduce
/// a `SizedBox.shrink()` y no ocupa espacio.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final pendingAsync = ref.watch(pendingActionsCountProvider);
    final pendingCount = pendingAsync.maybeWhen(
      data: (n) => n,
      orElse: () => 0,
    );

    if (!isOffline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final message = _buildMessage(isOffline, pendingCount);

    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
      color: c.stateDelay,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off : Icons.cloud_upload_outlined,
                size: 18,
                color: c.bgRoot,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TransitTypography.bodySecondary(c.bgRoot),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _buildMessage(bool offline, int pending) {
    if (offline && pending > 0) {
      return 'Sin conexión · $pending acción${pending == 1 ? '' : 'es'} en cola.';
    }
    if (offline) {
      return 'Sin conexión. Los cambios se guardarán y se enviarán al volver.';
    }
    return 'Sincronizando $pending acción${pending == 1 ? '' : 'es'} pendiente${pending == 1 ? '' : 's'}…';
  }
}
