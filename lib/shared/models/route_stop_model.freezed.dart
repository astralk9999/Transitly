// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_stop_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteStopModel {

 String get routeId; String get stopId; int get orderIndex; RouteDirection get direction; int? get timeFromStartMinutes; double? get distanceFromStartKm;
/// Create a copy of RouteStopModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteStopModelCopyWith<RouteStopModel> get copyWith => _$RouteStopModelCopyWithImpl<RouteStopModel>(this as RouteStopModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteStopModel&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.timeFromStartMinutes, timeFromStartMinutes) || other.timeFromStartMinutes == timeFromStartMinutes)&&(identical(other.distanceFromStartKm, distanceFromStartKm) || other.distanceFromStartKm == distanceFromStartKm));
}


@override
int get hashCode => Object.hash(runtimeType,routeId,stopId,orderIndex,direction,timeFromStartMinutes,distanceFromStartKm);

@override
String toString() {
  return 'RouteStopModel(routeId: $routeId, stopId: $stopId, orderIndex: $orderIndex, direction: $direction, timeFromStartMinutes: $timeFromStartMinutes, distanceFromStartKm: $distanceFromStartKm)';
}


}

/// @nodoc
abstract mixin class $RouteStopModelCopyWith<$Res>  {
  factory $RouteStopModelCopyWith(RouteStopModel value, $Res Function(RouteStopModel) _then) = _$RouteStopModelCopyWithImpl;
@useResult
$Res call({
 String routeId, String stopId, int orderIndex, RouteDirection direction, int? timeFromStartMinutes, double? distanceFromStartKm
});




}
/// @nodoc
class _$RouteStopModelCopyWithImpl<$Res>
    implements $RouteStopModelCopyWith<$Res> {
  _$RouteStopModelCopyWithImpl(this._self, this._then);

  final RouteStopModel _self;
  final $Res Function(RouteStopModel) _then;

/// Create a copy of RouteStopModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? routeId = null,Object? stopId = null,Object? orderIndex = null,Object? direction = null,Object? timeFromStartMinutes = freezed,Object? distanceFromStartKm = freezed,}) {
  return _then(_self.copyWith(
routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: null == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RouteDirection,timeFromStartMinutes: freezed == timeFromStartMinutes ? _self.timeFromStartMinutes : timeFromStartMinutes // ignore: cast_nullable_to_non_nullable
as int?,distanceFromStartKm: freezed == distanceFromStartKm ? _self.distanceFromStartKm : distanceFromStartKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteStopModel].
extension RouteStopModelPatterns on RouteStopModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteStopModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteStopModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteStopModel value)  $default,){
final _that = this;
switch (_that) {
case _RouteStopModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteStopModel value)?  $default,){
final _that = this;
switch (_that) {
case _RouteStopModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String routeId,  String stopId,  int orderIndex,  RouteDirection direction,  int? timeFromStartMinutes,  double? distanceFromStartKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteStopModel() when $default != null:
return $default(_that.routeId,_that.stopId,_that.orderIndex,_that.direction,_that.timeFromStartMinutes,_that.distanceFromStartKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String routeId,  String stopId,  int orderIndex,  RouteDirection direction,  int? timeFromStartMinutes,  double? distanceFromStartKm)  $default,) {final _that = this;
switch (_that) {
case _RouteStopModel():
return $default(_that.routeId,_that.stopId,_that.orderIndex,_that.direction,_that.timeFromStartMinutes,_that.distanceFromStartKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String routeId,  String stopId,  int orderIndex,  RouteDirection direction,  int? timeFromStartMinutes,  double? distanceFromStartKm)?  $default,) {final _that = this;
switch (_that) {
case _RouteStopModel() when $default != null:
return $default(_that.routeId,_that.stopId,_that.orderIndex,_that.direction,_that.timeFromStartMinutes,_that.distanceFromStartKm);case _:
  return null;

}
}

}

/// @nodoc


class _RouteStopModel extends RouteStopModel {
  const _RouteStopModel({required this.routeId, required this.stopId, required this.orderIndex, this.direction = RouteDirection.outbound, this.timeFromStartMinutes, this.distanceFromStartKm}): super._();
  

@override final  String routeId;
@override final  String stopId;
@override final  int orderIndex;
@override@JsonKey() final  RouteDirection direction;
@override final  int? timeFromStartMinutes;
@override final  double? distanceFromStartKm;

/// Create a copy of RouteStopModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteStopModelCopyWith<_RouteStopModel> get copyWith => __$RouteStopModelCopyWithImpl<_RouteStopModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteStopModel&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.timeFromStartMinutes, timeFromStartMinutes) || other.timeFromStartMinutes == timeFromStartMinutes)&&(identical(other.distanceFromStartKm, distanceFromStartKm) || other.distanceFromStartKm == distanceFromStartKm));
}


@override
int get hashCode => Object.hash(runtimeType,routeId,stopId,orderIndex,direction,timeFromStartMinutes,distanceFromStartKm);

@override
String toString() {
  return 'RouteStopModel(routeId: $routeId, stopId: $stopId, orderIndex: $orderIndex, direction: $direction, timeFromStartMinutes: $timeFromStartMinutes, distanceFromStartKm: $distanceFromStartKm)';
}


}

/// @nodoc
abstract mixin class _$RouteStopModelCopyWith<$Res> implements $RouteStopModelCopyWith<$Res> {
  factory _$RouteStopModelCopyWith(_RouteStopModel value, $Res Function(_RouteStopModel) _then) = __$RouteStopModelCopyWithImpl;
@override @useResult
$Res call({
 String routeId, String stopId, int orderIndex, RouteDirection direction, int? timeFromStartMinutes, double? distanceFromStartKm
});




}
/// @nodoc
class __$RouteStopModelCopyWithImpl<$Res>
    implements _$RouteStopModelCopyWith<$Res> {
  __$RouteStopModelCopyWithImpl(this._self, this._then);

  final _RouteStopModel _self;
  final $Res Function(_RouteStopModel) _then;

/// Create a copy of RouteStopModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routeId = null,Object? stopId = null,Object? orderIndex = null,Object? direction = null,Object? timeFromStartMinutes = freezed,Object? distanceFromStartKm = freezed,}) {
  return _then(_RouteStopModel(
routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: null == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RouteDirection,timeFromStartMinutes: freezed == timeFromStartMinutes ? _self.timeFromStartMinutes : timeFromStartMinutes // ignore: cast_nullable_to_non_nullable
as int?,distanceFromStartKm: freezed == distanceFromStartKm ? _self.distanceFromStartKm : distanceFromStartKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
