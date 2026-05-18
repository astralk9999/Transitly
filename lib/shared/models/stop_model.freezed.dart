// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stop_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StopModel {

 String get id; String get name; String get officialCode; double get lat; double get lng; String get municipality; String? get zoneId; bool get hasShelter; bool get hasBench; bool get isAccessible; bool get hasDisplay; String? get photoUrl; String? get notes;
/// Create a copy of StopModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StopModelCopyWith<StopModel> get copyWith => _$StopModelCopyWithImpl<StopModel>(this as StopModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.officialCode, officialCode) || other.officialCode == officialCode)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.municipality, municipality) || other.municipality == municipality)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.hasShelter, hasShelter) || other.hasShelter == hasShelter)&&(identical(other.hasBench, hasBench) || other.hasBench == hasBench)&&(identical(other.isAccessible, isAccessible) || other.isAccessible == isAccessible)&&(identical(other.hasDisplay, hasDisplay) || other.hasDisplay == hasDisplay)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,officialCode,lat,lng,municipality,zoneId,hasShelter,hasBench,isAccessible,hasDisplay,photoUrl,notes);

@override
String toString() {
  return 'StopModel(id: $id, name: $name, officialCode: $officialCode, lat: $lat, lng: $lng, municipality: $municipality, zoneId: $zoneId, hasShelter: $hasShelter, hasBench: $hasBench, isAccessible: $isAccessible, hasDisplay: $hasDisplay, photoUrl: $photoUrl, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $StopModelCopyWith<$Res>  {
  factory $StopModelCopyWith(StopModel value, $Res Function(StopModel) _then) = _$StopModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String officialCode, double lat, double lng, String municipality, String? zoneId, bool hasShelter, bool hasBench, bool isAccessible, bool hasDisplay, String? photoUrl, String? notes
});




}
/// @nodoc
class _$StopModelCopyWithImpl<$Res>
    implements $StopModelCopyWith<$Res> {
  _$StopModelCopyWithImpl(this._self, this._then);

  final StopModel _self;
  final $Res Function(StopModel) _then;

/// Create a copy of StopModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? officialCode = null,Object? lat = null,Object? lng = null,Object? municipality = null,Object? zoneId = freezed,Object? hasShelter = null,Object? hasBench = null,Object? isAccessible = null,Object? hasDisplay = null,Object? photoUrl = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,officialCode: null == officialCode ? _self.officialCode : officialCode // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,municipality: null == municipality ? _self.municipality : municipality // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,hasShelter: null == hasShelter ? _self.hasShelter : hasShelter // ignore: cast_nullable_to_non_nullable
as bool,hasBench: null == hasBench ? _self.hasBench : hasBench // ignore: cast_nullable_to_non_nullable
as bool,isAccessible: null == isAccessible ? _self.isAccessible : isAccessible // ignore: cast_nullable_to_non_nullable
as bool,hasDisplay: null == hasDisplay ? _self.hasDisplay : hasDisplay // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StopModel].
extension StopModelPatterns on StopModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StopModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StopModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StopModel value)  $default,){
final _that = this;
switch (_that) {
case _StopModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StopModel value)?  $default,){
final _that = this;
switch (_that) {
case _StopModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String officialCode,  double lat,  double lng,  String municipality,  String? zoneId,  bool hasShelter,  bool hasBench,  bool isAccessible,  bool hasDisplay,  String? photoUrl,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StopModel() when $default != null:
return $default(_that.id,_that.name,_that.officialCode,_that.lat,_that.lng,_that.municipality,_that.zoneId,_that.hasShelter,_that.hasBench,_that.isAccessible,_that.hasDisplay,_that.photoUrl,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String officialCode,  double lat,  double lng,  String municipality,  String? zoneId,  bool hasShelter,  bool hasBench,  bool isAccessible,  bool hasDisplay,  String? photoUrl,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _StopModel():
return $default(_that.id,_that.name,_that.officialCode,_that.lat,_that.lng,_that.municipality,_that.zoneId,_that.hasShelter,_that.hasBench,_that.isAccessible,_that.hasDisplay,_that.photoUrl,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String officialCode,  double lat,  double lng,  String municipality,  String? zoneId,  bool hasShelter,  bool hasBench,  bool isAccessible,  bool hasDisplay,  String? photoUrl,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _StopModel() when $default != null:
return $default(_that.id,_that.name,_that.officialCode,_that.lat,_that.lng,_that.municipality,_that.zoneId,_that.hasShelter,_that.hasBench,_that.isAccessible,_that.hasDisplay,_that.photoUrl,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _StopModel extends StopModel {
  const _StopModel({required this.id, required this.name, required this.officialCode, required this.lat, required this.lng, required this.municipality, this.zoneId, this.hasShelter = false, this.hasBench = false, this.isAccessible = false, this.hasDisplay = false, this.photoUrl, this.notes}): super._();
  

@override final  String id;
@override final  String name;
@override final  String officialCode;
@override final  double lat;
@override final  double lng;
@override final  String municipality;
@override final  String? zoneId;
@override@JsonKey() final  bool hasShelter;
@override@JsonKey() final  bool hasBench;
@override@JsonKey() final  bool isAccessible;
@override@JsonKey() final  bool hasDisplay;
@override final  String? photoUrl;
@override final  String? notes;

/// Create a copy of StopModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StopModelCopyWith<_StopModel> get copyWith => __$StopModelCopyWithImpl<_StopModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StopModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.officialCode, officialCode) || other.officialCode == officialCode)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.municipality, municipality) || other.municipality == municipality)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.hasShelter, hasShelter) || other.hasShelter == hasShelter)&&(identical(other.hasBench, hasBench) || other.hasBench == hasBench)&&(identical(other.isAccessible, isAccessible) || other.isAccessible == isAccessible)&&(identical(other.hasDisplay, hasDisplay) || other.hasDisplay == hasDisplay)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,officialCode,lat,lng,municipality,zoneId,hasShelter,hasBench,isAccessible,hasDisplay,photoUrl,notes);

@override
String toString() {
  return 'StopModel(id: $id, name: $name, officialCode: $officialCode, lat: $lat, lng: $lng, municipality: $municipality, zoneId: $zoneId, hasShelter: $hasShelter, hasBench: $hasBench, isAccessible: $isAccessible, hasDisplay: $hasDisplay, photoUrl: $photoUrl, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$StopModelCopyWith<$Res> implements $StopModelCopyWith<$Res> {
  factory _$StopModelCopyWith(_StopModel value, $Res Function(_StopModel) _then) = __$StopModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String officialCode, double lat, double lng, String municipality, String? zoneId, bool hasShelter, bool hasBench, bool isAccessible, bool hasDisplay, String? photoUrl, String? notes
});




}
/// @nodoc
class __$StopModelCopyWithImpl<$Res>
    implements _$StopModelCopyWith<$Res> {
  __$StopModelCopyWithImpl(this._self, this._then);

  final _StopModel _self;
  final $Res Function(_StopModel) _then;

/// Create a copy of StopModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? officialCode = null,Object? lat = null,Object? lng = null,Object? municipality = null,Object? zoneId = freezed,Object? hasShelter = null,Object? hasBench = null,Object? isAccessible = null,Object? hasDisplay = null,Object? photoUrl = freezed,Object? notes = freezed,}) {
  return _then(_StopModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,officialCode: null == officialCode ? _self.officialCode : officialCode // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,municipality: null == municipality ? _self.municipality : municipality // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,hasShelter: null == hasShelter ? _self.hasShelter : hasShelter // ignore: cast_nullable_to_non_nullable
as bool,hasBench: null == hasBench ? _self.hasBench : hasBench // ignore: cast_nullable_to_non_nullable
as bool,isAccessible: null == isAccessible ? _self.isAccessible : isAccessible // ignore: cast_nullable_to_non_nullable
as bool,hasDisplay: null == hasDisplay ? _self.hasDisplay : hasDisplay // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
