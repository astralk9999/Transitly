// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bus_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusLocation {

 double get lat; double get lng; double? get bearing; DateTime get recordedAt; double? get accuracy;
/// Create a copy of BusLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusLocationCopyWith<BusLocation> get copyWith => _$BusLocationCopyWithImpl<BusLocation>(this as BusLocation, _$identity);

  /// Serializes this BusLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.bearing, bearing) || other.bearing == bearing)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,bearing,recordedAt,accuracy);

@override
String toString() {
  return 'BusLocation(lat: $lat, lng: $lng, bearing: $bearing, recordedAt: $recordedAt, accuracy: $accuracy)';
}


}

/// @nodoc
abstract mixin class $BusLocationCopyWith<$Res>  {
  factory $BusLocationCopyWith(BusLocation value, $Res Function(BusLocation) _then) = _$BusLocationCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double? bearing, DateTime recordedAt, double? accuracy
});




}
/// @nodoc
class _$BusLocationCopyWithImpl<$Res>
    implements $BusLocationCopyWith<$Res> {
  _$BusLocationCopyWithImpl(this._self, this._then);

  final BusLocation _self;
  final $Res Function(BusLocation) _then;

/// Create a copy of BusLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? bearing = freezed,Object? recordedAt = null,Object? accuracy = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,bearing: freezed == bearing ? _self.bearing : bearing // ignore: cast_nullable_to_non_nullable
as double?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,accuracy: freezed == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BusLocation].
extension BusLocationPatterns on BusLocation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusLocation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusLocation value)  $default,){
final _that = this;
switch (_that) {
case _BusLocation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusLocation value)?  $default,){
final _that = this;
switch (_that) {
case _BusLocation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double? bearing,  DateTime recordedAt,  double? accuracy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.bearing,_that.recordedAt,_that.accuracy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double? bearing,  DateTime recordedAt,  double? accuracy)  $default,) {final _that = this;
switch (_that) {
case _BusLocation():
return $default(_that.lat,_that.lng,_that.bearing,_that.recordedAt,_that.accuracy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double? bearing,  DateTime recordedAt,  double? accuracy)?  $default,) {final _that = this;
switch (_that) {
case _BusLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.bearing,_that.recordedAt,_that.accuracy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusLocation implements BusLocation {
  const _BusLocation({required this.lat, required this.lng, this.bearing, required this.recordedAt, this.accuracy});
  factory _BusLocation.fromJson(Map<String, dynamic> json) => _$BusLocationFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  double? bearing;
@override final  DateTime recordedAt;
@override final  double? accuracy;

/// Create a copy of BusLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusLocationCopyWith<_BusLocation> get copyWith => __$BusLocationCopyWithImpl<_BusLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.bearing, bearing) || other.bearing == bearing)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,bearing,recordedAt,accuracy);

@override
String toString() {
  return 'BusLocation(lat: $lat, lng: $lng, bearing: $bearing, recordedAt: $recordedAt, accuracy: $accuracy)';
}


}

/// @nodoc
abstract mixin class _$BusLocationCopyWith<$Res> implements $BusLocationCopyWith<$Res> {
  factory _$BusLocationCopyWith(_BusLocation value, $Res Function(_BusLocation) _then) = __$BusLocationCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double? bearing, DateTime recordedAt, double? accuracy
});




}
/// @nodoc
class __$BusLocationCopyWithImpl<$Res>
    implements _$BusLocationCopyWith<$Res> {
  __$BusLocationCopyWithImpl(this._self, this._then);

  final _BusLocation _self;
  final $Res Function(_BusLocation) _then;

/// Create a copy of BusLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? bearing = freezed,Object? recordedAt = null,Object? accuracy = freezed,}) {
  return _then(_BusLocation(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,bearing: freezed == bearing ? _self.bearing : bearing // ignore: cast_nullable_to_non_nullable
as double?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,accuracy: freezed == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
