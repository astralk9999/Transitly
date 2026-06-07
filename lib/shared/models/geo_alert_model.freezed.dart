// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geo_alert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeoAlertModel {

 String get id; String get title; String get body; GeoAlertSeverity get severity; double get centerLat; double get centerLng; int get radiusM; bool get active; String? get createdBy; DateTime? get createdAt; DateTime? get expiresAt; List<String> get affectedRouteIds;
/// Create a copy of GeoAlertModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoAlertModelCopyWith<GeoAlertModel> get copyWith => _$GeoAlertModelCopyWithImpl<GeoAlertModel>(this as GeoAlertModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.radiusM, radiusM) || other.radiusM == radiusM)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other.affectedRouteIds, affectedRouteIds));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,severity,centerLat,centerLng,radiusM,active,createdBy,createdAt,expiresAt,const DeepCollectionEquality().hash(affectedRouteIds));

@override
String toString() {
  return 'GeoAlertModel(id: $id, title: $title, body: $body, severity: $severity, centerLat: $centerLat, centerLng: $centerLng, radiusM: $radiusM, active: $active, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, affectedRouteIds: $affectedRouteIds)';
}


}

/// @nodoc
abstract mixin class $GeoAlertModelCopyWith<$Res>  {
  factory $GeoAlertModelCopyWith(GeoAlertModel value, $Res Function(GeoAlertModel) _then) = _$GeoAlertModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String body, GeoAlertSeverity severity, double centerLat, double centerLng, int radiusM, bool active, String? createdBy, DateTime? createdAt, DateTime? expiresAt, List<String> affectedRouteIds
});




}
/// @nodoc
class _$GeoAlertModelCopyWithImpl<$Res>
    implements $GeoAlertModelCopyWith<$Res> {
  _$GeoAlertModelCopyWithImpl(this._self, this._then);

  final GeoAlertModel _self;
  final $Res Function(GeoAlertModel) _then;

/// Create a copy of GeoAlertModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? body = null,Object? severity = null,Object? centerLat = null,Object? centerLng = null,Object? radiusM = null,Object? active = null,Object? createdBy = freezed,Object? createdAt = freezed,Object? expiresAt = freezed,Object? affectedRouteIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as GeoAlertSeverity,centerLat: null == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double,centerLng: null == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double,radiusM: null == radiusM ? _self.radiusM : radiusM // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,affectedRouteIds: null == affectedRouteIds ? _self.affectedRouteIds : affectedRouteIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoAlertModel].
extension GeoAlertModelPatterns on GeoAlertModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoAlertModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoAlertModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoAlertModel value)  $default,){
final _that = this;
switch (_that) {
case _GeoAlertModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoAlertModel value)?  $default,){
final _that = this;
switch (_that) {
case _GeoAlertModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String body,  GeoAlertSeverity severity,  double centerLat,  double centerLng,  int radiusM,  bool active,  String? createdBy,  DateTime? createdAt,  DateTime? expiresAt,  List<String> affectedRouteIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoAlertModel() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.severity,_that.centerLat,_that.centerLng,_that.radiusM,_that.active,_that.createdBy,_that.createdAt,_that.expiresAt,_that.affectedRouteIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String body,  GeoAlertSeverity severity,  double centerLat,  double centerLng,  int radiusM,  bool active,  String? createdBy,  DateTime? createdAt,  DateTime? expiresAt,  List<String> affectedRouteIds)  $default,) {final _that = this;
switch (_that) {
case _GeoAlertModel():
return $default(_that.id,_that.title,_that.body,_that.severity,_that.centerLat,_that.centerLng,_that.radiusM,_that.active,_that.createdBy,_that.createdAt,_that.expiresAt,_that.affectedRouteIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String body,  GeoAlertSeverity severity,  double centerLat,  double centerLng,  int radiusM,  bool active,  String? createdBy,  DateTime? createdAt,  DateTime? expiresAt,  List<String> affectedRouteIds)?  $default,) {final _that = this;
switch (_that) {
case _GeoAlertModel() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.severity,_that.centerLat,_that.centerLng,_that.radiusM,_that.active,_that.createdBy,_that.createdAt,_that.expiresAt,_that.affectedRouteIds);case _:
  return null;

}
}

}

/// @nodoc


class _GeoAlertModel extends GeoAlertModel {
  const _GeoAlertModel({required this.id, required this.title, required this.body, this.severity = GeoAlertSeverity.info, required this.centerLat, required this.centerLng, required this.radiusM, this.active = true, this.createdBy, this.createdAt, this.expiresAt, final  List<String> affectedRouteIds = const <String>[]}): _affectedRouteIds = affectedRouteIds,super._();
  

@override final  String id;
@override final  String title;
@override final  String body;
@override@JsonKey() final  GeoAlertSeverity severity;
@override final  double centerLat;
@override final  double centerLng;
@override final  int radiusM;
@override@JsonKey() final  bool active;
@override final  String? createdBy;
@override final  DateTime? createdAt;
@override final  DateTime? expiresAt;
 final  List<String> _affectedRouteIds;
@override@JsonKey() List<String> get affectedRouteIds {
  if (_affectedRouteIds is EqualUnmodifiableListView) return _affectedRouteIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_affectedRouteIds);
}


/// Create a copy of GeoAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoAlertModelCopyWith<_GeoAlertModel> get copyWith => __$GeoAlertModelCopyWithImpl<_GeoAlertModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.radiusM, radiusM) || other.radiusM == radiusM)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other._affectedRouteIds, _affectedRouteIds));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,severity,centerLat,centerLng,radiusM,active,createdBy,createdAt,expiresAt,const DeepCollectionEquality().hash(_affectedRouteIds));

@override
String toString() {
  return 'GeoAlertModel(id: $id, title: $title, body: $body, severity: $severity, centerLat: $centerLat, centerLng: $centerLng, radiusM: $radiusM, active: $active, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, affectedRouteIds: $affectedRouteIds)';
}


}

/// @nodoc
abstract mixin class _$GeoAlertModelCopyWith<$Res> implements $GeoAlertModelCopyWith<$Res> {
  factory _$GeoAlertModelCopyWith(_GeoAlertModel value, $Res Function(_GeoAlertModel) _then) = __$GeoAlertModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String body, GeoAlertSeverity severity, double centerLat, double centerLng, int radiusM, bool active, String? createdBy, DateTime? createdAt, DateTime? expiresAt, List<String> affectedRouteIds
});




}
/// @nodoc
class __$GeoAlertModelCopyWithImpl<$Res>
    implements _$GeoAlertModelCopyWith<$Res> {
  __$GeoAlertModelCopyWithImpl(this._self, this._then);

  final _GeoAlertModel _self;
  final $Res Function(_GeoAlertModel) _then;

/// Create a copy of GeoAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? body = null,Object? severity = null,Object? centerLat = null,Object? centerLng = null,Object? radiusM = null,Object? active = null,Object? createdBy = freezed,Object? createdAt = freezed,Object? expiresAt = freezed,Object? affectedRouteIds = null,}) {
  return _then(_GeoAlertModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as GeoAlertSeverity,centerLat: null == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double,centerLng: null == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double,radiusM: null == radiusM ? _self.radiusM : radiusM // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,affectedRouteIds: null == affectedRouteIds ? _self._affectedRouteIds : affectedRouteIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
