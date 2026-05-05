import 'package:freezed_annotation/freezed_annotation.dart';

part 'zone_model.freezed.dart';

@freezed
class ZoneModel with _$ZoneModel {
  const ZoneModel._();

  const factory ZoneModel({
    required String id,
    required String name,
    required String zoneType,
    String? parentZoneId,
  }) = _ZoneModel;

  static ZoneModel fromJson(Map<String, dynamic> j) => ZoneModel(
        id: j['id'] as String,
        name: j['name'] as String,
        zoneType: j['zoneType'] as String? ?? 'municipality',
        parentZoneId: j['parentZoneId'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'zoneType': zoneType,
        if (parentZoneId != null) 'parentZoneId': parentZoneId,
      };
}
