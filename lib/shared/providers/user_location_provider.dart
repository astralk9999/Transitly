import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../data/geo/location_service.dart';

const _logTag = 'Provider:UserLocation';

final userLocationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationPermissionProvider =
    FutureProvider<LocationPermission>((ref) async {
  final service = ref.read(userLocationServiceProvider);
  return service.ensurePermission();
});

final userLocationStreamProvider =
    StreamProvider.autoDispose<LatLng?>((ref) {
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
    return const Stream.empty();
  }

  final controller = StreamController<LatLng?>();

  positionStream.listen(
    (pos) {
      if (!controller.isClosed) {
        controller.add(LocationService.toLatLng(pos));
      }
    },
    onError: (e) {
      AppLogger.warn(_logTag, 'position stream error', e);
      if (!controller.isClosed) controller.add(null);
    },
  );

  ref.onDispose(controller.close);

  return controller.stream;
});
