// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteShare {

 String get routeId; String get sharedWithId; String get sharedById; RouteSharePermission get permission; DateTime get createdAt; DateTime? get expiresAt;
/// Create a copy of RouteShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteShareCopyWith<RouteShare> get copyWith => _$RouteShareCopyWithImpl<RouteShare>(this as RouteShare, _$identity);

  /// Serializes this RouteShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteShare&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.sharedWithId, sharedWithId) || other.sharedWithId == sharedWithId)&&(identical(other.sharedById, sharedById) || other.sharedById == sharedById)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,routeId,sharedWithId,sharedById,permission,createdAt,expiresAt);

@override
String toString() {
  return 'RouteShare(routeId: $routeId, sharedWithId: $sharedWithId, sharedById: $sharedById, permission: $permission, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $RouteShareCopyWith<$Res>  {
  factory $RouteShareCopyWith(RouteShare value, $Res Function(RouteShare) _then) = _$RouteShareCopyWithImpl;
@useResult
$Res call({
 String routeId, String sharedWithId, String sharedById, RouteSharePermission permission, DateTime createdAt, DateTime? expiresAt
});




}
/// @nodoc
class _$RouteShareCopyWithImpl<$Res>
    implements $RouteShareCopyWith<$Res> {
  _$RouteShareCopyWithImpl(this._self, this._then);

  final RouteShare _self;
  final $Res Function(RouteShare) _then;

/// Create a copy of RouteShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? routeId = null,Object? sharedWithId = null,Object? sharedById = null,Object? permission = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,sharedWithId: null == sharedWithId ? _self.sharedWithId : sharedWithId // ignore: cast_nullable_to_non_nullable
as String,sharedById: null == sharedById ? _self.sharedById : sharedById // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as RouteSharePermission,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteShare].
extension RouteSharePatterns on RouteShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteShare value)  $default,){
final _that = this;
switch (_that) {
case _RouteShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteShare value)?  $default,){
final _that = this;
switch (_that) {
case _RouteShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String routeId,  String sharedWithId,  String sharedById,  RouteSharePermission permission,  DateTime createdAt,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteShare() when $default != null:
return $default(_that.routeId,_that.sharedWithId,_that.sharedById,_that.permission,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String routeId,  String sharedWithId,  String sharedById,  RouteSharePermission permission,  DateTime createdAt,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _RouteShare():
return $default(_that.routeId,_that.sharedWithId,_that.sharedById,_that.permission,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String routeId,  String sharedWithId,  String sharedById,  RouteSharePermission permission,  DateTime createdAt,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteShare() when $default != null:
return $default(_that.routeId,_that.sharedWithId,_that.sharedById,_that.permission,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteShare implements RouteShare {
  const _RouteShare({required this.routeId, required this.sharedWithId, required this.sharedById, this.permission = RouteSharePermission.view, required this.createdAt, this.expiresAt});
  factory _RouteShare.fromJson(Map<String, dynamic> json) => _$RouteShareFromJson(json);

@override final  String routeId;
@override final  String sharedWithId;
@override final  String sharedById;
@override@JsonKey() final  RouteSharePermission permission;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;

/// Create a copy of RouteShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteShareCopyWith<_RouteShare> get copyWith => __$RouteShareCopyWithImpl<_RouteShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteShare&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.sharedWithId, sharedWithId) || other.sharedWithId == sharedWithId)&&(identical(other.sharedById, sharedById) || other.sharedById == sharedById)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,routeId,sharedWithId,sharedById,permission,createdAt,expiresAt);

@override
String toString() {
  return 'RouteShare(routeId: $routeId, sharedWithId: $sharedWithId, sharedById: $sharedById, permission: $permission, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$RouteShareCopyWith<$Res> implements $RouteShareCopyWith<$Res> {
  factory _$RouteShareCopyWith(_RouteShare value, $Res Function(_RouteShare) _then) = __$RouteShareCopyWithImpl;
@override @useResult
$Res call({
 String routeId, String sharedWithId, String sharedById, RouteSharePermission permission, DateTime createdAt, DateTime? expiresAt
});




}
/// @nodoc
class __$RouteShareCopyWithImpl<$Res>
    implements _$RouteShareCopyWith<$Res> {
  __$RouteShareCopyWithImpl(this._self, this._then);

  final _RouteShare _self;
  final $Res Function(_RouteShare) _then;

/// Create a copy of RouteShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routeId = null,Object? sharedWithId = null,Object? sharedById = null,Object? permission = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_RouteShare(
routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,sharedWithId: null == sharedWithId ? _self.sharedWithId : sharedWithId // ignore: cast_nullable_to_non_nullable
as String,sharedById: null == sharedById ? _self.sharedById : sharedById // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as RouteSharePermission,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
