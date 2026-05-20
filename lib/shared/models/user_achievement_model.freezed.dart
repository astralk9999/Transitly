// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_achievement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserAchievementModel {

 String get achievementId; int get progress; bool get unlocked; DateTime? get unlockedAt;
/// Create a copy of UserAchievementModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserAchievementModelCopyWith<UserAchievementModel> get copyWith => _$UserAchievementModelCopyWithImpl<UserAchievementModel>(this as UserAchievementModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserAchievementModel&&(identical(other.achievementId, achievementId) || other.achievementId == achievementId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.unlockedAt, unlockedAt) || other.unlockedAt == unlockedAt));
}


@override
int get hashCode => Object.hash(runtimeType,achievementId,progress,unlocked,unlockedAt);

@override
String toString() {
  return 'UserAchievementModel(achievementId: $achievementId, progress: $progress, unlocked: $unlocked, unlockedAt: $unlockedAt)';
}


}

/// @nodoc
abstract mixin class $UserAchievementModelCopyWith<$Res>  {
  factory $UserAchievementModelCopyWith(UserAchievementModel value, $Res Function(UserAchievementModel) _then) = _$UserAchievementModelCopyWithImpl;
@useResult
$Res call({
 String achievementId, int progress, bool unlocked, DateTime? unlockedAt
});




}
/// @nodoc
class _$UserAchievementModelCopyWithImpl<$Res>
    implements $UserAchievementModelCopyWith<$Res> {
  _$UserAchievementModelCopyWithImpl(this._self, this._then);

  final UserAchievementModel _self;
  final $Res Function(UserAchievementModel) _then;

/// Create a copy of UserAchievementModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? achievementId = null,Object? progress = null,Object? unlocked = null,Object? unlockedAt = freezed,}) {
  return _then(_self.copyWith(
achievementId: null == achievementId ? _self.achievementId : achievementId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,unlockedAt: freezed == unlockedAt ? _self.unlockedAt : unlockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserAchievementModel].
extension UserAchievementModelPatterns on UserAchievementModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserAchievementModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserAchievementModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserAchievementModel value)  $default,){
final _that = this;
switch (_that) {
case _UserAchievementModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserAchievementModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserAchievementModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String achievementId,  int progress,  bool unlocked,  DateTime? unlockedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserAchievementModel() when $default != null:
return $default(_that.achievementId,_that.progress,_that.unlocked,_that.unlockedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String achievementId,  int progress,  bool unlocked,  DateTime? unlockedAt)  $default,) {final _that = this;
switch (_that) {
case _UserAchievementModel():
return $default(_that.achievementId,_that.progress,_that.unlocked,_that.unlockedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String achievementId,  int progress,  bool unlocked,  DateTime? unlockedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserAchievementModel() when $default != null:
return $default(_that.achievementId,_that.progress,_that.unlocked,_that.unlockedAt);case _:
  return null;

}
}

}

/// @nodoc


class _UserAchievementModel extends UserAchievementModel {
  const _UserAchievementModel({required this.achievementId, required this.progress, required this.unlocked, this.unlockedAt}): super._();
  

@override final  String achievementId;
@override final  int progress;
@override final  bool unlocked;
@override final  DateTime? unlockedAt;

/// Create a copy of UserAchievementModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserAchievementModelCopyWith<_UserAchievementModel> get copyWith => __$UserAchievementModelCopyWithImpl<_UserAchievementModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserAchievementModel&&(identical(other.achievementId, achievementId) || other.achievementId == achievementId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.unlockedAt, unlockedAt) || other.unlockedAt == unlockedAt));
}


@override
int get hashCode => Object.hash(runtimeType,achievementId,progress,unlocked,unlockedAt);

@override
String toString() {
  return 'UserAchievementModel(achievementId: $achievementId, progress: $progress, unlocked: $unlocked, unlockedAt: $unlockedAt)';
}


}

/// @nodoc
abstract mixin class _$UserAchievementModelCopyWith<$Res> implements $UserAchievementModelCopyWith<$Res> {
  factory _$UserAchievementModelCopyWith(_UserAchievementModel value, $Res Function(_UserAchievementModel) _then) = __$UserAchievementModelCopyWithImpl;
@override @useResult
$Res call({
 String achievementId, int progress, bool unlocked, DateTime? unlockedAt
});




}
/// @nodoc
class __$UserAchievementModelCopyWithImpl<$Res>
    implements _$UserAchievementModelCopyWith<$Res> {
  __$UserAchievementModelCopyWithImpl(this._self, this._then);

  final _UserAchievementModel _self;
  final $Res Function(_UserAchievementModel) _then;

/// Create a copy of UserAchievementModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? achievementId = null,Object? progress = null,Object? unlocked = null,Object? unlockedAt = freezed,}) {
  return _then(_UserAchievementModel(
achievementId: null == achievementId ? _self.achievementId : achievementId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,unlockedAt: freezed == unlockedAt ? _self.unlockedAt : unlockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
