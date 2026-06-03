class WizardStop {
  WizardStop({
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lng,
    this.stopType = 'custom',
    this.officialStopId,
    this.suggestAsOfficial = false,
    this.orderIndex = 0,
  });

  final String stopId;
  final String name;
  final double lat;
  final double lng;
  final String stopType;
  final String? officialStopId;
  final bool suggestAsOfficial;
  final int orderIndex;

  WizardStop copyWith({
    String? stopId,
    String? name,
    double? lat,
    double? lng,
    String? stopType,
    String? officialStopId,
    bool? suggestAsOfficial,
    int? orderIndex,
  }) {
    return WizardStop(
      stopId: stopId ?? this.stopId,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      stopType: stopType ?? this.stopType,
      officialStopId: officialStopId ?? this.officialStopId,
      suggestAsOfficial: suggestAsOfficial ?? this.suggestAsOfficial,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

class WizardSchedule {
  WizardSchedule({
    required this.dayType,
    required this.departureTime,
    this.originStopId,
    this.notes,
  });

  final String dayType;
  final String departureTime;
  final String? originStopId;
  final String? notes;
}

class WizardRoutePathPoint {
  WizardRoutePathPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

class WizardSegment {
  WizardSegment({
    required this.fromStopId,
    required this.toStopId,
    List<WizardRoutePathPoint>? points,
  }) : points = points ?? [];

  final String fromStopId;
  final String toStopId;
  final List<WizardRoutePathPoint> points;

  bool get isEmpty => points.isEmpty;
}

class WizardRoutePath {
  WizardRoutePath({List<WizardSegment>? segments})
      : segments = segments ?? [];
  final List<WizardSegment> segments;
}
