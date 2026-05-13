import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/app_logger.dart';

enum LocationServiceError {
  denied,
  deniedForever,
  disabled,
  timeout,
  unknown,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.error, [this.message]);
  final LocationServiceError error;
  final String? message;
}

/// Servicio de ubicación. Wrapper sobre geolocator con errores
/// tipados para que la UI pueda localizar sin importar la lib
/// nativa directamente. F8 lo introduce para detección geográfica
/// y carga lazy del operador cercano.
class LocationService {
  static const _logTag = 'Location';

  /// Verifica y solicita permiso de ubicación. Solo foreground.
  Future<LocationPermission> ensurePermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      // Verificar que el servicio de ubicación esté activo.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceException(
          LocationServiceError.disabled,
          'El servicio de ubicación está desactivado',
        );
      }
      return LocationPermission.always;
    }

    if (status.isPermanentlyDenied) {
      throw const LocationServiceException(
        LocationServiceError.deniedForever,
        'Permiso de ubicación denegado permanentemente. Actívalo en Ajustes.',
      );
    }

    throw const LocationServiceException(
      LocationServiceError.denied,
      'Permiso de ubicación denegado',
    );
  }

  /// Obtiene la posición actual con timeout.
  Future<Position?> getCurrent({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final hasPermission = await Permission.location.isGranted;
      if (!hasPermission) return null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(timeout);
    } catch (e) {
      AppLogger.warn(_logTag, 'getCurrent failed', e);
      return null;
    }
  }

  /// Stream de posición en tiempo real.
  Stream<Position> subscribe({
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    ),
  }) {
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Convierte [Position] a [LatLng].
  static LatLng toLatLng(Position pos) =>
      LatLng(pos.latitude, pos.longitude);
}
