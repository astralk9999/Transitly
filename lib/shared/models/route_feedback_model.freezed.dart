// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_feedback_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteFeedbackModel {

 String get id; String get userId; String get routeId; String? get stopId; FeedbackType get feedbackType; String get description; List<String> get photoUrls; FeedbackStatus get status; Priority get autoPriority; int get similarFeedbackCount; DateTime get createdAt;
/// Create a copy of RouteFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteFeedbackModelCopyWith<RouteFeedbackModel> get copyWith => _$RouteFeedbackModelCopyWithImpl<RouteFeedbackModel>(this as RouteFeedbackModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteFeedbackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.feedbackType, feedbackType) || other.feedbackType == feedbackType)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.photoUrls, photoUrls)&&(identical(other.status, status) || other.status == status)&&(identical(other.autoPriority, autoPriority) || other.autoPriority == autoPriority)&&(identical(other.similarFeedbackCount, similarFeedbackCount) || other.similarFeedbackCount == similarFeedbackCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,stopId,feedbackType,description,const DeepCollectionEquality().hash(photoUrls),status,autoPriority,similarFeedbackCount,createdAt);

@override
String toString() {
  return 'RouteFeedbackModel(id: $id, userId: $userId, routeId: $routeId, stopId: $stopId, feedbackType: $feedbackType, description: $description, photoUrls: $photoUrls, status: $status, autoPriority: $autoPriority, similarFeedbackCount: $similarFeedbackCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RouteFeedbackModelCopyWith<$Res>  {
  factory $RouteFeedbackModelCopyWith(RouteFeedbackModel value, $Res Function(RouteFeedbackModel) _then) = _$RouteFeedbackModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String routeId, String? stopId, FeedbackType feedbackType, String description, List<String> photoUrls, FeedbackStatus status, Priority autoPriority, int similarFeedbackCount, DateTime createdAt
});




}
/// @nodoc
class _$RouteFeedbackModelCopyWithImpl<$Res>
    implements $RouteFeedbackModelCopyWith<$Res> {
  _$RouteFeedbackModelCopyWithImpl(this._self, this._then);

  final RouteFeedbackModel _self;
  final $Res Function(RouteFeedbackModel) _then;

/// Create a copy of RouteFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? stopId = freezed,Object? feedbackType = null,Object? description = null,Object? photoUrls = null,Object? status = null,Object? autoPriority = null,Object? similarFeedbackCount = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: freezed == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String?,feedbackType: null == feedbackType ? _self.feedbackType : feedbackType // ignore: cast_nullable_to_non_nullable
as FeedbackType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeedbackStatus,autoPriority: null == autoPriority ? _self.autoPriority : autoPriority // ignore: cast_nullable_to_non_nullable
as Priority,similarFeedbackCount: null == similarFeedbackCount ? _self.similarFeedbackCount : similarFeedbackCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteFeedbackModel].
extension RouteFeedbackModelPatterns on RouteFeedbackModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteFeedbackModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteFeedbackModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteFeedbackModel value)  $default,){
final _that = this;
switch (_that) {
case _RouteFeedbackModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteFeedbackModel value)?  $default,){
final _that = this;
switch (_that) {
case _RouteFeedbackModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? stopId,  FeedbackType feedbackType,  String description,  List<String> photoUrls,  FeedbackStatus status,  Priority autoPriority,  int similarFeedbackCount,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteFeedbackModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.feedbackType,_that.description,_that.photoUrls,_that.status,_that.autoPriority,_that.similarFeedbackCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? stopId,  FeedbackType feedbackType,  String description,  List<String> photoUrls,  FeedbackStatus status,  Priority autoPriority,  int similarFeedbackCount,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RouteFeedbackModel():
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.feedbackType,_that.description,_that.photoUrls,_that.status,_that.autoPriority,_that.similarFeedbackCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String routeId,  String? stopId,  FeedbackType feedbackType,  String description,  List<String> photoUrls,  FeedbackStatus status,  Priority autoPriority,  int similarFeedbackCount,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteFeedbackModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.feedbackType,_that.description,_that.photoUrls,_that.status,_that.autoPriority,_that.similarFeedbackCount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _RouteFeedbackModel extends RouteFeedbackModel {
  const _RouteFeedbackModel({required this.id, required this.userId, required this.routeId, this.stopId, required this.feedbackType, required this.description, final  List<String> photoUrls = const <String>[], required this.status, this.autoPriority = Priority.medium, this.similarFeedbackCount = 0, required this.createdAt}): _photoUrls = photoUrls,super._();
  

@override final  String id;
@override final  String userId;
@override final  String routeId;
@override final  String? stopId;
@override final  FeedbackType feedbackType;
@override final  String description;
 final  List<String> _photoUrls;
@override@JsonKey() List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override final  FeedbackStatus status;
@override@JsonKey() final  Priority autoPriority;
@override@JsonKey() final  int similarFeedbackCount;
@override final  DateTime createdAt;

/// Create a copy of RouteFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteFeedbackModelCopyWith<_RouteFeedbackModel> get copyWith => __$RouteFeedbackModelCopyWithImpl<_RouteFeedbackModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteFeedbackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.feedbackType, feedbackType) || other.feedbackType == feedbackType)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._photoUrls, _photoUrls)&&(identical(other.status, status) || other.status == status)&&(identical(other.autoPriority, autoPriority) || other.autoPriority == autoPriority)&&(identical(other.similarFeedbackCount, similarFeedbackCount) || other.similarFeedbackCount == similarFeedbackCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,stopId,feedbackType,description,const DeepCollectionEquality().hash(_photoUrls),status,autoPriority,similarFeedbackCount,createdAt);

@override
String toString() {
  return 'RouteFeedbackModel(id: $id, userId: $userId, routeId: $routeId, stopId: $stopId, feedbackType: $feedbackType, description: $description, photoUrls: $photoUrls, status: $status, autoPriority: $autoPriority, similarFeedbackCount: $similarFeedbackCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RouteFeedbackModelCopyWith<$Res> implements $RouteFeedbackModelCopyWith<$Res> {
  factory _$RouteFeedbackModelCopyWith(_RouteFeedbackModel value, $Res Function(_RouteFeedbackModel) _then) = __$RouteFeedbackModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String routeId, String? stopId, FeedbackType feedbackType, String description, List<String> photoUrls, FeedbackStatus status, Priority autoPriority, int similarFeedbackCount, DateTime createdAt
});




}
/// @nodoc
class __$RouteFeedbackModelCopyWithImpl<$Res>
    implements _$RouteFeedbackModelCopyWith<$Res> {
  __$RouteFeedbackModelCopyWithImpl(this._self, this._then);

  final _RouteFeedbackModel _self;
  final $Res Function(_RouteFeedbackModel) _then;

/// Create a copy of RouteFeedbackModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? stopId = freezed,Object? feedbackType = null,Object? description = null,Object? photoUrls = null,Object? status = null,Object? autoPriority = null,Object? similarFeedbackCount = null,Object? createdAt = null,}) {
  return _then(_RouteFeedbackModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: freezed == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String?,feedbackType: null == feedbackType ? _self.feedbackType : feedbackType // ignore: cast_nullable_to_non_nullable
as FeedbackType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeedbackStatus,autoPriority: null == autoPriority ? _self.autoPriority : autoPriority // ignore: cast_nullable_to_non_nullable
as Priority,similarFeedbackCount: null == similarFeedbackCount ? _self.similarFeedbackCount : similarFeedbackCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
