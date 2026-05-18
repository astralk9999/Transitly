import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_region.freezed.dart';
part 'offline_region.g.dart';

enum OfflineRegionStatus { downloading, ready, stale, error }

/// Bounding box geográfico que delimita una región offline. Equivalente
/// a `LatLngBounds` pero con campos explícitos serializables a JSON.
@freezed
abstract class OfflineRegionBounds with _$OfflineRegionBounds {
  const factory OfflineRegionBounds({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) = _OfflineRegionBounds;

  factory OfflineRegionBounds.fromJson(Map<String, dynamic> json) =>
      _$OfflineRegionBoundsFromJson(json);
}

/// Una región del mapa descargada para uso offline (tiles + datos).
/// Habilitada en F20 cuando se introduzcan los tiles MapTiler.
@freezed
abstract class OfflineRegion with _$OfflineRegion {
  const factory OfflineRegion({
    required String id,
    required String label,
    required OfflineRegionBounds bounds,
    required int zoomMin,
    required int zoomMax,
    required DateTime downloadedAt,
    required int sizeBytes,
    required OfflineRegionStatus status,
    DateTime? dataSyncedAt,
  }) = _OfflineRegion;

  factory OfflineRegion.fromJson(Map<String, dynamic> json) =>
      _$OfflineRegionFromJson(json);
}
