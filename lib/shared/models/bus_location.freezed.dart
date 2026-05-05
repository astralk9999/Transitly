// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bus_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BusLocation _$BusLocationFromJson(Map<String, dynamic> json) {
  return _BusLocation.fromJson(json);
}

/// @nodoc
mixin _$BusLocation {
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  double? get bearing => throw _privateConstructorUsedError;
  DateTime get recordedAt => throw _privateConstructorUsedError;
  double? get accuracy => throw _privateConstructorUsedError;

  /// Serializes this BusLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusLocationCopyWith<BusLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusLocationCopyWith<$Res> {
  factory $BusLocationCopyWith(
    BusLocation value,
    $Res Function(BusLocation) then,
  ) = _$BusLocationCopyWithImpl<$Res, BusLocation>;
  @useResult
  $Res call({
    double lat,
    double lng,
    double? bearing,
    DateTime recordedAt,
    double? accuracy,
  });
}

/// @nodoc
class _$BusLocationCopyWithImpl<$Res, $Val extends BusLocation>
    implements $BusLocationCopyWith<$Res> {
  _$BusLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? bearing = freezed,
    Object? recordedAt = null,
    Object? accuracy = freezed,
  }) {
    return _then(
      _value.copyWith(
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            lng: null == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double,
            bearing: freezed == bearing
                ? _value.bearing
                : bearing // ignore: cast_nullable_to_non_nullable
                      as double?,
            recordedAt: null == recordedAt
                ? _value.recordedAt
                : recordedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            accuracy: freezed == accuracy
                ? _value.accuracy
                : accuracy // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusLocationImplCopyWith<$Res>
    implements $BusLocationCopyWith<$Res> {
  factory _$$BusLocationImplCopyWith(
    _$BusLocationImpl value,
    $Res Function(_$BusLocationImpl) then,
  ) = __$$BusLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double lat,
    double lng,
    double? bearing,
    DateTime recordedAt,
    double? accuracy,
  });
}

/// @nodoc
class __$$BusLocationImplCopyWithImpl<$Res>
    extends _$BusLocationCopyWithImpl<$Res, _$BusLocationImpl>
    implements _$$BusLocationImplCopyWith<$Res> {
  __$$BusLocationImplCopyWithImpl(
    _$BusLocationImpl _value,
    $Res Function(_$BusLocationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? bearing = freezed,
    Object? recordedAt = null,
    Object? accuracy = freezed,
  }) {
    return _then(
      _$BusLocationImpl(
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        lng: null == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double,
        bearing: freezed == bearing
            ? _value.bearing
            : bearing // ignore: cast_nullable_to_non_nullable
                  as double?,
        recordedAt: null == recordedAt
            ? _value.recordedAt
            : recordedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        accuracy: freezed == accuracy
            ? _value.accuracy
            : accuracy // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BusLocationImpl implements _BusLocation {
  const _$BusLocationImpl({
    required this.lat,
    required this.lng,
    this.bearing,
    required this.recordedAt,
    this.accuracy,
  });

  factory _$BusLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusLocationImplFromJson(json);

  @override
  final double lat;
  @override
  final double lng;
  @override
  final double? bearing;
  @override
  final DateTime recordedAt;
  @override
  final double? accuracy;

  @override
  String toString() {
    return 'BusLocation(lat: $lat, lng: $lng, bearing: $bearing, recordedAt: $recordedAt, accuracy: $accuracy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusLocationImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.bearing, bearing) || other.bearing == bearing) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, lat, lng, bearing, recordedAt, accuracy);

  /// Create a copy of BusLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusLocationImplCopyWith<_$BusLocationImpl> get copyWith =>
      __$$BusLocationImplCopyWithImpl<_$BusLocationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BusLocationImplToJson(this);
  }
}

abstract class _BusLocation implements BusLocation {
  const factory _BusLocation({
    required final double lat,
    required final double lng,
    final double? bearing,
    required final DateTime recordedAt,
    final double? accuracy,
  }) = _$BusLocationImpl;

  factory _BusLocation.fromJson(Map<String, dynamic> json) =
      _$BusLocationImpl.fromJson;

  @override
  double get lat;
  @override
  double get lng;
  @override
  double? get bearing;
  @override
  DateTime get recordedAt;
  @override
  double? get accuracy;

  /// Create a copy of BusLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusLocationImplCopyWith<_$BusLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
