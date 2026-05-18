// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OfflineRegionBounds _$OfflineRegionBoundsFromJson(Map<String, dynamic> json) =>
    _OfflineRegionBounds(
      northLat: (json['northLat'] as num).toDouble(),
      southLat: (json['southLat'] as num).toDouble(),
      eastLng: (json['eastLng'] as num).toDouble(),
      westLng: (json['westLng'] as num).toDouble(),
    );

Map<String, dynamic> _$OfflineRegionBoundsToJson(
  _OfflineRegionBounds instance,
) => <String, dynamic>{
  'northLat': instance.northLat,
  'southLat': instance.southLat,
  'eastLng': instance.eastLng,
  'westLng': instance.westLng,
};

_OfflineRegion _$OfflineRegionFromJson(Map<String, dynamic> json) =>
    _OfflineRegion(
      id: json['id'] as String,
      label: json['label'] as String,
      bounds: OfflineRegionBounds.fromJson(
        json['bounds'] as Map<String, dynamic>,
      ),
      zoomMin: (json['zoomMin'] as num).toInt(),
      zoomMax: (json['zoomMax'] as num).toInt(),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      status: $enumDecode(_$OfflineRegionStatusEnumMap, json['status']),
      dataSyncedAt: json['dataSyncedAt'] == null
          ? null
          : DateTime.parse(json['dataSyncedAt'] as String),
    );

Map<String, dynamic> _$OfflineRegionToJson(_OfflineRegion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'bounds': instance.bounds.toJson(),
      'zoomMin': instance.zoomMin,
      'zoomMax': instance.zoomMax,
      'downloadedAt': instance.downloadedAt.toIso8601String(),
      'sizeBytes': instance.sizeBytes,
      'status': _$OfflineRegionStatusEnumMap[instance.status]!,
      'dataSyncedAt': ?instance.dataSyncedAt?.toIso8601String(),
    };

const _$OfflineRegionStatusEnumMap = {
  OfflineRegionStatus.downloading: 'downloading',
  OfflineRegionStatus.ready: 'ready',
  OfflineRegionStatus.stale: 'stale',
  OfflineRegionStatus.error: 'error',
};
