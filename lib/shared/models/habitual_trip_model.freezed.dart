// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habitual_trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HabitualTripModel {

 String get id; String get userId; String get routeId; String get stopId; String? get destinationStopId; String? get timeWindowStart; String? get timeWindowEnd; List<int> get daysOfWeek; bool get notify; int get notifyMinutesBefore;
/// Create a copy of HabitualTripModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitualTripModelCopyWith<HabitualTripModel> get copyWith => _$HabitualTripModelCopyWithImpl<HabitualTripModel>(this as HabitualTripModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitualTripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.destinationStopId, destinationStopId) || other.destinationStopId == destinationStopId)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.notify, notify) || other.notify == notify)&&(identical(other.notifyMinutesBefore, notifyMinutesBefore) || other.notifyMinutesBefore == notifyMinutesBefore));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,stopId,destinationStopId,timeWindowStart,timeWindowEnd,const DeepCollectionEquality().hash(daysOfWeek),notify,notifyMinutesBefore);

@override
String toString() {
  return 'HabitualTripModel(id: $id, userId: $userId, routeId: $routeId, stopId: $stopId, destinationStopId: $destinationStopId, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, daysOfWeek: $daysOfWeek, notify: $notify, notifyMinutesBefore: $notifyMinutesBefore)';
}


}

/// @nodoc
abstract mixin class $HabitualTripModelCopyWith<$Res>  {
  factory $HabitualTripModelCopyWith(HabitualTripModel value, $Res Function(HabitualTripModel) _then) = _$HabitualTripModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String routeId, String stopId, String? destinationStopId, String? timeWindowStart, String? timeWindowEnd, List<int> daysOfWeek, bool notify, int notifyMinutesBefore
});




}
/// @nodoc
class _$HabitualTripModelCopyWithImpl<$Res>
    implements $HabitualTripModelCopyWith<$Res> {
  _$HabitualTripModelCopyWithImpl(this._self, this._then);

  final HabitualTripModel _self;
  final $Res Function(HabitualTripModel) _then;

/// Create a copy of HabitualTripModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? stopId = null,Object? destinationStopId = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? daysOfWeek = null,Object? notify = null,Object? notifyMinutesBefore = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: null == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String,destinationStopId: freezed == destinationStopId ? _self.destinationStopId : destinationStopId // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,notify: null == notify ? _self.notify : notify // ignore: cast_nullable_to_non_nullable
as bool,notifyMinutesBefore: null == notifyMinutesBefore ? _self.notifyMinutesBefore : notifyMinutesBefore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitualTripModel].
extension HabitualTripModelPatterns on HabitualTripModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitualTripModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitualTripModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitualTripModel value)  $default,){
final _that = this;
switch (_that) {
case _HabitualTripModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitualTripModel value)?  $default,){
final _that = this;
switch (_that) {
case _HabitualTripModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String stopId,  String? destinationStopId,  String? timeWindowStart,  String? timeWindowEnd,  List<int> daysOfWeek,  bool notify,  int notifyMinutesBefore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitualTripModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.destinationStopId,_that.timeWindowStart,_that.timeWindowEnd,_that.daysOfWeek,_that.notify,_that.notifyMinutesBefore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String routeId,  String stopId,  String? destinationStopId,  String? timeWindowStart,  String? timeWindowEnd,  List<int> daysOfWeek,  bool notify,  int notifyMinutesBefore)  $default,) {final _that = this;
switch (_that) {
case _HabitualTripModel():
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.destinationStopId,_that.timeWindowStart,_that.timeWindowEnd,_that.daysOfWeek,_that.notify,_that.notifyMinutesBefore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String routeId,  String stopId,  String? destinationStopId,  String? timeWindowStart,  String? timeWindowEnd,  List<int> daysOfWeek,  bool notify,  int notifyMinutesBefore)?  $default,) {final _that = this;
switch (_that) {
case _HabitualTripModel() when $default != null:
return $default(_that.id,_that.userId,_that.routeId,_that.stopId,_that.destinationStopId,_that.timeWindowStart,_that.timeWindowEnd,_that.daysOfWeek,_that.notify,_that.notifyMinutesBefore);case _:
  return null;

}
}

}

/// @nodoc


class _HabitualTripModel extends HabitualTripModel {
  const _HabitualTripModel({required this.id, required this.userId, required this.routeId, required this.stopId, this.destinationStopId, this.timeWindowStart, this.timeWindowEnd, final  List<int> daysOfWeek = const [], this.notify = false, this.notifyMinutesBefore = 5}): _daysOfWeek = daysOfWeek,super._();
  

@override final  String id;
@override final  String userId;
@override final  String routeId;
@override final  String stopId;
@override final  String? destinationStopId;
@override final  String? timeWindowStart;
@override final  String? timeWindowEnd;
 final  List<int> _daysOfWeek;
@override@JsonKey() List<int> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

@override@JsonKey() final  bool notify;
@override@JsonKey() final  int notifyMinutesBefore;

/// Create a copy of HabitualTripModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitualTripModelCopyWith<_HabitualTripModel> get copyWith => __$HabitualTripModelCopyWithImpl<_HabitualTripModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitualTripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.destinationStopId, destinationStopId) || other.destinationStopId == destinationStopId)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.notify, notify) || other.notify == notify)&&(identical(other.notifyMinutesBefore, notifyMinutesBefore) || other.notifyMinutesBefore == notifyMinutesBefore));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routeId,stopId,destinationStopId,timeWindowStart,timeWindowEnd,const DeepCollectionEquality().hash(_daysOfWeek),notify,notifyMinutesBefore);

@override
String toString() {
  return 'HabitualTripModel(id: $id, userId: $userId, routeId: $routeId, stopId: $stopId, destinationStopId: $destinationStopId, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, daysOfWeek: $daysOfWeek, notify: $notify, notifyMinutesBefore: $notifyMinutesBefore)';
}


}

/// @nodoc
abstract mixin class _$HabitualTripModelCopyWith<$Res> implements $HabitualTripModelCopyWith<$Res> {
  factory _$HabitualTripModelCopyWith(_HabitualTripModel value, $Res Function(_HabitualTripModel) _then) = __$HabitualTripModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String routeId, String stopId, String? destinationStopId, String? timeWindowStart, String? timeWindowEnd, List<int> daysOfWeek, bool notify, int notifyMinutesBefore
});




}
/// @nodoc
class __$HabitualTripModelCopyWithImpl<$Res>
    implements _$HabitualTripModelCopyWith<$Res> {
  __$HabitualTripModelCopyWithImpl(this._self, this._then);

  final _HabitualTripModel _self;
  final $Res Function(_HabitualTripModel) _then;

/// Create a copy of HabitualTripModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? routeId = null,Object? stopId = null,Object? destinationStopId = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? daysOfWeek = null,Object? notify = null,Object? notifyMinutesBefore = null,}) {
  return _then(_HabitualTripModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,stopId: null == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String,destinationStopId: freezed == destinationStopId ? _self.destinationStopId : destinationStopId // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,notify: null == notify ? _self.notify : notify // ignore: cast_nullable_to_non_nullable
as bool,notifyMinutesBefore: null == notifyMinutesBefore ? _self.notifyMinutesBefore : notifyMinutesBefore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
