class ZoneModel {
  const ZoneModel({
    required this.id,
    required this.name,
    required this.zoneType,
    this.parentZoneId,
  });

  final String id;
  final String name;
  final String zoneType;
  final String? parentZoneId;

  factory ZoneModel.fromJson(Map<String, dynamic> j) => ZoneModel(
        id: j['id'] as String,
        name: j['name'] as String,
        zoneType: j['zoneType'] as String? ?? 'municipality',
        parentZoneId: j['parentZoneId'] as String?,
      );
}
