// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_favorite_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserFavoriteModel {

 String get id; String get userId; String get routeId; String? get homeStopId; int? get alarmMinutesBefore;
/// Create a copy of UserFavoriteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserFavoriteModelCopyWith<UserFavoriteModel> get copyWith => _$UserFavoriteModelCopyWithImpl<UserFavoriteModel>(this as UserFavoriteModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserFavoriteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.homeStopId, homeStopId) || other.homeStopId == homeStopId)&&(identical(other.alarmMinutesBefore, alarmMinutesBefore) || other.alarmMinutesBefore == alarmMinutesBefore));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,homeStopId,alarmMinutesBefore);

@override
String toString() {
  return 'UserFavoriteModel(id: $id, userId: $userId, routeId: $routeId, homeStopId: $homeStopId, alarmMinutesBefore: $alarmMinutesBefore)';
}


}

/// @nodoc
abstract mixin class $UserFavoriteModelCopyWith<$Res>  {
  factory $UserFavoriteModelCopyWith(UserFavoriteModel value, $Res Function(UserFavoriteModel) _then) = _$UserFavoriteModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String routeId, String? homeStopId, int? alarmMinutesBefore
});




}
/// @nodoc
class _$UserFavoriteModelCopyWithImpl<$Res>
    implements $UserFavoriteModelCopyWith<$Res> {
  _$UserFavoriteModelCopyWithImpl(this._self, this._then);

  final UserFavoriteModel _self;
  final $Res Function(UserFavoriteModel) _then;

/// Create a copy of UserFavoriteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? homeStopId = freezed,Object? alarmMinutesBefore = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,homeStopId: freezed == homeStopId ? _self.homeStopId : homeStopId // ignore: cast_nullable_to_non_nullable
as String?,alarmMinutesBefore: freezed == alarmMinutesBefore ? _self.alarmMinutesBefore : alarmMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserFavoriteModel].
extension UserFavoriteModelPatterns on UserFavoriteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserFavoriteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserFavoriteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserFavoriteModel value)  $default,){
final _that = this;
switch (_that) {
case _UserFavoriteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserFavoriteModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserFavoriteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? homeStopId,  int? alarmMinutesBefore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserFavoriteModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.homeStopId,_that.alarmMinutesBefore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? homeStopId,  int? alarmMinutesBefore)  $default,) {final _that = this;
switch (_that) {
case _UserFavoriteModel():
return $default(_that.id,_that.userId,_that.routeId,_that.homeStopId,_that.alarmMinutesBefore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String routeId,  String? homeStopId,  int? alarmMinutesBefore)?  $default,) {final _that = this;
switch (_that) {
case _UserFavoriteModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.homeStopId,_that.alarmMinutesBefore);case _:
  return null;

}
}

}

/// @nodoc


class _UserFavoriteModel extends UserFavoriteModel {
  const _UserFavoriteModel({required this.id, required this.userId, required this.routeId, this.homeStopId, this.alarmMinutesBefore}): super._();
  

@override final  String id;
@override final  String userId;
@override final  String routeId;
@override final  String? homeStopId;
@override final  int? alarmMinutesBefore;

/// Create a copy of UserFavoriteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserFavoriteModelCopyWith<_UserFavoriteModel> get copyWith => __$UserFavoriteModelCopyWithImpl<_UserFavoriteModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserFavoriteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.homeStopId, homeStopId) || other.homeStopId == homeStopId)&&(identical(other.alarmMinutesBefore, alarmMinutesBefore) || other.alarmMinutesBefore == alarmMinutesBefore));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,homeStopId,alarmMinutesBefore);

@override
String toString() {
  return 'UserFavoriteModel(id: $id, userId: $userId, routeId: $routeId, homeStopId: $homeStopId, alarmMinutesBefore: $alarmMinutesBefore)';
}


}

/// @nodoc
abstract mixin class _$UserFavoriteModelCopyWith<$Res> implements $UserFavoriteModelCopyWith<$Res> {
  factory _$UserFavoriteModelCopyWith(_UserFavoriteModel value, $Res Function(_UserFavoriteModel) _then) = __$UserFavoriteModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String routeId, String? homeStopId, int? alarmMinutesBefore
});




}
/// @nodoc
class __$UserFavoriteModelCopyWithImpl<$Res>
    implements _$UserFavoriteModelCopyWith<$Res> {
  __$UserFavoriteModelCopyWithImpl(this._self, this._then);

  final _UserFavoriteModel _self;
  final $Res Function(_UserFavoriteModel) _then;

/// Create a copy of UserFavoriteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? homeStopId = freezed,Object? alarmMinutesBefore = freezed,}) {
  return _then(_UserFavoriteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,homeStopId: freezed == homeStopId ? _self.homeStopId : homeStopId // ignore: cast_nullable_to_non_nullable
as String?,alarmMinutesBefore: freezed == alarmMinutesBefore ? _self.alarmMinutesBefore : alarmMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
