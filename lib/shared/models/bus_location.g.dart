// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusLocationImpl _$$BusLocationImplFromJson(Map<String, dynamic> json) =>
    _$BusLocationImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$BusLocationImplToJson(_$BusLocationImpl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      if (instance.bearing case final value?) 'bearing': value,
      'recordedAt': instance.recordedAt.toIso8601String(),
      if (instance.accuracy case final value?) 'accuracy': value,
    };
