// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusLocation _$BusLocationFromJson(Map<String, dynamic> json) => _BusLocation(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  bearing: (json['bearing'] as num?)?.toDouble(),
  recordedAt: DateTime.parse(json['recordedAt'] as String),
  accuracy: (json['accuracy'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BusLocationToJson(_BusLocation instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'bearing': ?instance.bearing,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'accuracy': ?instance.accuracy,
    };
