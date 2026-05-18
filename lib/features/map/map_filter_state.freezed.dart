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

 bool get showOfficial; bool get showCommunity; Set<String> get activeOperators; Set<String> get activeKinds; int get nextMinutes; bool get onlyAccessible; bool get onlyFavorites; double get radiusMeters;
/// Create a copy of MapFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapFilterStateCopyWith<MapFilterState> get copyWith => _$MapFilterStateCopyWithImpl<MapFilterState>(this as MapFilterState, _$identity);

  /// Serializes this MapFilterState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapFilterState&&(identical(other.showOfficial, showOfficial) || other.showOfficial == showOfficial)&&(identical(other.showCommunity, showCommunity) || other.showCommunity == showCommunity)&&const DeepCollectionEquality().equals(other.activeOperators, activeOperators)&&const DeepCollectionEquality().equals(other.activeKinds, activeKinds)&&(identical(other.nextMinutes, nextMinutes) || other.nextMinutes == nextMinutes)&&(identical(other.onlyAccessible, onlyAccessible) || other.onlyAccessible == onlyAccessible)&&(identical(other.onlyFavorites, onlyFavorites) || other.onlyFavorites == onlyFavorites)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showOfficial,showCommunity,const DeepCollectionEquality().hash(activeOperators),const DeepCollectionEquality().hash(activeKinds),nextMinutes,onlyAccessible,onlyFavorites,radiusMeters);

@override
String toString() {
  return 'MapFilterState(showOfficial: $showOfficial, showCommunity: $showCommunity, activeOperators: $activeOperators, activeKinds: $activeKinds, nextMinutes: $nextMinutes, onlyAccessible: $onlyAccessible, onlyFavorites: $onlyFavorites, radiusMeters: $radiusMeters)';
}


}

/// @nodoc
abstract mixin class $MapFilterStateCopyWith<$Res>  {
  factory $MapFilterStateCopyWith(MapFilterState value, $Res Function(MapFilterState) _then) = _$MapFilterStateCopyWithImpl;
@useResult
$Res call({
 bool showOfficial, bool showCommunity, Set<String> activeOperators, Set<String> activeKinds, int nextMinutes, bool onlyAccessible, bool onlyFavorites, double radiusMeters
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
@pragma('vm:prefer-inline') @override $Res call({Object? showOfficial = null,Object? showCommunity = null,Object? activeOperators = null,Object? activeKinds = null,Object? nextMinutes = null,Object? onlyAccessible = null,Object? onlyFavorites = null,Object? radiusMeters = null,}) {
  return _then(_self.copyWith(
showOfficial: null == showOfficial ? _self.showOfficial : showOfficial // ignore: cast_nullable_to_non_nullable
as bool,showCommunity: null == showCommunity ? _self.showCommunity : showCommunity // ignore: cast_nullable_to_non_nullable
as bool,activeOperators: null == activeOperators ? _self.activeOperators : activeOperators // ignore: cast_nullable_to_non_nullable
as Set<String>,activeKinds: null == activeKinds ? _self.activeKinds : activeKinds // ignore: cast_nullable_to_non_nullable
as Set<String>,nextMinutes: null == nextMinutes ? _self.nextMinutes : nextMinutes // ignore: cast_nullable_to_non_nullable
as int,onlyAccessible: null == onlyAccessible ? _self.onlyAccessible : onlyAccessible // ignore: cast_nullable_to_non_nullable
as bool,onlyFavorites: null == onlyFavorites ? _self.onlyFavorites : onlyFavorites // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showOfficial,  bool showCommunity,  Set<String> activeOperators,  Set<String> activeKinds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  double radiusMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
return $default(_that.showOfficial,_that.showCommunity,_that.activeOperators,_that.activeKinds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.radiusMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showOfficial,  bool showCommunity,  Set<String> activeOperators,  Set<String> activeKinds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  double radiusMeters)  $default,) {final _that = this;
switch (_that) {
case _MapFilterState():
return $default(_that.showOfficial,_that.showCommunity,_that.activeOperators,_that.activeKinds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.radiusMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showOfficial,  bool showCommunity,  Set<String> activeOperators,  Set<String> activeKinds,  int nextMinutes,  bool onlyAccessible,  bool onlyFavorites,  double radiusMeters)?  $default,) {final _that = this;
switch (_that) {
case _MapFilterState() when $default != null:
return $default(_that.showOfficial,_that.showCommunity,_that.activeOperators,_that.activeKinds,_that.nextMinutes,_that.onlyAccessible,_that.onlyFavorites,_that.radiusMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MapFilterState implements MapFilterState {
  const _MapFilterState({this.showOfficial = true, this.showCommunity = true, final  Set<String> activeOperators = const <String>{}, final  Set<String> activeKinds = const <String>{}, this.nextMinutes = 0, this.onlyAccessible = false, this.onlyFavorites = false, this.radiusMeters = 5000}): _activeOperators = activeOperators,_activeKinds = activeKinds;
  factory _MapFilterState.fromJson(Map<String, dynamic> json) => _$MapFilterStateFromJson(json);

@override@JsonKey() final  bool showOfficial;
@override@JsonKey() final  bool showCommunity;
 final  Set<String> _activeOperators;
@override@JsonKey() Set<String> get activeOperators {
  if (_activeOperators is EqualUnmodifiableSetView) return _activeOperators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeOperators);
}

 final  Set<String> _activeKinds;
@override@JsonKey() Set<String> get activeKinds {
  if (_activeKinds is EqualUnmodifiableSetView) return _activeKinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeKinds);
}

@override@JsonKey() final  int nextMinutes;
@override@JsonKey() final  bool onlyAccessible;
@override@JsonKey() final  bool onlyFavorites;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapFilterState&&(identical(other.showOfficial, showOfficial) || other.showOfficial == showOfficial)&&(identical(other.showCommunity, showCommunity) || other.showCommunity == showCommunity)&&const DeepCollectionEquality().equals(other._activeOperators, _activeOperators)&&const DeepCollectionEquality().equals(other._activeKinds, _activeKinds)&&(identical(other.nextMinutes, nextMinutes) || other.nextMinutes == nextMinutes)&&(identical(other.onlyAccessible, onlyAccessible) || other.onlyAccessible == onlyAccessible)&&(identical(other.onlyFavorites, onlyFavorites) || other.onlyFavorites == onlyFavorites)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showOfficial,showCommunity,const DeepCollectionEquality().hash(_activeOperators),const DeepCollectionEquality().hash(_activeKinds),nextMinutes,onlyAccessible,onlyFavorites,radiusMeters);

@override
String toString() {
  return 'MapFilterState(showOfficial: $showOfficial, showCommunity: $showCommunity, activeOperators: $activeOperators, activeKinds: $activeKinds, nextMinutes: $nextMinutes, onlyAccessible: $onlyAccessible, onlyFavorites: $onlyFavorites, radiusMeters: $radiusMeters)';
}


}

/// @nodoc
abstract mixin class _$MapFilterStateCopyWith<$Res> implements $MapFilterStateCopyWith<$Res> {
  factory _$MapFilterStateCopyWith(_MapFilterState value, $Res Function(_MapFilterState) _then) = __$MapFilterStateCopyWithImpl;
@override @useResult
$Res call({
 bool showOfficial, bool showCommunity, Set<String> activeOperators, Set<String> activeKinds, int nextMinutes, bool onlyAccessible, bool onlyFavorites, double radiusMeters
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
@override @pragma('vm:prefer-inline') $Res call({Object? showOfficial = null,Object? showCommunity = null,Object? activeOperators = null,Object? activeKinds = null,Object? nextMinutes = null,Object? onlyAccessible = null,Object? onlyFavorites = null,Object? radiusMeters = null,}) {
  return _then(_MapFilterState(
showOfficial: null == showOfficial ? _self.showOfficial : showOfficial // ignore: cast_nullable_to_non_nullable
as bool,showCommunity: null == showCommunity ? _self.showCommunity : showCommunity // ignore: cast_nullable_to_non_nullable
as bool,activeOperators: null == activeOperators ? _self._activeOperators : activeOperators // ignore: cast_nullable_to_non_nullable
as Set<String>,activeKinds: null == activeKinds ? _self._activeKinds : activeKinds // ignore: cast_nullable_to_non_nullable
as Set<String>,nextMinutes: null == nextMinutes ? _self.nextMinutes : nextMinutes // ignore: cast_nullable_to_non_nullable
as int,onlyAccessible: null == onlyAccessible ? _self.onlyAccessible : onlyAccessible // ignore: cast_nullable_to_non_nullable
as bool,onlyFavorites: null == onlyFavorites ? _self.onlyFavorites : onlyFavorites // ignore: cast_nullable_to_non_nullable
as bool,radiusMeters: null == radiusMeters ? _self.radiusMeters : radiusMeters // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
