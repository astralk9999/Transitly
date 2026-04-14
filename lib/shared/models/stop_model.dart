class StopModel {
  const StopModel({
    required this.id,
    required this.name,
    required this.officialCode,
    required this.lat,
    required this.lng,
    required this.municipality,
    this.zoneId,
    this.hasShelter = false,
    this.hasBench = false,
    this.isAccessible = false,
    this.hasDisplay = false,
    this.photoUrl,
    this.notes,
  });

  final String id;
  final String name;
  final String officialCode;
  final double lat;
  final double lng;
  final String municipality;
  final String? zoneId;
  final bool hasShelter;
  final bool hasBench;
  final bool isAccessible;
  final bool hasDisplay;
  final String? photoUrl;
  final String? notes;

  factory StopModel.fromJson(Map<String, dynamic> j) => StopModel(
        id: j['officialCode'] as String? ?? j['name'] as String,
        name: j['name'] as String,
        officialCode: j['officialCode'] as String? ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        municipality: j['municipality'] as String? ?? '',
        hasShelter: j['hasShelter'] as bool? ?? false,
        hasBench: j['hasBench'] as bool? ?? false,
        isAccessible: j['isAccessible'] as bool? ?? false,
      );
}
