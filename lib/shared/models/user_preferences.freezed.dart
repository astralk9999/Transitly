// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPreferences {

 String get userId; String get themePaletteId; Map<String, String>? get customColors; String get backgroundId; bool get backgroundEnabled; double get backgroundOpacity; double get fontScale; ColorBlindMode get colorBlindMode; bool get dyslexiaFontEnabled; bool get reduceMotion; bool get highContrast; String get mapStyle; bool get notifIncidentResolved; bool get notifRoutePromoted; bool get notifBusApproaching; bool get notifFeatureRequestReplied; bool get quietHoursEnabled; String? get quietHoursStart; String? get quietHoursEnd; bool get extendedTimers;
/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<UserPreferences> get copyWith => _$UserPreferencesCopyWithImpl<UserPreferences>(this as UserPreferences, _$identity);

  /// Serializes this UserPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferences&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.themePaletteId, themePaletteId) || other.themePaletteId == themePaletteId)&&const DeepCollectionEquality().equals(other.customColors, customColors)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.backgroundEnabled, backgroundEnabled) || other.backgroundEnabled == backgroundEnabled)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.colorBlindMode, colorBlindMode) || other.colorBlindMode == colorBlindMode)&&(identical(other.dyslexiaFontEnabled, dyslexiaFontEnabled) || other.dyslexiaFontEnabled == dyslexiaFontEnabled)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.highContrast, highContrast) || other.highContrast == highContrast)&&(identical(other.mapStyle, mapStyle) || other.mapStyle == mapStyle)&&(identical(other.notifIncidentResolved, notifIncidentResolved) || other.notifIncidentResolved == notifIncidentResolved)&&(identical(other.notifRoutePromoted, notifRoutePromoted) || other.notifRoutePromoted == notifRoutePromoted)&&(identical(other.notifBusApproaching, notifBusApproaching) || other.notifBusApproaching == notifBusApproaching)&&(identical(other.notifFeatureRequestReplied, notifFeatureRequestReplied) || other.notifFeatureRequestReplied == notifFeatureRequestReplied)&&(identical(other.quietHoursEnabled, quietHoursEnabled) || other.quietHoursEnabled == quietHoursEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd)&&(identical(other.extendedTimers, extendedTimers) || other.extendedTimers == extendedTimers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,themePaletteId,const DeepCollectionEquality().hash(customColors),backgroundId,backgroundEnabled,backgroundOpacity,fontScale,colorBlindMode,dyslexiaFontEnabled,reduceMotion,highContrast,mapStyle,notifIncidentResolved,notifRoutePromoted,notifBusApproaching,notifFeatureRequestReplied,quietHoursEnabled,quietHoursStart,quietHoursEnd,extendedTimers]);

@override
String toString() {
  return 'UserPreferences(userId: $userId, themePaletteId: $themePaletteId, customColors: $customColors, backgroundId: $backgroundId, backgroundEnabled: $backgroundEnabled, backgroundOpacity: $backgroundOpacity, fontScale: $fontScale, colorBlindMode: $colorBlindMode, dyslexiaFontEnabled: $dyslexiaFontEnabled, reduceMotion: $reduceMotion, highContrast: $highContrast, mapStyle: $mapStyle, notifIncidentResolved: $notifIncidentResolved, notifRoutePromoted: $notifRoutePromoted, notifBusApproaching: $notifBusApproaching, notifFeatureRequestReplied: $notifFeatureRequestReplied, quietHoursEnabled: $quietHoursEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd, extendedTimers: $extendedTimers)';
}


}

/// @nodoc
abstract mixin class $UserPreferencesCopyWith<$Res>  {
  factory $UserPreferencesCopyWith(UserPreferences value, $Res Function(UserPreferences) _then) = _$UserPreferencesCopyWithImpl;
@useResult
$Res call({
 String userId, String themePaletteId, Map<String, String>? customColors, String backgroundId, bool backgroundEnabled, double backgroundOpacity, double fontScale, ColorBlindMode colorBlindMode, bool dyslexiaFontEnabled, bool reduceMotion, bool highContrast, String mapStyle, bool notifIncidentResolved, bool notifRoutePromoted, bool notifBusApproaching, bool notifFeatureRequestReplied, bool quietHoursEnabled, String? quietHoursStart, String? quietHoursEnd, bool extendedTimers
});




}
/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._self, this._then);

  final UserPreferences _self;
  final $Res Function(UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? themePaletteId = null,Object? customColors = freezed,Object? backgroundId = null,Object? backgroundEnabled = null,Object? backgroundOpacity = null,Object? fontScale = null,Object? colorBlindMode = null,Object? dyslexiaFontEnabled = null,Object? reduceMotion = null,Object? highContrast = null,Object? mapStyle = null,Object? notifIncidentResolved = null,Object? notifRoutePromoted = null,Object? notifBusApproaching = null,Object? notifFeatureRequestReplied = null,Object? quietHoursEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,Object? extendedTimers = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,themePaletteId: null == themePaletteId ? _self.themePaletteId : themePaletteId // ignore: cast_nullable_to_non_nullable
as String,customColors: freezed == customColors ? _self.customColors : customColors // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,backgroundId: null == backgroundId ? _self.backgroundId : backgroundId // ignore: cast_nullable_to_non_nullable
as String,backgroundEnabled: null == backgroundEnabled ? _self.backgroundEnabled : backgroundEnabled // ignore: cast_nullable_to_non_nullable
as bool,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,colorBlindMode: null == colorBlindMode ? _self.colorBlindMode : colorBlindMode // ignore: cast_nullable_to_non_nullable
as ColorBlindMode,dyslexiaFontEnabled: null == dyslexiaFontEnabled ? _self.dyslexiaFontEnabled : dyslexiaFontEnabled // ignore: cast_nullable_to_non_nullable
as bool,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,highContrast: null == highContrast ? _self.highContrast : highContrast // ignore: cast_nullable_to_non_nullable
as bool,mapStyle: null == mapStyle ? _self.mapStyle : mapStyle // ignore: cast_nullable_to_non_nullable
as String,notifIncidentResolved: null == notifIncidentResolved ? _self.notifIncidentResolved : notifIncidentResolved // ignore: cast_nullable_to_non_nullable
as bool,notifRoutePromoted: null == notifRoutePromoted ? _self.notifRoutePromoted : notifRoutePromoted // ignore: cast_nullable_to_non_nullable
as bool,notifBusApproaching: null == notifBusApproaching ? _self.notifBusApproaching : notifBusApproaching // ignore: cast_nullable_to_non_nullable
as bool,notifFeatureRequestReplied: null == notifFeatureRequestReplied ? _self.notifFeatureRequestReplied : notifFeatureRequestReplied // ignore: cast_nullable_to_non_nullable
as bool,quietHoursEnabled: null == quietHoursEnabled ? _self.quietHoursEnabled : quietHoursEnabled // ignore: cast_nullable_to_non_nullable
as bool,quietHoursStart: freezed == quietHoursStart ? _self.quietHoursStart : quietHoursStart // ignore: cast_nullable_to_non_nullable
as String?,quietHoursEnd: freezed == quietHoursEnd ? _self.quietHoursEnd : quietHoursEnd // ignore: cast_nullable_to_non_nullable
as String?,extendedTimers: null == extendedTimers ? _self.extendedTimers : extendedTimers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPreferences].
extension UserPreferencesPatterns on UserPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPreferences value)  $default,){
final _that = this;
switch (_that) {
case _UserPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String themePaletteId,  Map<String, String>? customColors,  String backgroundId,  bool backgroundEnabled,  double backgroundOpacity,  double fontScale,  ColorBlindMode colorBlindMode,  bool dyslexiaFontEnabled,  bool reduceMotion,  bool highContrast,  String mapStyle,  bool notifIncidentResolved,  bool notifRoutePromoted,  bool notifBusApproaching,  bool notifFeatureRequestReplied,  bool quietHoursEnabled,  String? quietHoursStart,  String? quietHoursEnd,  bool extendedTimers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.userId,_that.themePaletteId,_that.customColors,_that.backgroundId,_that.backgroundEnabled,_that.backgroundOpacity,_that.fontScale,_that.colorBlindMode,_that.dyslexiaFontEnabled,_that.reduceMotion,_that.highContrast,_that.mapStyle,_that.notifIncidentResolved,_that.notifRoutePromoted,_that.notifBusApproaching,_that.notifFeatureRequestReplied,_that.quietHoursEnabled,_that.quietHoursStart,_that.quietHoursEnd,_that.extendedTimers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String themePaletteId,  Map<String, String>? customColors,  String backgroundId,  bool backgroundEnabled,  double backgroundOpacity,  double fontScale,  ColorBlindMode colorBlindMode,  bool dyslexiaFontEnabled,  bool reduceMotion,  bool highContrast,  String mapStyle,  bool notifIncidentResolved,  bool notifRoutePromoted,  bool notifBusApproaching,  bool notifFeatureRequestReplied,  bool quietHoursEnabled,  String? quietHoursStart,  String? quietHoursEnd,  bool extendedTimers)  $default,) {final _that = this;
switch (_that) {
case _UserPreferences():
return $default(_that.userId,_that.themePaletteId,_that.customColors,_that.backgroundId,_that.backgroundEnabled,_that.backgroundOpacity,_that.fontScale,_that.colorBlindMode,_that.dyslexiaFontEnabled,_that.reduceMotion,_that.highContrast,_that.mapStyle,_that.notifIncidentResolved,_that.notifRoutePromoted,_that.notifBusApproaching,_that.notifFeatureRequestReplied,_that.quietHoursEnabled,_that.quietHoursStart,_that.quietHoursEnd,_that.extendedTimers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String themePaletteId,  Map<String, String>? customColors,  String backgroundId,  bool backgroundEnabled,  double backgroundOpacity,  double fontScale,  ColorBlindMode colorBlindMode,  bool dyslexiaFontEnabled,  bool reduceMotion,  bool highContrast,  String mapStyle,  bool notifIncidentResolved,  bool notifRoutePromoted,  bool notifBusApproaching,  bool notifFeatureRequestReplied,  bool quietHoursEnabled,  String? quietHoursStart,  String? quietHoursEnd,  bool extendedTimers)?  $default,) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.userId,_that.themePaletteId,_that.customColors,_that.backgroundId,_that.backgroundEnabled,_that.backgroundOpacity,_that.fontScale,_that.colorBlindMode,_that.dyslexiaFontEnabled,_that.reduceMotion,_that.highContrast,_that.mapStyle,_that.notifIncidentResolved,_that.notifRoutePromoted,_that.notifBusApproaching,_that.notifFeatureRequestReplied,_that.quietHoursEnabled,_that.quietHoursStart,_that.quietHoursEnd,_that.extendedTimers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPreferences implements UserPreferences {
  const _UserPreferences({required this.userId, this.themePaletteId = 'default', final  Map<String, String>? customColors, this.backgroundId = 'smoke', this.backgroundEnabled = true, this.backgroundOpacity = 1.0, this.fontScale = 1.0, this.colorBlindMode = ColorBlindMode.none, this.dyslexiaFontEnabled = false, this.reduceMotion = false, this.highContrast = false, this.mapStyle = 'streets', this.notifIncidentResolved = true, this.notifRoutePromoted = true, this.notifBusApproaching = true, this.notifFeatureRequestReplied = true, this.quietHoursEnabled = false, this.quietHoursStart, this.quietHoursEnd, this.extendedTimers = false}): _customColors = customColors;
  factory _UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);

@override final  String userId;
@override@JsonKey() final  String themePaletteId;
 final  Map<String, String>? _customColors;
@override Map<String, String>? get customColors {
  final value = _customColors;
  if (value == null) return null;
  if (_customColors is EqualUnmodifiableMapView) return _customColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  String backgroundId;
@override@JsonKey() final  bool backgroundEnabled;
@override@JsonKey() final  double backgroundOpacity;
@override@JsonKey() final  double fontScale;
@override@JsonKey() final  ColorBlindMode colorBlindMode;
@override@JsonKey() final  bool dyslexiaFontEnabled;
@override@JsonKey() final  bool reduceMotion;
@override@JsonKey() final  bool highContrast;
@override@JsonKey() final  String mapStyle;
@override@JsonKey() final  bool notifIncidentResolved;
@override@JsonKey() final  bool notifRoutePromoted;
@override@JsonKey() final  bool notifBusApproaching;
@override@JsonKey() final  bool notifFeatureRequestReplied;
@override@JsonKey() final  bool quietHoursEnabled;
@override final  String? quietHoursStart;
@override final  String? quietHoursEnd;
@override@JsonKey() final  bool extendedTimers;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesCopyWith<_UserPreferences> get copyWith => __$UserPreferencesCopyWithImpl<_UserPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferences&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.themePaletteId, themePaletteId) || other.themePaletteId == themePaletteId)&&const DeepCollectionEquality().equals(other._customColors, _customColors)&&(identical(other.backgroundId, backgroundId) || other.backgroundId == backgroundId)&&(identical(other.backgroundEnabled, backgroundEnabled) || other.backgroundEnabled == backgroundEnabled)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.colorBlindMode, colorBlindMode) || other.colorBlindMode == colorBlindMode)&&(identical(other.dyslexiaFontEnabled, dyslexiaFontEnabled) || other.dyslexiaFontEnabled == dyslexiaFontEnabled)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.highContrast, highContrast) || other.highContrast == highContrast)&&(identical(other.mapStyle, mapStyle) || other.mapStyle == mapStyle)&&(identical(other.notifIncidentResolved, notifIncidentResolved) || other.notifIncidentResolved == notifIncidentResolved)&&(identical(other.notifRoutePromoted, notifRoutePromoted) || other.notifRoutePromoted == notifRoutePromoted)&&(identical(other.notifBusApproaching, notifBusApproaching) || other.notifBusApproaching == notifBusApproaching)&&(identical(other.notifFeatureRequestReplied, notifFeatureRequestReplied) || other.notifFeatureRequestReplied == notifFeatureRequestReplied)&&(identical(other.quietHoursEnabled, quietHoursEnabled) || other.quietHoursEnabled == quietHoursEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd)&&(identical(other.extendedTimers, extendedTimers) || other.extendedTimers == extendedTimers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,themePaletteId,const DeepCollectionEquality().hash(_customColors),backgroundId,backgroundEnabled,backgroundOpacity,fontScale,colorBlindMode,dyslexiaFontEnabled,reduceMotion,highContrast,mapStyle,notifIncidentResolved,notifRoutePromoted,notifBusApproaching,notifFeatureRequestReplied,quietHoursEnabled,quietHoursStart,quietHoursEnd,extendedTimers]);

@override
String toString() {
  return 'UserPreferences(userId: $userId, themePaletteId: $themePaletteId, customColors: $customColors, backgroundId: $backgroundId, backgroundEnabled: $backgroundEnabled, backgroundOpacity: $backgroundOpacity, fontScale: $fontScale, colorBlindMode: $colorBlindMode, dyslexiaFontEnabled: $dyslexiaFontEnabled, reduceMotion: $reduceMotion, highContrast: $highContrast, mapStyle: $mapStyle, notifIncidentResolved: $notifIncidentResolved, notifRoutePromoted: $notifRoutePromoted, notifBusApproaching: $notifBusApproaching, notifFeatureRequestReplied: $notifFeatureRequestReplied, quietHoursEnabled: $quietHoursEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd, extendedTimers: $extendedTimers)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesCopyWith<$Res> implements $UserPreferencesCopyWith<$Res> {
  factory _$UserPreferencesCopyWith(_UserPreferences value, $Res Function(_UserPreferences) _then) = __$UserPreferencesCopyWithImpl;
@override @useResult
$Res call({
 String userId, String themePaletteId, Map<String, String>? customColors, String backgroundId, bool backgroundEnabled, double backgroundOpacity, double fontScale, ColorBlindMode colorBlindMode, bool dyslexiaFontEnabled, bool reduceMotion, bool highContrast, String mapStyle, bool notifIncidentResolved, bool notifRoutePromoted, bool notifBusApproaching, bool notifFeatureRequestReplied, bool quietHoursEnabled, String? quietHoursStart, String? quietHoursEnd, bool extendedTimers
});




}
/// @nodoc
class __$UserPreferencesCopyWithImpl<$Res>
    implements _$UserPreferencesCopyWith<$Res> {
  __$UserPreferencesCopyWithImpl(this._self, this._then);

  final _UserPreferences _self;
  final $Res Function(_UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? themePaletteId = null,Object? customColors = freezed,Object? backgroundId = null,Object? backgroundEnabled = null,Object? backgroundOpacity = null,Object? fontScale = null,Object? colorBlindMode = null,Object? dyslexiaFontEnabled = null,Object? reduceMotion = null,Object? highContrast = null,Object? mapStyle = null,Object? notifIncidentResolved = null,Object? notifRoutePromoted = null,Object? notifBusApproaching = null,Object? notifFeatureRequestReplied = null,Object? quietHoursEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,Object? extendedTimers = null,}) {
  return _then(_UserPreferences(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,themePaletteId: null == themePaletteId ? _self.themePaletteId : themePaletteId // ignore: cast_nullable_to_non_nullable
as String,customColors: freezed == customColors ? _self._customColors : customColors // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,backgroundId: null == backgroundId ? _self.backgroundId : backgroundId // ignore: cast_nullable_to_non_nullable
as String,backgroundEnabled: null == backgroundEnabled ? _self.backgroundEnabled : backgroundEnabled // ignore: cast_nullable_to_non_nullable
as bool,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,colorBlindMode: null == colorBlindMode ? _self.colorBlindMode : colorBlindMode // ignore: cast_nullable_to_non_nullable
as ColorBlindMode,dyslexiaFontEnabled: null == dyslexiaFontEnabled ? _self.dyslexiaFontEnabled : dyslexiaFontEnabled // ignore: cast_nullable_to_non_nullable
as bool,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,highContrast: null == highContrast ? _self.highContrast : highContrast // ignore: cast_nullable_to_non_nullable
as bool,mapStyle: null == mapStyle ? _self.mapStyle : mapStyle // ignore: cast_nullable_to_non_nullable
as String,notifIncidentResolved: null == notifIncidentResolved ? _self.notifIncidentResolved : notifIncidentResolved // ignore: cast_nullable_to_non_nullable
as bool,notifRoutePromoted: null == notifRoutePromoted ? _self.notifRoutePromoted : notifRoutePromoted // ignore: cast_nullable_to_non_nullable
as bool,notifBusApproaching: null == notifBusApproaching ? _self.notifBusApproaching : notifBusApproaching // ignore: cast_nullable_to_non_nullable
as bool,notifFeatureRequestReplied: null == notifFeatureRequestReplied ? _self.notifFeatureRequestReplied : notifFeatureRequestReplied // ignore: cast_nullable_to_non_nullable
as bool,quietHoursEnabled: null == quietHoursEnabled ? _self.quietHoursEnabled : quietHoursEnabled // ignore: cast_nullable_to_non_nullable
as bool,quietHoursStart: freezed == quietHoursStart ? _self.quietHoursStart : quietHoursStart // ignore: cast_nullable_to_non_nullable
as String?,quietHoursEnd: freezed == quietHoursEnd ? _self.quietHoursEnd : quietHoursEnd // ignore: cast_nullable_to_non_nullable
as String?,extendedTimers: null == extendedTimers ? _self.extendedTimers : extendedTimers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
