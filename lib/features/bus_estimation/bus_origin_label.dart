import '../../../shared/models/enums.dart';

/// Etiqueta visual para identificar el origen del dato de posición
/// de un bus en el mapa. F13.3 la conecta al widget de marcadores.
enum BusOriginLabel {
  officialLive,
  officialEstimated,
  communityDriver,
  communityEstimated,
}

/// Helper: determina la etiqueta a partir del source de la ruta y
/// el source de la posición.
BusOriginLabel labelFor({
  required RouteSource routeSource,
  required BusPositionSource positionSource,
}) {
  return switch ((routeSource, positionSource)) {
    (RouteSource.official, BusPositionSource.gtfsRealtime) =>
      BusOriginLabel.officialLive,
    (RouteSource.official, BusPositionSource.driver) =>
      BusOriginLabel.officialLive,
    (RouteSource.official, BusPositionSource.estimated) =>
      BusOriginLabel.officialEstimated,
    (RouteSource.community, BusPositionSource.driver) =>
      BusOriginLabel.communityDriver,
    (RouteSource.community, _) =>
      BusOriginLabel.communityEstimated,
  };
}

extension BusOriginLabelExtension on BusOriginLabel {
  String get displayName => switch (this) {
        BusOriginLabel.officialLive => 'Oficial · en vivo',
        BusOriginLabel.officialEstimated => 'Oficial · estimado',
        BusOriginLabel.communityDriver => 'Comunidad · conductor',
        BusOriginLabel.communityEstimated => 'Comunidad · estimado',
      };

  bool get isOfficial =>
      this == BusOriginLabel.officialLive ||
      this == BusOriginLabel.officialEstimated;
}
