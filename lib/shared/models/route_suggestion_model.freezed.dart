// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_suggestion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteSuggestionModel {

 String get id; String get suggestedBy; String get originText; double? get originLat; double? get originLng; String get destinationText; double? get destinationLat; double? get destinationLng; String? get routeCode; String? get operatorName; ServiceType? get serviceType; String? get detailLevel; String? get source; String? get notes; SuggestionStatus get status; int get voteCount; int get contributionCount; Priority get priority; DateTime get createdAt;
/// Create a copy of RouteSuggestionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteSuggestionModelCopyWith<RouteSuggestionModel> get copyWith => _$RouteSuggestionModelCopyWithImpl<RouteSuggestionModel>(this as RouteSuggestionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteSuggestionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.suggestedBy, suggestedBy) || other.suggestedBy == suggestedBy)&&(identical(other.originText, originText) || other.originText == originText)&&(identical(other.originLat, originLat) || other.originLat == originLat)&&(identical(other.originLng, originLng) || other.originLng == originLng)&&(identical(other.destinationText, destinationText) || other.destinationText == destinationText)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.routeCode, routeCode) || other.routeCode == routeCode)&&(identical(other.operatorName, operatorName) || other.operatorName == operatorName)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.detailLevel, detailLevel) || other.detailLevel == detailLevel)&&(identical(other.source, source) || other.source == source)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.contributionCount, contributionCount) || other.contributionCount == contributionCount)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,suggestedBy,originText,originLat,originLng,destinationText,destinationLat,destinationLng,routeCode,operatorName,serviceType,detailLevel,source,notes,status,voteCount,contributionCount,priority,createdAt]);

@override
String toString() {
  return 'RouteSuggestionModel(id: $id, suggestedBy: $suggestedBy, originText: $originText, originLat: $originLat, originLng: $originLng, destinationText: $destinationText, destinationLat: $destinationLat, destinationLng: $destinationLng, routeCode: $routeCode, operatorName: $operatorName, serviceType: $serviceType, detailLevel: $detailLevel, source: $source, notes: $notes, status: $status, voteCount: $voteCount, contributionCount: $contributionCount, priority: $priority, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RouteSuggestionModelCopyWith<$Res>  {
  factory $RouteSuggestionModelCopyWith(RouteSuggestionModel value, $Res Function(RouteSuggestionModel) _then) = _$RouteSuggestionModelCopyWithImpl;
@useResult
$Res call({
 String id, String suggestedBy, String originText, double? originLat, double? originLng, String destinationText, double? destinationLat, double? destinationLng, String? routeCode, String? operatorName, ServiceType? serviceType, String? detailLevel, String? source, String? notes, SuggestionStatus status, int voteCount, int contributionCount, Priority priority, DateTime createdAt
});




}
/// @nodoc
class _$RouteSuggestionModelCopyWithImpl<$Res>
    implements $RouteSuggestionModelCopyWith<$Res> {
  _$RouteSuggestionModelCopyWithImpl(this._self, this._then);

  final RouteSuggestionModel _self;
  final $Res Function(RouteSuggestionModel) _then;

/// Create a copy of RouteSuggestionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? suggestedBy = null,Object? originText = null,Object? originLat = freezed,Object? originLng = freezed,Object? destinationText = null,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? routeCode = freezed,Object? operatorName = freezed,Object? serviceType = freezed,Object? detailLevel = freezed,Object? source = freezed,Object? notes = freezed,Object? status = null,Object? voteCount = null,Object? contributionCount = null,Object? priority = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,suggestedBy: null == suggestedBy ? _self.suggestedBy : suggestedBy // ignore: cast_nullable_to_non_nullable
as String,originText: null == originText ? _self.originText : originText // ignore: cast_nullable_to_non_nullable
as String,originLat: freezed == originLat ? _self.originLat : originLat // ignore: cast_nullable_to_non_nullable
as double?,originLng: freezed == originLng ? _self.originLng : originLng // ignore: cast_nullable_to_non_nullable
as double?,destinationText: null == destinationText ? _self.destinationText : destinationText // ignore: cast_nullable_to_non_nullable
as String,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,routeCode: freezed == routeCode ? _self.routeCode : routeCode // ignore: cast_nullable_to_non_nullable
as String?,operatorName: freezed == operatorName ? _self.operatorName : operatorName // ignore: cast_nullable_to_non_nullable
as String?,serviceType: freezed == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as ServiceType?,detailLevel: freezed == detailLevel ? _self.detailLevel : detailLevel // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SuggestionStatus,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,contributionCount: null == contributionCount ? _self.contributionCount : contributionCount // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteSuggestionModel].
extension RouteSuggestionModelPatterns on RouteSuggestionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteSuggestionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteSuggestionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteSuggestionModel value)  $default,){
final _that = this;
switch (_that) {
case _RouteSuggestionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteSuggestionModel value)?  $default,){
final _that = this;
switch (_that) {
case _RouteSuggestionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String suggestedBy,  String originText,  double? originLat,  double? originLng,  String destinationText,  double? destinationLat,  double? destinationLng,  String? routeCode,  String? operatorName,  ServiceType? serviceType,  String? detailLevel,  String? source,  String? notes,  SuggestionStatus status,  int voteCount,  int contributionCount,  Priority priority,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteSuggestionModel() when $default != null:
return $default(_that.id,_that.suggestedBy,_that.originText,_that.originLat,_that.originLng,_that.destinationText,_that.destinationLat,_that.destinationLng,_that.routeCode,_that.operatorName,_that.serviceType,_that.detailLevel,_that.source,_that.notes,_that.status,_that.voteCount,_that.contributionCount,_that.priority,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String suggestedBy,  String originText,  double? originLat,  double? originLng,  String destinationText,  double? destinationLat,  double? destinationLng,  String? routeCode,  String? operatorName,  ServiceType? serviceType,  String? detailLevel,  String? source,  String? notes,  SuggestionStatus status,  int voteCount,  int contributionCount,  Priority priority,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RouteSuggestionModel():
return $default(_that.id,_that.suggestedBy,_that.originText,_that.originLat,_that.originLng,_that.destinationText,_that.destinationLat,_that.destinationLng,_that.routeCode,_that.operatorName,_that.serviceType,_that.detailLevel,_that.source,_that.notes,_that.status,_that.voteCount,_that.contributionCount,_that.priority,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String suggestedBy,  String originText,  double? originLat,  double? originLng,  String destinationText,  double? destinationLat,  double? destinationLng,  String? routeCode,  String? operatorName,  ServiceType? serviceType,  String? detailLevel,  String? source,  String? notes,  SuggestionStatus status,  int voteCount,  int contributionCount,  Priority priority,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteSuggestionModel() when $default != null:
return $default(_that.id,_that.suggestedBy,_that.originText,_that.originLat,_that.originLng,_that.destinationText,_that.destinationLat,_that.destinationLng,_that.routeCode,_that.operatorName,_that.serviceType,_that.detailLevel,_that.source,_that.notes,_that.status,_that.voteCount,_that.contributionCount,_that.priority,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _RouteSuggestionModel extends RouteSuggestionModel {
  const _RouteSuggestionModel({required this.id, required this.suggestedBy, required this.originText, this.originLat, this.originLng, required this.destinationText, this.destinationLat, this.destinationLng, this.routeCode, this.operatorName, this.serviceType, this.detailLevel, this.source, this.notes, required this.status, this.voteCount = 0, this.contributionCount = 0, this.priority = Priority.medium, required this.createdAt}): super._();
  

@override final  String id;
@override final  String suggestedBy;
@override final  String originText;
@override final  double? originLat;
@override final  double? originLng;
@override final  String destinationText;
@override final  double? destinationLat;
@override final  double? destinationLng;
@override final  String? routeCode;
@override final  String? operatorName;
@override final  ServiceType? serviceType;
@override final  String? detailLevel;
@override final  String? source;
@override final  String? notes;
@override final  SuggestionStatus status;
@override@JsonKey() final  int voteCount;
@override@JsonKey() final  int contributionCount;
@override@JsonKey() final  Priority priority;
@override final  DateTime createdAt;

/// Create a copy of RouteSuggestionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteSuggestionModelCopyWith<_RouteSuggestionModel> get copyWith => __$RouteSuggestionModelCopyWithImpl<_RouteSuggestionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteSuggestionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.suggestedBy, suggestedBy) || other.suggestedBy == suggestedBy)&&(identical(other.originText, originText) || other.originText == originText)&&(identical(other.originLat, originLat) || other.originLat == originLat)&&(identical(other.originLng, originLng) || other.originLng == originLng)&&(identical(other.destinationText, destinationText) || other.destinationText == destinationText)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.routeCode, routeCode) || other.routeCode == routeCode)&&(identical(other.operatorName, operatorName) || other.operatorName == operatorName)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.detailLevel, detailLevel) || other.detailLevel == detailLevel)&&(identical(other.source, source) || other.source == source)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.contributionCount, contributionCount) || other.contributionCount == contributionCount)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,suggestedBy,originText,originLat,originLng,destinationText,destinationLat,destinationLng,routeCode,operatorName,serviceType,detailLevel,source,notes,status,voteCount,contributionCount,priority,createdAt]);

@override
String toString() {
  return 'RouteSuggestionModel(id: $id, suggestedBy: $suggestedBy, originText: $originText, originLat: $originLat, originLng: $originLng, destinationText: $destinationText, destinationLat: $destinationLat, destinationLng: $destinationLng, routeCode: $routeCode, operatorName: $operatorName, serviceType: $serviceType, detailLevel: $detailLevel, source: $source, notes: $notes, status: $status, voteCount: $voteCount, contributionCount: $contributionCount, priority: $priority, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RouteSuggestionModelCopyWith<$Res> implements $RouteSuggestionModelCopyWith<$Res> {
  factory _$RouteSuggestionModelCopyWith(_RouteSuggestionModel value, $Res Function(_RouteSuggestionModel) _then) = __$RouteSuggestionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String suggestedBy, String originText, double? originLat, double? originLng, String destinationText, double? destinationLat, double? destinationLng, String? routeCode, String? operatorName, ServiceType? serviceType, String? detailLevel, String? source, String? notes, SuggestionStatus status, int voteCount, int contributionCount, Priority priority, DateTime createdAt
});




}
/// @nodoc
class __$RouteSuggestionModelCopyWithImpl<$Res>
    implements _$RouteSuggestionModelCopyWith<$Res> {
  __$RouteSuggestionModelCopyWithImpl(this._self, this._then);

  final _RouteSuggestionModel _self;
  final $Res Function(_RouteSuggestionModel) _then;

/// Create a copy of RouteSuggestionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? suggestedBy = null,Object? originText = null,Object? originLat = freezed,Object? originLng = freezed,Object? destinationText = null,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? routeCode = freezed,Object? operatorName = freezed,Object? serviceType = freezed,Object? detailLevel = freezed,Object? source = freezed,Object? notes = freezed,Object? status = null,Object? voteCount = null,Object? contributionCount = null,Object? priority = null,Object? createdAt = null,}) {
  return _then(_RouteSuggestionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,suggestedBy: null == suggestedBy ? _self.suggestedBy : suggestedBy // ignore: cast_nullable_to_non_nullable
as String,originText: null == originText ? _self.originText : originText // ignore: cast_nullable_to_non_nullable
as String,originLat: freezed == originLat ? _self.originLat : originLat // ignore: cast_nullable_to_non_nullable
as double?,originLng: freezed == originLng ? _self.originLng : originLng // ignore: cast_nullable_to_non_nullable
as double?,destinationText: null == destinationText ? _self.destinationText : destinationText // ignore: cast_nullable_to_non_nullable
as String,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,routeCode: freezed == routeCode ? _self.routeCode : routeCode // ignore: cast_nullable_to_non_nullable
as String?,operatorName: freezed == operatorName ? _self.operatorName : operatorName // ignore: cast_nullable_to_non_nullable
as String?,serviceType: freezed == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as ServiceType?,detailLevel: freezed == detailLevel ? _self.detailLevel : detailLevel // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SuggestionStatus,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,contributionCount: null == contributionCount ? _self.contributionCount : contributionCount // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
