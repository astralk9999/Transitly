// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveTripModel {

 String get id; String get routeId; String? get driverId; DateTime? get startedAt; double? get currentLat; double? get currentLng; double? get currentBearing; int? get currentStopIndex; TripStatus get status; int get delayMinutes; BusCapacity get capacity; String? get vehicleNumber; String? get driverMessage;
/// Create a copy of ActiveTripModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveTripModelCopyWith<ActiveTripModel> get copyWith => _$ActiveTripModelCopyWithImpl<ActiveTripModel>(this as ActiveTripModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveTripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.currentLat, currentLat) || other.currentLat == currentLat)&&(identical(other.currentLng, currentLng) || other.currentLng == currentLng)&&(identical(other.currentBearing, currentBearing) || other.currentBearing == currentBearing)&&(identical(other.currentStopIndex, currentStopIndex) || other.currentStopIndex == currentStopIndex)&&(identical(other.status, status) || other.status == status)&&(identical(other.delayMinutes, delayMinutes) || other.delayMinutes == delayMinutes)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.driverMessage, driverMessage) || other.driverMessage == driverMessage));
}


@override
int get hashCode => Object.hash(runtimeType,id,routeId,driverId,startedAt,currentLat,currentLng,currentBearing,currentStopIndex,status,delayMinutes,capacity,vehicleNumber,driverMessage);

@override
String toString() {
  return 'ActiveTripModel(id: $id, routeId: $routeId, driverId: $driverId, startedAt: $startedAt, currentLat: $currentLat, currentLng: $currentLng, currentBearing: $currentBearing, currentStopIndex: $currentStopIndex, status: $status, delayMinutes: $delayMinutes, capacity: $capacity, vehicleNumber: $vehicleNumber, driverMessage: $driverMessage)';
}


}

/// @nodoc
abstract mixin class $ActiveTripModelCopyWith<$Res>  {
  factory $ActiveTripModelCopyWith(ActiveTripModel value, $Res Function(ActiveTripModel) _then) = _$ActiveTripModelCopyWithImpl;
@useResult
$Res call({
 String id, String routeId, String? driverId, DateTime? startedAt, double? currentLat, double? currentLng, double? currentBearing, int? currentStopIndex, TripStatus status, int delayMinutes, BusCapacity capacity, String? vehicleNumber, String? driverMessage
});




}
/// @nodoc
class _$ActiveTripModelCopyWithImpl<$Res>
    implements $ActiveTripModelCopyWith<$Res> {
  _$ActiveTripModelCopyWithImpl(this._self, this._then);

  final ActiveTripModel _self;
  final $Res Function(ActiveTripModel) _then;

/// Create a copy of ActiveTripModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routeId = null,Object? driverId = freezed,Object? startedAt = freezed,Object? currentLat = freezed,Object? currentLng = freezed,Object? currentBearing = freezed,Object? currentStopIndex = freezed,Object? status = null,Object? delayMinutes = null,Object? capacity = null,Object? vehicleNumber = freezed,Object? driverMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLat: freezed == currentLat ? _self.currentLat : currentLat // ignore: cast_nullable_to_non_nullable
as double?,currentLng: freezed == currentLng ? _self.currentLng : currentLng // ignore: cast_nullable_to_non_nullable
as double?,currentBearing: freezed == currentBearing ? _self.currentBearing : currentBearing // ignore: cast_nullable_to_non_nullable
as double?,currentStopIndex: freezed == currentStopIndex ? _self.currentStopIndex : currentStopIndex // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,delayMinutes: null == delayMinutes ? _self.delayMinutes : delayMinutes // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as BusCapacity,vehicleNumber: freezed == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String?,driverMessage: freezed == driverMessage ? _self.driverMessage : driverMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActiveTripModel].
extension ActiveTripModelPatterns on ActiveTripModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveTripModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveTripModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveTripModel value)  $default,){
final _that = this;
switch (_that) {
case _ActiveTripModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveTripModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveTripModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String routeId,  String? driverId,  DateTime? startedAt,  double? currentLat,  double? currentLng,  double? currentBearing,  int? currentStopIndex,  TripStatus status,  int delayMinutes,  BusCapacity capacity,  String? vehicleNumber,  String? driverMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveTripModel() when $default != null:
return $default(_that.id,_that.routeId,_that.driverId,_that.startedAt,_that.currentLat,_that.currentLng,_that.currentBearing,_that.currentStopIndex,_that.status,_that.delayMinutes,_that.capacity,_that.vehicleNumber,_that.driverMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String routeId,  String? driverId,  DateTime? startedAt,  double? currentLat,  double? currentLng,  double? currentBearing,  int? currentStopIndex,  TripStatus status,  int delayMinutes,  BusCapacity capacity,  String? vehicleNumber,  String? driverMessage)  $default,) {final _that = this;
switch (_that) {
case _ActiveTripModel():
return $default(_that.id,_that.routeId,_that.driverId,_that.startedAt,_that.currentLat,_that.currentLng,_that.currentBearing,_that.currentStopIndex,_that.status,_that.delayMinutes,_that.capacity,_that.vehicleNumber,_that.driverMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String routeId,  String? driverId,  DateTime? startedAt,  double? currentLat,  double? currentLng,  double? currentBearing,  int? currentStopIndex,  TripStatus status,  int delayMinutes,  BusCapacity capacity,  String? vehicleNumber,  String? driverMessage)?  $default,) {final _that = this;
switch (_that) {
case _ActiveTripModel() when $default != null:
return $default(_that.id,_that.routeId,_that.driverId,_that.startedAt,_that.currentLat,_that.currentLng,_that.currentBearing,_that.currentStopIndex,_that.status,_that.delayMinutes,_that.capacity,_that.vehicleNumber,_that.driverMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveTripModel extends ActiveTripModel {
  const _ActiveTripModel({required this.id, required this.routeId, this.driverId, this.startedAt, this.currentLat, this.currentLng, this.currentBearing, this.currentStopIndex, required this.status, this.delayMinutes = 0, required this.capacity, this.vehicleNumber, this.driverMessage}): super._();
  

@override final  String id;
@override final  String routeId;
@override final  String? driverId;
@override final  DateTime? startedAt;
@override final  double? currentLat;
@override final  double? currentLng;
@override final  double? currentBearing;
@override final  int? currentStopIndex;
@override final  TripStatus status;
@override@JsonKey() final  int delayMinutes;
@override final  BusCapacity capacity;
@override final  String? vehicleNumber;
@override final  String? driverMessage;

/// Create a copy of ActiveTripModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveTripModelCopyWith<_ActiveTripModel> get copyWith => __$ActiveTripModelCopyWithImpl<_ActiveTripModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveTripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.currentLat, currentLat) || other.currentLat == currentLat)&&(identical(other.currentLng, currentLng) || other.currentLng == currentLng)&&(identical(other.currentBearing, currentBearing) || other.currentBearing == currentBearing)&&(identical(other.currentStopIndex, currentStopIndex) || other.currentStopIndex == currentStopIndex)&&(identical(other.status, status) || other.status == status)&&(identical(other.delayMinutes, delayMinutes) || other.delayMinutes == delayMinutes)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.driverMessage, driverMessage) || other.driverMessage == driverMessage));
}


@override
int get hashCode => Object.hash(runtimeType,id,routeId,driverId,startedAt,currentLat,currentLng,currentBearing,currentStopIndex,status,delayMinutes,capacity,vehicleNumber,driverMessage);

@override
String toString() {
  return 'ActiveTripModel(id: $id, routeId: $routeId, driverId: $driverId, startedAt: $startedAt, currentLat: $currentLat, currentLng: $currentLng, currentBearing: $currentBearing, currentStopIndex: $currentStopIndex, status: $status, delayMinutes: $delayMinutes, capacity: $capacity, vehicleNumber: $vehicleNumber, driverMessage: $driverMessage)';
}


}

/// @nodoc
abstract mixin class _$ActiveTripModelCopyWith<$Res> implements $ActiveTripModelCopyWith<$Res> {
  factory _$ActiveTripModelCopyWith(_ActiveTripModel value, $Res Function(_ActiveTripModel) _then) = __$ActiveTripModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String routeId, String? driverId, DateTime? startedAt, double? currentLat, double? currentLng, double? currentBearing, int? currentStopIndex, TripStatus status, int delayMinutes, BusCapacity capacity, String? vehicleNumber, String? driverMessage
});




}
/// @nodoc
class __$ActiveTripModelCopyWithImpl<$Res>
    implements _$ActiveTripModelCopyWith<$Res> {
  __$ActiveTripModelCopyWithImpl(this._self, this._then);

  final _ActiveTripModel _self;
  final $Res Function(_ActiveTripModel) _then;

/// Create a copy of ActiveTripModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routeId = null,Object? driverId = freezed,Object? startedAt = freezed,Object? currentLat = freezed,Object? currentLng = freezed,Object? currentBearing = freezed,Object? currentStopIndex = freezed,Object? status = null,Object? delayMinutes = null,Object? capacity = null,Object? vehicleNumber = freezed,Object? driverMessage = freezed,}) {
  return _then(_ActiveTripModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLat: freezed == currentLat ? _self.currentLat : currentLat // ignore: cast_nullable_to_non_nullable
as double?,currentLng: freezed == currentLng ? _self.currentLng : currentLng // ignore: cast_nullable_to_non_nullable
as double?,currentBearing: freezed == currentBearing ? _self.currentBearing : currentBearing // ignore: cast_nullable_to_non_nullable
as double?,currentStopIndex: freezed == currentStopIndex ? _self.currentStopIndex : currentStopIndex // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,delayMinutes: null == delayMinutes ? _self.delayMinutes : delayMinutes // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as BusCapacity,vehicleNumber: freezed == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String?,driverMessage: freezed == driverMessage ? _self.driverMessage : driverMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
