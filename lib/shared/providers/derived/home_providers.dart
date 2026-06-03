import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/mock/mock_data_service.dart';
import '../../models/alert_model.dart';
import '../../models/stop_model.dart';
import '../user_location_provider.dart';
import '../user_provider.dart';

/// Conjunto de routeIds favoritos del usuario actual.
///
/// Filtra `mockData.favorites` por `currentUserProvider.id`. Si en el
/// futuro las favoritas viven en su propia colección por usuario, este
/// provider sigue siendo el único punto de derivación.
final homeFavRouteIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);
  final user = ref.watch(currentUserProvider);
  return mockData.favorites
      .where((f) => f.userId == user.id)
      .map((f) => f.routeId)
      .toSet();
});

/// Parada habitual del usuario: la `homeStopId` de su primera favorita,
/// resuelta a un [StopModel]. `null` si no hay favoritas o si la parada
/// referenciada ya no existe.
final homeHabitualStopProvider = Provider.autoDispose<StopModel?>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);
  final user = ref.watch(currentUserProvider);
  final favs = mockData.favorites.where((f) => f.userId == user.id);
  if (favs.isEmpty) return null;
  final stopId = favs.first.homeStopId;
  if (stopId == null) return null;
  return mockData.getStopById(stopId);
});

/// Paradas más cercanas a un punto, hasta [count] resultados.
///
/// Wrapper Riverpod sobre `MockDataService.getNearbyStops` para que el
/// widget no llame al servicio dentro de su `build()`.
final homeNearbyStopsProvider =
    Provider.autoDispose.family<List<StopModel>, ({LatLng center, int count})>(
        (ref, args) {
  final mockData = ref.watch(mockDataServiceProvider);
  return mockData.getNearbyStops(
    args.center.latitude,
    args.center.longitude,
    args.count,
  );
});

/// Avisos activos para las rutas favoritas del usuario, filtrados por
/// proximidad geográfica cuando la alerta tiene restricción de zona.
final homeFavAlertsProvider = Provider.autoDispose<List<AlertModel>>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);
  final favIds = ref.watch(homeFavRouteIdsProvider);
  final userLoc = ref.watch(userLocationLatLngProvider);
  return mockData.getAlertsAffecting(
    userLocation: userLoc,
    favoriteRouteIds: favIds.toList(),
  );
});
