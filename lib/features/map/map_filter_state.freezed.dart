// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapFilterState {

 bool get showOfficial; bool get showCommunity; Set<String> get disabledOperators; Set<String> get disabledKinds; Set<String> get disabledLines; Set<String> get disabledZones; Set<String> get disabledRouteIds; int get nextMinutes; bool get onlyAccessible; bool get onlyFavorites; bool get showAllStops; double get radiusMeters;
/// Create a copy of MapFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapFilterStateCopyWith<MapFilterState> get copyWith => _$MapFilterStateCopyWithImpl<MapFilterState>(this as MapFilterState, _$identity);

  /// Serializes this MapFilterState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapFilterState&&(identical(other.showOfficial, showOfficial) || other.showOfficial == showOfficial)&&(identical(other.showCommunity, showCommunity) || other.showCommunity == showCommunity)&&const DeepCollectionEquality().equals(other.disabledOperators, disabledOperators)&&const DeepCollectionEquality().equals(other.disabledKinds, disabledKinds)&&const DeepCollectionEquality().equals(other.disabledLines, disabledLines)&&const DeepCollectionEquality().equals(other.disabledZones, disabledZones)&&const DeepCollectionEquality().equals(other.disabledRouteIds, disabledRouteIds)&&(identical(other.nextMinutes, nextMinutes) || other.nextMinutes == nextMinutes)&&(identical(other.onlyAccessible, onlyAccessible) || other.onlyAccessible == onlyAccessible)&&(identical(other.onlyFavorites, onlyFavorites) || other.onlyFavorites == onlyFavorites)&&(identical(other.showAllStops, showAllStops) || other.showAllStops == showAllStops)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showOfficial,showCommunity,const DeepCollectionEquality().hash(disabledOperators),const DeepCollectionEquality().hash(disabledKinds),const DeepCollectionEquality().hash(disabledLines),const DeepCollectionEquality().hash(disabledZones),const DeepCollectionEquality().hash(disabledRouteIds),nextMinutes,onlyAccessible,onlyFavorites,showAllStops,radiusMeters);

@override
String toString() {
  return 'MapFilterState(showOfficial: $showOfficial, showCommunity: $showCommunity, disabledOperators: $disabledOperators, disabledKinds: $disabledKinds, disabledLines: $disabledLines, disabledZones: $disabledZones, disabledRouteIds: $disabledRouteIds, nextMinutes: $nextMinutes, onlyAccessible: $onlyAccessible, onlyFavorites: $onlyFavorites, showAllStops: $showAllStops, radiusMeters: $radiusMeters)';
}


}

/// @nodoc
abstract mixin class $MapFilterStateCopyWith<$Res>  {
  factory $MapFilterStateCopyWith(MapFilterState value, $Res Function(MapFilterState) _then) = _$MapFilterStateCopyWithImpl;
@useResult
$Res call({
 bool showOfficial, bool showCommunity, Set<String> disabledOperators, Set<String> disabledKinds, Set<String> disabledLines, Set<String> disabledZones, Set<String> disabledRouteIds, int nextMinutes, bool onlyAccessible, bool onlyFavorites, bool showAllStops, double radiusMeters
});




}
/// @nodoc
class _$MapFilterStateCopyWithImpl<$Res>
    implements $MapFilterStateCopyWith<$Res> {
  _$MapFilterStateCopyWithImpl(this._self, this._then);

  final MapFilterState _self;
  final $Res Function(MapFilterState) _then;

/// Create a copy of MapFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showOfficial = null,Object? showCommunity = null,Object? disabledOperators = null,Object? disabledKinds = null,Object? disabledLines = null,Object? disabledZones = null,Object? disabledRouteIds = null,Object? nextMinutes = null,Object? onlyAccessible = null,Object? onlyFavorites = null,Object? showAllStops = null,Object? radiusMeters = null,}) {
  return _then(_self.copyWith(
showOfficial: null == showOfficial ? _self.showOfficial : showOfficial // ignore: cast_nullable_to_non_nullable
as bool,showCommunity: null == showCommunity ? _self.showCommunity : showCommunity // ignore: cast_nullable_to_non_nullable
as bool,disabledOperators: null == disabledOperators ? _self.disabledOperators : disabledOperators // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledKinds: null == disabledKinds ? _self.disabledKinds : disabledKinds // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledLines: null == disabledLines ? _self.disabledLines : disabledLines // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledZones: null == disabledZones ? _self.disabledZones : disabledZones // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledRouteIds: null == disabledRouteIds ? _self.disabledRouteIds : disabledRouteIds // ignore: cast_nullable_to_non_nullable
as Set<String>,nextMinutes: null == nextMinutes ? _self.nextMinutes : nextMinutes // ignore: cast_nullable_to_non_nullable
as int,onlyAccessible: null == onlyAccessible ? _self.onlyAccessible : onlyAccessible // ignore: cast_nullable_to_non_nullable
as bool,onlyFavorites: null == onlyFavorites ? _self.onlyFavorites : onlyFavorites // ignore: cast_nullable_to_non_nullable
as bool,showAllStops: null == showAllStops ? _self.showAllStops : showAllStops // ignore: cast_nullable_to_non_nullable
as bool,radiusMeters: null == radiusMeters ? _self.radiusMeters : radiusMeters // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MapFilterState].
extension MapFilterStatePatterns on MapFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapFilterState value)  $default,){
final _that = this;
switch (_that) {
case _MapFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showOfficial,  bool showCommunity,  Set<String> disabledOperators,  Set<String> disabledKinds,  Set<String> disabledLines,  Set<String> disabledZones,  Set<String> disabledRouteIds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  bool showAllStops,  double radiusMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
return $default(_that.showOfficial,_that.showCommunity,_that.disabledOperators,_that.disabledKinds,_that.disabledLines,_that.disabledZones,_that.disabledRouteIds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.showAllStops,_that.radiusMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showOfficial,  bool showCommunity,  Set<String> disabledOperators,  Set<String> disabledKinds,  Set<String> disabledLines,  Set<String> disabledZones,  Set<String> disabledRouteIds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  bool showAllStops,  double radiusMeters)  $default,) {final _that = this;
switch (_that) {
case _MapFilterState():
return $default(_that.showOfficial,_that.showCommunity,_that.disabledOperators,_that.disabledKinds,_that.disabledLines,_that.disabledZones,_that.disabledRouteIds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.showAllStops,_that.radiusMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showOfficial,  bool showCommunity,  Set<String> disabledOperators,  Set<String> disabledKinds,  Set<String> disabledLines,  Set<String> disabledZones,  Set<String> disabledRouteIds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  bool showAllStops,  double radiusMeters)?  $default,) {final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
return $default(_that.showOfficial,_that.showCommunity,_that.disabledOperators,_that.disabledKinds,_that.disabledLines,_that.disabledZones,_that.disabledRouteIds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.showAllStops,_that.radiusMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MapFilterState implements MapFilterState {
  const _MapFilterState({this.showOfficial = true, this.showCommunity = true, final  Set<String> disabledOperators = const <String>{}, final  Set<String> disabledKinds = const <String>{}, final  Set<String> disabledLines = const <String>{}, final  Set<String> disabledZones = const <String>{}, final  Set<String> disabledRouteIds = const <String>{}, this.nextMinutes = 0, this.onlyAccessible = false, this.onlyFavorites = false, this.showAllStops = false, this.radiusMeters = 5000}): _disabledOperators = disabledOperators,_disabledKinds = disabledKinds,_disabledLines = disabledLines,_disabledZones = disabledZones,_disabledRouteIds = disabledRouteIds;
  factory _MapFilterState.fromJson(Map<String, dynamic> json) => _$MapFilterStateFromJson(json);

@override@JsonKey() final  bool showOfficial;
@override@JsonKey() final  bool showCommunity;
 final  Set<String> _disabledOperators;
@override@JsonKey() Set<String> get disabledOperators {
  if (_disabledOperators is EqualUnmodifiableSetView) return _disabledOperators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledOperators);
}

 final  Set<String> _disabledKinds;
@override@JsonKey() Set<String> get disabledKinds {
  if (_disabledKinds is EqualUnmodifiableSetView) return _disabledKinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledKinds);
}

 final  Set<String> _disabledLines;
@override@JsonKey() Set<String> get disabledLines {
  if (_disabledLines is EqualUnmodifiableSetView) return _disabledLines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledLines);
}

 final  Set<String> _disabledZones;
@override@JsonKey() Set<String> get disabledZones {
  if (_disabledZones is EqualUnmodifiableSetView) return _disabledZones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledZones);
}

 final  Set<String> _disabledRouteIds;
@override@JsonKey() Set<String> get disabledRouteIds {
  if (_disabledRouteIds is EqualUnmodifiableSetView) return _disabledRouteIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledRouteIds);
}

@override@JsonKey() final  int nextMinutes;
@override@JsonKey() final  bool onlyAccessible;
@override@JsonKey() final  bool onlyFavorites;
@override@JsonKey() final  bool showAllStops;
@override@JsonKey() final  double radiusMeters;

/// Create a copy of MapFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapFilterStateCopyWith<_MapFilterState> get copyWith => __$MapFilterStateCopyWithImpl<_MapFilterState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapFilterStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapFilterState&&(identical(other.showOfficial, showOfficial) || other.showOfficial == showOfficial)&&(identical(other.showCommunity, showCommunity) || other.showCommunity == showCommunity)&&const DeepCollectionEquality().equals(other._disabledOperators, _disabledOperators)&&const DeepCollectionEquality().equals(other._disabledKinds, _disabledKinds)&&const DeepCollectionEquality().equals(other._disabledLines, _disabledLines)&&const DeepCollectionEquality().equals(other._disabledZones, _disabledZones)&&const DeepCollectionEquality().equals(other._disabledRouteIds, _disabledRouteIds)&&(identical(other.nextMinutes, nextMinutes) || other.nextMinutes == nextMinutes)&&(identical(other.onlyAccessible, onlyAccessible) || other.onlyAccessible == onlyAccessible)&&(identical(other.onlyFavorites, onlyFavorites) || other.onlyFavorites == onlyFavorites)&&(identical(other.showAllStops, showAllStops) || other.showAllStops == showAllStops)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showOfficial,showCommunity,const DeepCollectionEquality().hash(_disabledOperators),const DeepCollectionEquality().hash(_disabledKinds),const DeepCollectionEquality().hash(_disabledLines),const DeepCollectionEquality().hash(_disabledZones),const DeepCollectionEquality().hash(_disabledRouteIds),nextMinutes,onlyAccessible,onlyFavorites,showAllStops,radiusMeters);

@override
String toString() {
  return 'MapFilterState(showOfficial: $showOfficial, showCommunity: $showCommunity, disabledOperators: $disabledOperators, disabledKinds: $disabledKinds, disabledLines: $disabledLines, disabledZones: $disabledZones, disabledRouteIds: $disabledRouteIds, nextMinutes: $nextMinutes, onlyAccessible: $onlyAccessible, onlyFavorites: $onlyFavorites, showAllStops: $showAllStops, radiusMeters: $radiusMeters)';
}


}

/// @nodoc
abstract mixin class _$MapFilterStateCopyWith<$Res> implements $MapFilterStateCopyWith<$Res> {
  factory _$MapFilterStateCopyWith(_MapFilterState value, $Res Function(_MapFilterState) _then) = __$MapFilterStateCopyWithImpl;
@override @useResult
$Res call({
 bool showOfficial, bool showCommunity, Set<String> disabledOperators, Set<String> disabledKinds, Set<String> disabledLines, Set<String> disabledZones, Set<String> disabledRouteIds, int nextMinutes, bool onlyAccessible, bool onlyFavorites, bool showAllStops, double radiusMeters
});




}
/// @nodoc
class __$MapFilterStateCopyWithImpl<$Res>
    implements _$MapFilterStateCopyWith<$Res> {
  __$MapFilterStateCopyWithImpl(this._self, this._then);

  final _MapFilterState _self;
  final $Res Function(_MapFilterState) _then;

/// Create a copy of MapFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showOfficial = null,Object? showCommunity = null,Object? disabledOperators = null,Object? disabledKinds = null,Object? disabledLines = null,Object? disabledZones = null,Object? disabledRouteIds = null,Object? nextMinutes = null,Object? onlyAccessible = null,Object? onlyFavorites = null,Object? showAllStops = null,Object? radiusMeters = null,}) {
  return _then(_MapFilterState(
showOfficial: null == showOfficial ? _self.showOfficial : showOfficial // ignore: cast_nullable_to_non_nullable
as bool,showCommunity: null == showCommunity ? _self.showCommunity : showCommunity // ignore: cast_nullable_to_non_nullable
as bool,disabledOperators: null == disabledOperators ? _self._disabledOperators : disabledOperators // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledKinds: null == disabledKinds ? _self._disabledKinds : disabledKinds // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledLines: null == disabledLines ? _self._disabledLines : disabledLines // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledZones: null == disabledZones ? _self._disabledZones : disabledZones // ignore: cast_nullable_to_non_nullable
as Set<String>,disabledRouteIds: null == disabledRouteIds ? _self._disabledRouteIds : disabledRouteIds // ignore: cast_nullable_to_non_nullable
as Set<String>,nextMinutes: null == nextMinutes ? _self.nextMinutes : nextMinutes // ignore: cast_nullable_to_non_nullable
as int,onlyAccessible: null == onlyAccessible ? _self.onlyAccessible : onlyAccessible // ignore: cast_nullable_to_non_nullable
as bool,onlyFavorites: null == onlyFavorites ? _self.onlyFavorites : onlyFavorites // ignore: cast_nullable_to_non_nullable
as bool,showAllStops: null == showAllStops ? _self.showAllStops : showAllStops // ignore: cast_nullable_to_non_nullable
as bool,radiusMeters: null == radiusMeters ? _self.radiusMeters : radiusMeters // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
