import 'package:freezed_annotation/freezed_annotation.dart';

part 'stop_model.freezed.dart';

@freezed
abstract class StopModel with _$StopModel {
  const StopModel._();

  const factory StopModel({
    required String id,
    required String name,
    required String officialCode,
    required double lat,
    required double lng,
    required String municipality,
    String? zoneId,
    @Default(false) bool hasShelter,
    @Default(false) bool hasBench,
    @Default(false) bool isAccessible,
    @Default(false) bool hasDisplay,
    String? photoUrl,
    String? notes,
  }) = _StopModel;

  // Custom mapping (id derivado de officialCode || name). Static en lugar
  // de factory para no engatillar json_serializable, que generaría un
  // .g.dart innecesario porque el cuerpo no llama a _$StopModelFromJson.
  static StopModel fromJson(Map<String, dynamic> j) => StopModel(
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (officialCode.isNotEmpty) 'officialCode': officialCode,
        'name': name,
        'lat': lat,
        'lng': lng,
        if (municipality.isNotEmpty) 'municipality': municipality,
        if (zoneId != null) 'zoneId': zoneId,
        'hasShelter': hasShelter,
        'hasBench': hasBench,
        'isAccessible': isAccessible,
        if (hasDisplay) 'hasDisplay': hasDisplay,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (notes != null) 'notes': notes,
      };
}
