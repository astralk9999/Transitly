// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) {
  return _UserPreferences.fromJson(json);
}

/// @nodoc
mixin _$UserPreferences {
  String get userId => throw _privateConstructorUsedError;
  String get themePaletteId => throw _privateConstructorUsedError;
  Map<String, String>? get customColors => throw _privateConstructorUsedError;
  String get backgroundId => throw _privateConstructorUsedError;
  bool get backgroundEnabled => throw _privateConstructorUsedError;
  double get backgroundOpacity => throw _privateConstructorUsedError;
  double get fontScale => throw _privateConstructorUsedError;
  ColorBlindMode get colorBlindMode => throw _privateConstructorUsedError;
  bool get dyslexiaFontEnabled => throw _privateConstructorUsedError;
  bool get reduceMotion => throw _privateConstructorUsedError;

  /// Serializes this UserPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserPreferencesCopyWith<UserPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPreferencesCopyWith<$Res> {
  factory $UserPreferencesCopyWith(
    UserPreferences value,
    $Res Function(UserPreferences) then,
  ) = _$UserPreferencesCopyWithImpl<$Res, UserPreferences>;
  @useResult
  $Res call({
    String userId,
    String themePaletteId,
    Map<String, String>? customColors,
    String backgroundId,
    bool backgroundEnabled,
    double backgroundOpacity,
    double fontScale,
    ColorBlindMode colorBlindMode,
    bool dyslexiaFontEnabled,
    bool reduceMotion,
  });
}

/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res, $Val extends UserPreferences>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? themePaletteId = null,
    Object? customColors = freezed,
    Object? backgroundId = null,
    Object? backgroundEnabled = null,
    Object? backgroundOpacity = null,
    Object? fontScale = null,
    Object? colorBlindMode = null,
    Object? dyslexiaFontEnabled = null,
    Object? reduceMotion = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            themePaletteId: null == themePaletteId
                ? _value.themePaletteId
                : themePaletteId // ignore: cast_nullable_to_non_nullable
                      as String,
            customColors: freezed == customColors
                ? _value.customColors
                : customColors // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>?,
            backgroundId: null == backgroundId
                ? _value.backgroundId
                : backgroundId // ignore: cast_nullable_to_non_nullable
                      as String,
            backgroundEnabled: null == backgroundEnabled
                ? _value.backgroundEnabled
                : backgroundEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            backgroundOpacity: null == backgroundOpacity
                ? _value.backgroundOpacity
                : backgroundOpacity // ignore: cast_nullable_to_non_nullable
                      as double,
            fontScale: null == fontScale
                ? _value.fontScale
                : fontScale // ignore: cast_nullable_to_non_nullable
                      as double,
            colorBlindMode: null == colorBlindMode
                ? _value.colorBlindMode
                : colorBlindMode // ignore: cast_nullable_to_non_nullable
                      as ColorBlindMode,
            dyslexiaFontEnabled: null == dyslexiaFontEnabled
                ? _value.dyslexiaFontEnabled
                : dyslexiaFontEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            reduceMotion: null == reduceMotion
                ? _value.reduceMotion
                : reduceMotion // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserPreferencesImplCopyWith<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  factory _$$UserPreferencesImplCopyWith(
    _$UserPreferencesImpl value,
    $Res Function(_$UserPreferencesImpl) then,
  ) = __$$UserPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String themePaletteId,
    Map<String, String>? customColors,
    String backgroundId,
    bool backgroundEnabled,
    double backgroundOpacity,
    double fontScale,
    ColorBlindMode colorBlindMode,
    bool dyslexiaFontEnabled,
    bool reduceMotion,
  });
}

/// @nodoc
class __$$UserPreferencesImplCopyWithImpl<$Res>
    extends _$UserPreferencesCopyWithImpl<$Res, _$UserPreferencesImpl>
    implements _$$UserPreferencesImplCopyWith<$Res> {
  __$$UserPreferencesImplCopyWithImpl(
    _$UserPreferencesImpl _value,
    $Res Function(_$UserPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? themePaletteId = null,
    Object? customColors = freezed,
    Object? backgroundId = null,
    Object? backgroundEnabled = null,
    Object? backgroundOpacity = null,
    Object? fontScale = null,
    Object? colorBlindMode = null,
    Object? dyslexiaFontEnabled = null,
    Object? reduceMotion = null,
  }) {
    return _then(
      _$UserPreferencesImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        themePaletteId: null == themePaletteId
            ? _value.themePaletteId
            : themePaletteId // ignore: cast_nullable_to_non_nullable
                  as String,
        customColors: freezed == customColors
            ? _value._customColors
            : customColors // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>?,
        backgroundId: null == backgroundId
            ? _value.backgroundId
            : backgroundId // ignore: cast_nullable_to_non_nullable
                  as String,
        backgroundEnabled: null == backgroundEnabled
            ? _value.backgroundEnabled
            : backgroundEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        backgroundOpacity: null == backgroundOpacity
            ? _value.backgroundOpacity
            : backgroundOpacity // ignore: cast_nullable_to_non_nullable
                  as double,
        fontScale: null == fontScale
            ? _value.fontScale
            : fontScale // ignore: cast_nullable_to_non_nullable
                  as double,
        colorBlindMode: null == colorBlindMode
            ? _value.colorBlindMode
            : colorBlindMode // ignore: cast_nullable_to_non_nullable
                  as ColorBlindMode,
        dyslexiaFontEnabled: null == dyslexiaFontEnabled
            ? _value.dyslexiaFontEnabled
            : dyslexiaFontEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        reduceMotion: null == reduceMotion
            ? _value.reduceMotion
            : reduceMotion // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPreferencesImpl implements _UserPreferences {
  const _$UserPreferencesImpl({
    required this.userId,
    this.themePaletteId = 'default',
    final Map<String, String>? customColors,
    this.backgroundId = 'smoke',
    this.backgroundEnabled = true,
    this.backgroundOpacity = 1.0,
    this.fontScale = 1.0,
    this.colorBlindMode = ColorBlindMode.none,
    this.dyslexiaFontEnabled = false,
    this.reduceMotion = false,
  }) : _customColors = customColors;

  factory _$UserPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPreferencesImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final String themePaletteId;
  final Map<String, String>? _customColors;
  @override
  Map<String, String>? get customColors {
    final value = _customColors;
    if (value == null) return null;
    if (_customColors is EqualUnmodifiableMapView) return _customColors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final String backgroundId;
  @override
  @JsonKey()
  final bool backgroundEnabled;
  @override
  @JsonKey()
  final double backgroundOpacity;
  @override
  @JsonKey()
  final double fontScale;
  @override
  @JsonKey()
  final ColorBlindMode colorBlindMode;
  @override
  @JsonKey()
  final bool dyslexiaFontEnabled;
  @override
  @JsonKey()
  final bool reduceMotion;

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, themePaletteId: $themePaletteId, customColors: $customColors, backgroundId: $backgroundId, backgroundEnabled: $backgroundEnabled, backgroundOpacity: $backgroundOpacity, fontScale: $fontScale, colorBlindMode: $colorBlindMode, dyslexiaFontEnabled: $dyslexiaFontEnabled, reduceMotion: $reduceMotion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPreferencesImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.themePaletteId, themePaletteId) ||
                other.themePaletteId == themePaletteId) &&
            const DeepCollectionEquality().equals(
              other._customColors,
              _customColors,
            ) &&
            (identical(other.backgroundId, backgroundId) ||
                other.backgroundId == backgroundId) &&
            (identical(other.backgroundEnabled, backgroundEnabled) ||
                other.backgroundEnabled == backgroundEnabled) &&
            (identical(other.backgroundOpacity, backgroundOpacity) ||
                other.backgroundOpacity == backgroundOpacity) &&
            (identical(other.fontScale, fontScale) ||
                other.fontScale == fontScale) &&
            (identical(other.colorBlindMode, colorBlindMode) ||
                other.colorBlindMode == colorBlindMode) &&
            (identical(other.dyslexiaFontEnabled, dyslexiaFontEnabled) ||
                other.dyslexiaFontEnabled == dyslexiaFontEnabled) &&
            (identical(other.reduceMotion, reduceMotion) ||
                other.reduceMotion == reduceMotion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    themePaletteId,
    const DeepCollectionEquality().hash(_customColors),
    backgroundId,
    backgroundEnabled,
    backgroundOpacity,
    fontScale,
    colorBlindMode,
    dyslexiaFontEnabled,
    reduceMotion,
  );

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      __$$UserPreferencesImplCopyWithImpl<_$UserPreferencesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPreferencesImplToJson(this);
  }
}

abstract class _UserPreferences implements UserPreferences {
  const factory _UserPreferences({
    required final String userId,
    final String themePaletteId,
    final Map<String, String>? customColors,
    final String backgroundId,
    final bool backgroundEnabled,
    final double backgroundOpacity,
    final double fontScale,
    final ColorBlindMode colorBlindMode,
    final bool dyslexiaFontEnabled,
    final bool reduceMotion,
  }) = _$UserPreferencesImpl;

  factory _UserPreferences.fromJson(Map<String, dynamic> json) =
      _$UserPreferencesImpl.fromJson;

  @override
  String get userId;
  @override
  String get themePaletteId;
  @override
  Map<String, String>? get customColors;
  @override
  String get backgroundId;
  @override
  bool get backgroundEnabled;
  @override
  double get backgroundOpacity;
  @override
  double get fontScale;
  @override
  ColorBlindMode get colorBlindMode;
  @override
  bool get dyslexiaFontEnabled;
  @override
  bool get reduceMotion;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
