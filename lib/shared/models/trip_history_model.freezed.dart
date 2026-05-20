// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripHistoryModel {

 String get id; String get userId; String get routeId; String? get fromStopId; String? get toStopId; DateTime get startedAt; double? get cost; double? get distanceKm; double? get co2SavedKg;
/// Create a copy of TripHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripHistoryModelCopyWith<TripHistoryModel> get copyWith => _$TripHistoryModelCopyWithImpl<TripHistoryModel>(this as TripHistoryModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.fromStopId, fromStopId) || other.fromStopId == fromStopId)&&(identical(other.toStopId, toStopId) || other.toStopId == toStopId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.co2SavedKg, co2SavedKg) || other.co2SavedKg == co2SavedKg));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,fromStopId,toStopId,startedAt,cost,distanceKm,co2SavedKg);

@override
String toString() {
  return 'TripHistoryModel(id: $id, userId: $userId, routeId: $routeId, fromStopId: $fromStopId, toStopId: $toStopId, startedAt: $startedAt, cost: $cost, distanceKm: $distanceKm, co2SavedKg: $co2SavedKg)';
}


}

/// @nodoc
abstract mixin class $TripHistoryModelCopyWith<$Res>  {
  factory $TripHistoryModelCopyWith(TripHistoryModel value, $Res Function(TripHistoryModel) _then) = _$TripHistoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String routeId, String? fromStopId, String? toStopId, DateTime startedAt, double? cost, double? distanceKm, double? co2SavedKg
});




}
/// @nodoc
class _$TripHistoryModelCopyWithImpl<$Res>
    implements $TripHistoryModelCopyWith<$Res> {
  _$TripHistoryModelCopyWithImpl(this._self, this._then);

  final TripHistoryModel _self;
  final $Res Function(TripHistoryModel) _then;

/// Create a copy of TripHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? fromStopId = freezed,Object? toStopId = freezed,Object? startedAt = null,Object? cost = freezed,Object? distanceKm = freezed,Object? co2SavedKg = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,fromStopId: freezed == fromStopId ? _self.fromStopId : fromStopId // ignore: cast_nullable_to_non_nullable
as String?,toStopId: freezed == toStopId ? _self.toStopId : toStopId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,co2SavedKg: freezed == co2SavedKg ? _self.co2SavedKg : co2SavedKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripHistoryModel].
extension TripHistoryModelPatterns on TripHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _TripHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _TripHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? fromStopId,  String? toStopId,  DateTime startedAt,  double? cost,  double? distanceKm,  double? co2SavedKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripHistoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.fromStopId,_that.toStopId,_that.startedAt,_that.cost,_that.distanceKm,_that.co2SavedKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String? fromStopId,  String? toStopId,  DateTime startedAt,  double? cost,  double? distanceKm,  double? co2SavedKg)  $default,) {final _that = this;
switch (_that) {
case _TripHistoryModel():
return $default(_that.id,_that.userId,_that.routeId,_that.fromStopId,_that.toStopId,_that.startedAt,_that.cost,_that.distanceKm,_that.co2SavedKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String routeId,  String? fromStopId,  String? toStopId,  DateTime startedAt,  double? cost,  double? distanceKm,  double? co2SavedKg)?  $default,) {final _that = this;
switch (_that) {
case _TripHistoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.fromStopId,_that.toStopId,_that.startedAt,_that.cost,_that.distanceKm,_that.co2SavedKg);case _:
  return null;

}
}

}

/// @nodoc


class _TripHistoryModel extends TripHistoryModel {
  const _TripHistoryModel({required this.id, required this.userId, required this.routeId, this.fromStopId, this.toStopId, required this.startedAt, this.cost, this.distanceKm, this.co2SavedKg}): super._();
  

@override final  String id;
@override final  String userId;
@override final  String routeId;
@override final  String? fromStopId;
@override final  String? toStopId;
@override final  DateTime startedAt;
@override final  double? cost;
@override final  double? distanceKm;
@override final  double? co2SavedKg;

/// Create a copy of TripHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripHistoryModelCopyWith<_TripHistoryModel> get copyWith => __$TripHistoryModelCopyWithImpl<_TripHistoryModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.fromStopId, fromStopId) || other.fromStopId == fromStopId)&&(identical(other.toStopId, toStopId) || other.toStopId == toStopId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.co2SavedKg, co2SavedKg) || other.co2SavedKg == co2SavedKg));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,fromStopId,toStopId,startedAt,cost,distanceKm,co2SavedKg);

@override
String toString() {
  return 'TripHistoryModel(id: $id, userId: $userId, routeId: $routeId, fromStopId: $fromStopId, toStopId: $toStopId, startedAt: $startedAt, cost: $cost, distanceKm: $distanceKm, co2SavedKg: $co2SavedKg)';
}


}

/// @nodoc
abstract mixin class _$TripHistoryModelCopyWith<$Res> implements $TripHistoryModelCopyWith<$Res> {
  factory _$TripHistoryModelCopyWith(_TripHistoryModel value, $Res Function(_TripHistoryModel) _then) = __$TripHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String routeId, String? fromStopId, String? toStopId, DateTime startedAt, double? cost, double? distanceKm, double? co2SavedKg
});




}
/// @nodoc
class __$TripHistoryModelCopyWithImpl<$Res>
    implements _$TripHistoryModelCopyWith<$Res> {
  __$TripHistoryModelCopyWithImpl(this._self, this._then);

  final _TripHistoryModel _self;
  final $Res Function(_TripHistoryModel) _then;

/// Create a copy of TripHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? fromStopId = freezed,Object? toStopId = freezed,Object? startedAt = null,Object? cost = freezed,Object? distanceKm = freezed,Object? co2SavedKg = freezed,}) {
  return _then(_TripHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,fromStopId: freezed == fromStopId ? _self.fromStopId : fromStopId // ignore: cast_nullable_to_non_nullable
as String?,toStopId: freezed == toStopId ? _self.toStopId : toStopId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,co2SavedKg: freezed == co2SavedKg ? _self.co2SavedKg : co2SavedKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
