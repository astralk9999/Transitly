// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedbackMessageModel {

 String get id; String get feedbackId; String get userId; String get message; bool get isFromManager; DateTime get createdAt;
/// Create a copy of FeedbackMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackMessageModelCopyWith<FeedbackMessageModel> get copyWith => _$FeedbackMessageModelCopyWithImpl<FeedbackMessageModel>(this as FeedbackMessageModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.feedbackId, feedbackId) || other.feedbackId == feedbackId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.isFromManager, isFromManager) || other.isFromManager == isFromManager)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,feedbackId,userId,message,isFromManager,createdAt);

@override
String toString() {
  return 'FeedbackMessageModel(id: $id, feedbackId: $feedbackId, userId: $userId, message: $message, isFromManager: $isFromManager, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FeedbackMessageModelCopyWith<$Res>  {
  factory $FeedbackMessageModelCopyWith(FeedbackMessageModel value, $Res Function(FeedbackMessageModel) _then) = _$FeedbackMessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String feedbackId, String userId, String message, bool isFromManager, DateTime createdAt
});




}
/// @nodoc
class _$FeedbackMessageModelCopyWithImpl<$Res>
    implements $FeedbackMessageModelCopyWith<$Res> {
  _$FeedbackMessageModelCopyWithImpl(this._self, this._then);

  final FeedbackMessageModel _self;
  final $Res Function(FeedbackMessageModel) _then;

/// Create a copy of FeedbackMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? feedbackId = null,Object? userId = null,Object? message = null,Object? isFromManager = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,feedbackId: null == feedbackId ? _self.feedbackId : feedbackId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,isFromManager: null == isFromManager ? _self.isFromManager : isFromManager // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackMessageModel].
extension FeedbackMessageModelPatterns on FeedbackMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String feedbackId,  String userId,  String message,  bool isFromManager,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackMessageModel() when $default != null:
return $default(_that.id,_that.feedbackId,_that.userId,_that.message,_that.isFromManager,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String feedbackId,  String userId,  String message,  bool isFromManager,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FeedbackMessageModel():
return $default(_that.id,_that.feedbackId,_that.userId,_that.message,_that.isFromManager,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String feedbackId,  String userId,  String message,  bool isFromManager,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackMessageModel() when $default != null:
return $default(_that.id,_that.feedbackId,_that.userId,_that.message,_that.isFromManager,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _FeedbackMessageModel extends FeedbackMessageModel {
  const _FeedbackMessageModel({required this.id, required this.feedbackId, required this.userId, required this.message, this.isFromManager = false, required this.createdAt}): super._();
  

@override final  String id;
@override final  String feedbackId;
@override final  String userId;
@override final  String message;
@override@JsonKey() final  bool isFromManager;
@override final  DateTime createdAt;

/// Create a copy of FeedbackMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackMessageModelCopyWith<_FeedbackMessageModel> get copyWith => __$FeedbackMessageModelCopyWithImpl<_FeedbackMessageModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.feedbackId, feedbackId) || other.feedbackId == feedbackId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.isFromManager, isFromManager) || other.isFromManager == isFromManager)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,feedbackId,userId,message,isFromManager,createdAt);

@override
String toString() {
  return 'FeedbackMessageModel(id: $id, feedbackId: $feedbackId, userId: $userId, message: $message, isFromManager: $isFromManager, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FeedbackMessageModelCopyWith<$Res> implements $FeedbackMessageModelCopyWith<$Res> {
  factory _$FeedbackMessageModelCopyWith(_FeedbackMessageModel value, $Res Function(_FeedbackMessageModel) _then) = __$FeedbackMessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String feedbackId, String userId, String message, bool isFromManager, DateTime createdAt
});




}
/// @nodoc
class __$FeedbackMessageModelCopyWithImpl<$Res>
    implements _$FeedbackMessageModelCopyWith<$Res> {
  __$FeedbackMessageModelCopyWithImpl(this._self, this._then);

  final _FeedbackMessageModel _self;
  final $Res Function(_FeedbackMessageModel) _then;

/// Create a copy of FeedbackMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? feedbackId = null,Object? userId = null,Object? message = null,Object? isFromManager = null,Object? createdAt = null,}) {
  return _then(_FeedbackMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,feedbackId: null == feedbackId ? _self.feedbackId : feedbackId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,isFromManager: null == isFromManager ? _self.isFromManager : isFromManager // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
