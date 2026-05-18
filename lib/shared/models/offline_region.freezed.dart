// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OfflineRegionBounds {

 double get northLat; double get southLat; double get eastLng; double get westLng;
/// Create a copy of OfflineRegionBounds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineRegionBoundsCopyWith<OfflineRegionBounds> get copyWith => _$OfflineRegionBoundsCopyWithImpl<OfflineRegionBounds>(this as OfflineRegionBounds, _$identity);

  /// Serializes this OfflineRegionBounds to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineRegionBounds&&(identical(other.northLat, northLat) || other.northLat == northLat)&&(identical(other.southLat, southLat) || other.southLat == southLat)&&(identical(other.eastLng, eastLng) || other.eastLng == eastLng)&&(identical(other.westLng, westLng) || other.westLng == westLng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northLat,southLat,eastLng,westLng);

@override
String toString() {
  return 'OfflineRegionBounds(northLat: $northLat, southLat: $southLat, eastLng: $eastLng, westLng: $westLng)';
}


}

/// @nodoc
abstract mixin class $OfflineRegionBoundsCopyWith<$Res>  {
  factory $OfflineRegionBoundsCopyWith(OfflineRegionBounds value, $Res Function(OfflineRegionBounds) _then) = _$OfflineRegionBoundsCopyWithImpl;
@useResult
$Res call({
 double northLat, double southLat, double eastLng, double westLng
});




}
/// @nodoc
class _$OfflineRegionBoundsCopyWithImpl<$Res>
    implements $OfflineRegionBoundsCopyWith<$Res> {
  _$OfflineRegionBoundsCopyWithImpl(this._self, this._then);

  final OfflineRegionBounds _self;
  final $Res Function(OfflineRegionBounds) _then;

/// Create a copy of OfflineRegionBounds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? northLat = null,Object? southLat = null,Object? eastLng = null,Object? westLng = null,}) {
  return _then(_self.copyWith(
northLat: null == northLat ? _self.northLat : northLat // ignore: cast_nullable_to_non_nullable
as double,southLat: null == southLat ? _self.southLat : southLat // ignore: cast_nullable_to_non_nullable
as double,eastLng: null == eastLng ? _self.eastLng : eastLng // ignore: cast_nullable_to_non_nullable
as double,westLng: null == westLng ? _self.westLng : westLng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineRegionBounds].
extension OfflineRegionBoundsPatterns on OfflineRegionBounds {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineRegionBounds value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineRegionBounds() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineRegionBounds value)  $default,){
final _that = this;
switch (_that) {
case _OfflineRegionBounds():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineRegionBounds value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineRegionBounds() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double northLat,  double southLat,  double eastLng,  double westLng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineRegionBounds() when $default != null:
return $default(_that.northLat,_that.southLat,_that.eastLng,_that.westLng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double northLat,  double southLat,  double eastLng,  double westLng)  $default,) {final _that = this;
switch (_that) {
case _OfflineRegionBounds():
return $default(_that.northLat,_that.southLat,_that.eastLng,_that.westLng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double northLat,  double southLat,  double eastLng,  double westLng)?  $default,) {final _that = this;
switch (_that) {
case _OfflineRegionBounds() when $default != null:
return $default(_that.northLat,_that.southLat,_that.eastLng,_that.westLng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OfflineRegionBounds implements OfflineRegionBounds {
  const _OfflineRegionBounds({required this.northLat, required this.southLat, required this.eastLng, required this.westLng});
  factory _OfflineRegionBounds.fromJson(Map<String, dynamic> json) => _$OfflineRegionBoundsFromJson(json);

@override final  double northLat;
@override final  double southLat;
@override final  double eastLng;
@override final  double westLng;

/// Create a copy of OfflineRegionBounds
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineRegionBoundsCopyWith<_OfflineRegionBounds> get copyWith => __$OfflineRegionBoundsCopyWithImpl<_OfflineRegionBounds>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfflineRegionBoundsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineRegionBounds&&(identical(other.northLat, northLat) || other.northLat == northLat)&&(identical(other.southLat, southLat) || other.southLat == southLat)&&(identical(other.eastLng, eastLng) || other.eastLng == eastLng)&&(identical(other.westLng, westLng) || other.westLng == westLng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northLat,southLat,eastLng,westLng);

@override
String toString() {
  return 'OfflineRegionBounds(northLat: $northLat, southLat: $southLat, eastLng: $eastLng, westLng: $westLng)';
}


}

/// @nodoc
abstract mixin class _$OfflineRegionBoundsCopyWith<$Res> implements $OfflineRegionBoundsCopyWith<$Res> {
  factory _$OfflineRegionBoundsCopyWith(_OfflineRegionBounds value, $Res Function(_OfflineRegionBounds) _then) = __$OfflineRegionBoundsCopyWithImpl;
@override @useResult
$Res call({
 double northLat, double southLat, double eastLng, double westLng
});




}
/// @nodoc
class __$OfflineRegionBoundsCopyWithImpl<$Res>
    implements _$OfflineRegionBoundsCopyWith<$Res> {
  __$OfflineRegionBoundsCopyWithImpl(this._self, this._then);

  final _OfflineRegionBounds _self;
  final $Res Function(_OfflineRegionBounds) _then;

/// Create a copy of OfflineRegionBounds
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? northLat = null,Object? southLat = null,Object? eastLng = null,Object? westLng = null,}) {
  return _then(_OfflineRegionBounds(
northLat: null == northLat ? _self.northLat : northLat // ignore: cast_nullable_to_non_nullable
as double,southLat: null == southLat ? _self.southLat : southLat // ignore: cast_nullable_to_non_nullable
as double,eastLng: null == eastLng ? _self.eastLng : eastLng // ignore: cast_nullable_to_non_nullable
as double,westLng: null == westLng ? _self.westLng : westLng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$OfflineRegion {

 String get id; String get label; OfflineRegionBounds get bounds; int get zoomMin; int get zoomMax; DateTime get downloadedAt; int get sizeBytes; OfflineRegionStatus get status; DateTime? get dataSyncedAt;
/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineRegionCopyWith<OfflineRegion> get copyWith => _$OfflineRegionCopyWithImpl<OfflineRegion>(this as OfflineRegion, _$identity);

  /// Serializes this OfflineRegion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.zoomMin, zoomMin) || other.zoomMin == zoomMin)&&(identical(other.zoomMax, zoomMax) || other.zoomMax == zoomMax)&&(identical(other.downloadedAt, downloadedAt) || other.downloadedAt == downloadedAt)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.dataSyncedAt, dataSyncedAt) || other.dataSyncedAt == dataSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,bounds,zoomMin,zoomMax,downloadedAt,sizeBytes,status,dataSyncedAt);

@override
String toString() {
  return 'OfflineRegion(id: $id, label: $label, bounds: $bounds, zoomMin: $zoomMin, zoomMax: $zoomMax, downloadedAt: $downloadedAt, sizeBytes: $sizeBytes, status: $status, dataSyncedAt: $dataSyncedAt)';
}


}

/// @nodoc
abstract mixin class $OfflineRegionCopyWith<$Res>  {
  factory $OfflineRegionCopyWith(OfflineRegion value, $Res Function(OfflineRegion) _then) = _$OfflineRegionCopyWithImpl;
@useResult
$Res call({
 String id, String label, OfflineRegionBounds bounds, int zoomMin, int zoomMax, DateTime downloadedAt, int sizeBytes, OfflineRegionStatus status, DateTime? dataSyncedAt
});


$OfflineRegionBoundsCopyWith<$Res> get bounds;

}
/// @nodoc
class _$OfflineRegionCopyWithImpl<$Res>
    implements $OfflineRegionCopyWith<$Res> {
  _$OfflineRegionCopyWithImpl(this._self, this._then);

  final OfflineRegion _self;
  final $Res Function(OfflineRegion) _then;

/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? bounds = null,Object? zoomMin = null,Object? zoomMax = null,Object? downloadedAt = null,Object? sizeBytes = null,Object? status = null,Object? dataSyncedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as OfflineRegionBounds,zoomMin: null == zoomMin ? _self.zoomMin : zoomMin // ignore: cast_nullable_to_non_nullable
as int,zoomMax: null == zoomMax ? _self.zoomMax : zoomMax // ignore: cast_nullable_to_non_nullable
as int,downloadedAt: null == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfflineRegionStatus,dataSyncedAt: freezed == dataSyncedAt ? _self.dataSyncedAt : dataSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfflineRegionBoundsCopyWith<$Res> get bounds {
  
  return $OfflineRegionBoundsCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}


/// Adds pattern-matching-related methods to [OfflineRegion].
extension OfflineRegionPatterns on OfflineRegion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineRegion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineRegion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineRegion value)  $default,){
final _that = this;
switch (_that) {
case _OfflineRegion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineRegion value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineRegion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  OfflineRegionBounds bounds,  int zoomMin,  int zoomMax,  DateTime downloadedAt,  int sizeBytes,  OfflineRegionStatus status,  DateTime? dataSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineRegion() when $default != null:
return $default(_that.id,_that.label,_that.bounds,_that.zoomMin,_that.zoomMax,_that.downloadedAt,_that.sizeBytes,_that.status,_that.dataSyncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  OfflineRegionBounds bounds,  int zoomMin,  int zoomMax,  DateTime downloadedAt,  int sizeBytes,  OfflineRegionStatus status,  DateTime? dataSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _OfflineRegion():
return $default(_that.id,_that.label,_that.bounds,_that.zoomMin,_that.zoomMax,_that.downloadedAt,_that.sizeBytes,_that.status,_that.dataSyncedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  OfflineRegionBounds bounds,  int zoomMin,  int zoomMax,  DateTime downloadedAt,  int sizeBytes,  OfflineRegionStatus status,  DateTime? dataSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _OfflineRegion() when $default != null:
return $default(_that.id,_that.label,_that.bounds,_that.zoomMin,_that.zoomMax,_that.downloadedAt,_that.sizeBytes,_that.status,_that.dataSyncedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OfflineRegion implements OfflineRegion {
  const _OfflineRegion({required this.id, required this.label, required this.bounds, required this.zoomMin, required this.zoomMax, required this.downloadedAt, required this.sizeBytes, required this.status, this.dataSyncedAt});
  factory _OfflineRegion.fromJson(Map<String, dynamic> json) => _$OfflineRegionFromJson(json);

@override final  String id;
@override final  String label;
@override final  OfflineRegionBounds bounds;
@override final  int zoomMin;
@override final  int zoomMax;
@override final  DateTime downloadedAt;
@override final  int sizeBytes;
@override final  OfflineRegionStatus status;
@override final  DateTime? dataSyncedAt;

/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineRegionCopyWith<_OfflineRegion> get copyWith => __$OfflineRegionCopyWithImpl<_OfflineRegion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfflineRegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.zoomMin, zoomMin) || other.zoomMin == zoomMin)&&(identical(other.zoomMax, zoomMax) || other.zoomMax == zoomMax)&&(identical(other.downloadedAt, downloadedAt) || other.downloadedAt == downloadedAt)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.dataSyncedAt, dataSyncedAt) || other.dataSyncedAt == dataSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,bounds,zoomMin,zoomMax,downloadedAt,sizeBytes,status,dataSyncedAt);

@override
String toString() {
  return 'OfflineRegion(id: $id, label: $label, bounds: $bounds, zoomMin: $zoomMin, zoomMax: $zoomMax, downloadedAt: $downloadedAt, sizeBytes: $sizeBytes, status: $status, dataSyncedAt: $dataSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$OfflineRegionCopyWith<$Res> implements $OfflineRegionCopyWith<$Res> {
  factory _$OfflineRegionCopyWith(_OfflineRegion value, $Res Function(_OfflineRegion) _then) = __$OfflineRegionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, OfflineRegionBounds bounds, int zoomMin, int zoomMax, DateTime downloadedAt, int sizeBytes, OfflineRegionStatus status, DateTime? dataSyncedAt
});


@override $OfflineRegionBoundsCopyWith<$Res> get bounds;

}
/// @nodoc
class __$OfflineRegionCopyWithImpl<$Res>
    implements _$OfflineRegionCopyWith<$Res> {
  __$OfflineRegionCopyWithImpl(this._self, this._then);

  final _OfflineRegion _self;
  final $Res Function(_OfflineRegion) _then;

/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? bounds = null,Object? zoomMin = null,Object? zoomMax = null,Object? downloadedAt = null,Object? sizeBytes = null,Object? status = null,Object? dataSyncedAt = freezed,}) {
  return _then(_OfflineRegion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as OfflineRegionBounds,zoomMin: null == zoomMin ? _self.zoomMin : zoomMin // ignore: cast_nullable_to_non_nullable
as int,zoomMax: null == zoomMax ? _self.zoomMax : zoomMax // ignore: cast_nullable_to_non_nullable
as int,downloadedAt: null == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfflineRegionStatus,dataSyncedAt: freezed == dataSyncedAt ? _self.dataSyncedAt : dataSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OfflineRegion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfflineRegionBoundsCopyWith<$Res> get bounds {
  
  return $OfflineRegionBoundsCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}

// dart format on
