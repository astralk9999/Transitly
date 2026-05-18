// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incident_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IncidentModel {

 String get id; String get reporterId; String get routeId; String? get stopId; IncidentType get incidentType; IncidentCategory get category; String? get comment; String get status; int get confirmations; DateTime get createdAt;
/// Create a copy of IncidentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentModelCopyWith<IncidentModel> get copyWith => _$IncidentModelCopyWithImpl<IncidentModel>(this as IncidentModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncidentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.incidentType, incidentType) || other.incidentType == incidentType)&&(identical(other.category, category) || other.category == category)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.status, status) || other.status == status)&&(identical(other.confirmations, confirmations) || other.confirmations == confirmations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,reporterId,routeId,stopId,incidentType,category,comment,status,confirmations,createdAt);

@override
String toString() {
  return 'IncidentModel(id: $id, reporterId: $reporterId, routeId: $routeId, stopId: $stopId, incidentType: $incidentType, category: $category, comment: $comment, status: $status, confirmations: $confirmations, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $IncidentModelCopyWith<$Res>  {
  factory $IncidentModelCopyWith(IncidentModel value, $Res Function(IncidentModel) _then) = _$IncidentModelCopyWithImpl;
@useResult
$Res call({
 String id, String reporterId, String routeId, String? stopId, IncidentType incidentType, IncidentCategory category, String? comment, String status, int confirmations, DateTime createdAt
});




}
/// @nodoc
class _$IncidentModelCopyWithImpl<$Res>
    implements $IncidentModelCopyWith<$Res> {
  _$IncidentModelCopyWithImpl(this._self, this._then);

  final IncidentModel _self;
  final $Res Function(IncidentModel) _then;

/// Create a copy of IncidentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reporterId = null,Object? routeId = null,Object? stopId = freezed,Object? incidentType = null,Object? category = null,Object? comment = freezed,Object? status = null,Object? confirmations = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: freezed == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String?,incidentType: null == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as IncidentType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IncidentCategory,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,confirmations: null == confirmations ? _self.confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [IncidentModel].
extension IncidentModelPatterns on IncidentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncidentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncidentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncidentModel value)  $default,){
final _that = this;
switch (_that) {
case _IncidentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncidentModel value)?  $default,){
final _that = this;
switch (_that) {
case _IncidentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reporterId,  String routeId,  String? stopId,  IncidentType incidentType,  IncidentCategory category,  String? comment,  String status,  int confirmations,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncidentModel() when $default != null:
return $default(_that.id,_that.reporterId,_that.routeId,_that.stopId,_that.incidentType,_that.category,_that.comment,_that.status,_that.confirmations,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reporterId,  String routeId,  String? stopId,  IncidentType incidentType,  IncidentCategory category,  String? comment,  String status,  int confirmations,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _IncidentModel():
return $default(_that.id,_that.reporterId,_that.routeId,_that.stopId,_that.incidentType,_that.category,_that.comment,_that.status,_that.confirmations,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reporterId,  String routeId,  String? stopId,  IncidentType incidentType,  IncidentCategory category,  String? comment,  String status,  int confirmations,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _IncidentModel() when $default != null:
return $default(_that.id,_that.reporterId,_that.routeId,_that.stopId,_that.incidentType,_that.category,_that.comment,_that.status,_that.confirmations,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _IncidentModel extends IncidentModel {
  const _IncidentModel({required this.id, required this.reporterId, required this.routeId, this.stopId, required this.incidentType, required this.category, this.comment, required this.status, this.confirmations = 0, required this.createdAt}): super._();
  

@override final  String id;
@override final  String reporterId;
@override final  String routeId;
@override final  String? stopId;
@override final  IncidentType incidentType;
@override final  IncidentCategory category;
@override final  String? comment;
@override final  String status;
@override@JsonKey() final  int confirmations;
@override final  DateTime createdAt;

/// Create a copy of IncidentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentModelCopyWith<_IncidentModel> get copyWith => __$IncidentModelCopyWithImpl<_IncidentModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncidentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.incidentType, incidentType) || other.incidentType == incidentType)&&(identical(other.category, category) || other.category == category)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.status, status) || other.status == status)&&(identical(other.confirmations, confirmations) || other.confirmations == confirmations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,reporterId,routeId,stopId,incidentType,category,comment,status,confirmations,createdAt);

@override
String toString() {
  return 'IncidentModel(id: $id, reporterId: $reporterId, routeId: $routeId, stopId: $stopId, incidentType: $incidentType, category: $category, comment: $comment, status: $status, confirmations: $confirmations, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$IncidentModelCopyWith<$Res> implements $IncidentModelCopyWith<$Res> {
  factory _$IncidentModelCopyWith(_IncidentModel value, $Res Function(_IncidentModel) _then) = __$IncidentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String reporterId, String routeId, String? stopId, IncidentType incidentType, IncidentCategory category, String? comment, String status, int confirmations, DateTime createdAt
});




}
/// @nodoc
class __$IncidentModelCopyWithImpl<$Res>
    implements _$IncidentModelCopyWith<$Res> {
  __$IncidentModelCopyWithImpl(this._self, this._then);

  final _IncidentModel _self;
  final $Res Function(_IncidentModel) _then;

/// Create a copy of IncidentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reporterId = null,Object? routeId = null,Object? stopId = freezed,Object? incidentType = null,Object? category = null,Object? comment = freezed,Object? status = null,Object? confirmations = null,Object? createdAt = null,}) {
  return _then(_IncidentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: freezed == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String?,incidentType: null == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as IncidentType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IncidentCategory,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,confirmations: null == confirmations ? _self.confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
