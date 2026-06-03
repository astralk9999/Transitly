import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../data/geo/location_service.dart';

class UserLocationFix {
  const UserLocationFix({required this.position, required this.accuracy});
  final LatLng position;
  final double accuracy;
}

const _logTag = 'Provider:UserLocation';

final userLocationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationPermissionProvider =
    FutureProvider<LocationPermission>((ref) async {
  final service = ref.read(userLocationServiceProvider);
  return service.ensurePermission();
});

/// Stream de la ubicación del usuario.
///
/// Implementación crítica: usa `async*` para poder hacer `await` sobre el
/// permiso ANTES de suscribirse a `Geolocator.getPositionStream()`. Sin
/// esto, geolocator devuelve un stream "muerto" si la primera invocación
/// ocurre con permiso denied (aunque luego se conceda y se re-suscriba).
///
/// Cuando el usuario concede permiso en runtime y llamamos
/// `ref.invalidate(userLocationPermissionProvider)`, este provider se
/// reconstruye, awaita el permiso ya granted, y arranca geolocator
/// limpiamente.
final userLocationStreamProvider =
    StreamProvider.autoDispose<UserLocationFix?>((ref) {
  return _locationStream(ref);
});

Stream<UserLocationFix?> _locationStream(Ref ref) async* {
  // 1) Esperar al permiso. Si está en runtime prompt, este await
  //    bloquea hasta que el usuario responda.
  final LocationPermission permission;
  try {
    permission = await ref.watch(userLocationPermissionProvider.future);
  } catch (e) {
    AppLogger.warn(_logTag, 'permission resolve failed', e);
    yield null;
    return;
  }

  // 2) Sin permiso utilizable → emitir null y salir. Cuando el
  //    permission provider se invalide tras conceder en runtime,
  //    este stream se reconstruye y vuelve a empezar.
  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    yield null;
    return;
  }

  // 3) Permiso granted: suscribirse a geolocator AHORA, no antes.
  final service = ref.read(userLocationServiceProvider);
  Stream<Position> positionStream;
  try {
    positionStream = service.subscribe(
      settings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  } catch (e) {
    AppLogger.warn(_logTag, 'position stream failed', e);
    yield null;
    return;
  }

  // 4) Re-emitir cada posición como UserLocationFix. Si el stream
  //    falla, emite null y termina (Riverpod podrá re-disparar el
  //    provider si se invalida).
  try {
    await for (final pos in positionStream) {
      yield UserLocationFix(
        position: LocationService.toLatLng(pos),
        accuracy: pos.accuracy,
      );
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'position stream error', e);
    yield null;
  }
}

final userLocationLatLngProvider = Provider<LatLng?>((ref) =>
    ref.watch(userLocationStreamProvider).valueOrNull?.position);
