import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_location.freezed.dart';
part 'bus_location.g.dart';

/// Posición geográfica instantánea de un bus o de cualquier entidad
/// móvil con orientación opcional. Pensado para extraerse de
/// [ActiveTripModel] cuando F4-F12 introduzcan telemetría real.
@freezed
class BusLocation with _$BusLocation {
  const factory BusLocation({
    required double lat,
    required double lng,
    double? bearing,
    required DateTime recordedAt,
    double? accuracy,
  }) = _BusLocation;

  factory BusLocation.fromJson(Map<String, dynamic> json) =>
      _$BusLocationFromJson(json);
}
