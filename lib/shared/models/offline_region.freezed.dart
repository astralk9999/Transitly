// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OfflineRegionBounds _$OfflineRegionBoundsFromJson(Map<String, dynamic> json) {
  return _OfflineRegionBounds.fromJson(json);
}

/// @nodoc
mixin _$OfflineRegionBounds {
  double get northLat => throw _privateConstructorUsedError;
  double get southLat => throw _privateConstructorUsedError;
  double get eastLng => throw _privateConstructorUsedError;
  double get westLng => throw _privateConstructorUsedError;

  /// Serializes this OfflineRegionBounds to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OfflineRegionBounds
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfflineRegionBoundsCopyWith<OfflineRegionBounds> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfflineRegionBoundsCopyWith<$Res> {
  factory $OfflineRegionBoundsCopyWith(
    OfflineRegionBounds value,
    $Res Function(OfflineRegionBounds) then,
  ) = _$OfflineRegionBoundsCopyWithImpl<$Res, OfflineRegionBounds>;
  @useResult
  $Res call({double northLat, double southLat, double eastLng, double westLng});
}

/// @nodoc
class _$OfflineRegionBoundsCopyWithImpl<$Res, $Val extends OfflineRegionBounds>
    implements $OfflineRegionBoundsCopyWith<$Res> {
  _$OfflineRegionBoundsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfflineRegionBounds
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northLat = null,
    Object? southLat = null,
    Object? eastLng = null,
    Object? westLng = null,
  }) {
    return _then(
      _value.copyWith(
            northLat: null == northLat
                ? _value.northLat
                : northLat // ignore: cast_nullable_to_non_nullable
                      as double,
            southLat: null == southLat
                ? _value.southLat
                : southLat // ignore: cast_nullable_to_non_nullable
                      as double,
            eastLng: null == eastLng
                ? _value.eastLng
                : eastLng // ignore: cast_nullable_to_non_nullable
                      as double,
            westLng: null == westLng
                ? _value.westLng
                : westLng // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OfflineRegionBoundsImplCopyWith<$Res>
    implements $OfflineRegionBoundsCopyWith<$Res> {
  factory _$$OfflineRegionBoundsImplCopyWith(
    _$OfflineRegionBoundsImpl value,
    $Res Function(_$OfflineRegionBoundsImpl) then,
  ) = __$$OfflineRegionBoundsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double northLat, double southLat, double eastLng, double westLng});
}

/// @nodoc
class __$$OfflineRegionBoundsImplCopyWithImpl<$Res>
    extends _$OfflineRegionBoundsCopyWithImpl<$Res, _$OfflineRegionBoundsImpl>
    implements _$$OfflineRegionBoundsImplCopyWith<$Res> {
  __$$OfflineRegionBoundsImplCopyWithImpl(
    _$OfflineRegionBoundsImpl _value,
    $Res Function(_$OfflineRegionBoundsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OfflineRegionBounds
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northLat = null,
    Object? southLat = null,
    Object? eastLng = null,
    Object? westLng = null,
  }) {
    return _then(
      _$OfflineRegionBoundsImpl(
        northLat: null == northLat
            ? _value.northLat
            : northLat // ignore: cast_nullable_to_non_nullable
                  as double,
        southLat: null == southLat
            ? _value.southLat
            : southLat // ignore: cast_nullable_to_non_nullable
                  as double,
        eastLng: null == eastLng
            ? _value.eastLng
            : eastLng // ignore: cast_nullable_to_non_nullable
                  as double,
        westLng: null == westLng
            ? _value.westLng
            : westLng // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OfflineRegionBoundsImpl implements _OfflineRegionBounds {
  const _$OfflineRegionBoundsImpl({
    required this.northLat,
    required this.southLat,
    required this.eastLng,
    required this.westLng,
  });

  factory _$OfflineRegionBoundsImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfflineRegionBoundsImplFromJson(json);

  @override
  final double northLat;
  @override
  final double southLat;
  @override
  final double eastLng;
  @override
  final double westLng;

  @override
  String toString() {
    return 'OfflineRegionBounds(northLat: $northLat, southLat: $southLat, eastLng: $eastLng, westLng: $westLng)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfflineRegionBoundsImpl &&
            (identical(other.northLat, northLat) ||
                other.northLat == northLat) &&
            (identical(other.southLat, southLat) ||
                other.southLat == southLat) &&
            (identical(other.eastLng, eastLng) || other.eastLng == eastLng) &&
            (identical(other.westLng, westLng) || other.westLng == westLng));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, northLat, southLat, eastLng, westLng);

  /// Create a copy of OfflineRegionBounds
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfflineRegionBoundsImplCopyWith<_$OfflineRegionBoundsImpl> get copyWith =>
      __$$OfflineRegionBoundsImplCopyWithImpl<_$OfflineRegionBoundsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OfflineRegionBoundsImplToJson(this);
  }
}

abstract class _OfflineRegionBounds implements OfflineRegionBounds {
  const factory _OfflineRegionBounds({
    required final double northLat,
    required final double southLat,
    required final double eastLng,
    required final double westLng,
  }) = _$OfflineRegionBoundsImpl;

  factory _OfflineRegionBounds.fromJson(Map<String, dynamic> json) =
      _$OfflineRegionBoundsImpl.fromJson;

  @override
  double get northLat;
  @override
  double get southLat;
  @override
  double get eastLng;
  @override
  double get westLng;

  /// Create a copy of OfflineRegionBounds
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfflineRegionBoundsImplCopyWith<_$OfflineRegionBoundsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OfflineRegion _$OfflineRegionFromJson(Map<String, dynamic> json) {
  return _OfflineRegion.fromJson(json);
}

/// @nodoc
mixin _$OfflineRegion {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  OfflineRegionBounds get bounds => throw _privateConstructorUsedError;
  int get zoomMin => throw _privateConstructorUsedError;
  int get zoomMax => throw _privateConstructorUsedError;
  DateTime get downloadedAt => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  OfflineRegionStatus get status => throw _privateConstructorUsedError;

  /// Serializes this OfflineRegion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfflineRegionCopyWith<OfflineRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfflineRegionCopyWith<$Res> {
  factory $OfflineRegionCopyWith(
    OfflineRegion value,
    $Res Function(OfflineRegion) then,
  ) = _$OfflineRegionCopyWithImpl<$Res, OfflineRegion>;
  @useResult
  $Res call({
    String id,
    String label,
    OfflineRegionBounds bounds,
    int zoomMin,
    int zoomMax,
    DateTime downloadedAt,
    int sizeBytes,
    OfflineRegionStatus status,
  });

  $OfflineRegionBoundsCopyWith<$Res> get bounds;
}

/// @nodoc
class _$OfflineRegionCopyWithImpl<$Res, $Val extends OfflineRegion>
    implements $OfflineRegionCopyWith<$Res> {
  _$OfflineRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? bounds = null,
    Object? zoomMin = null,
    Object? zoomMax = null,
    Object? downloadedAt = null,
    Object? sizeBytes = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            bounds: null == bounds
                ? _value.bounds
                : bounds // ignore: cast_nullable_to_non_nullable
                      as OfflineRegionBounds,
            zoomMin: null == zoomMin
                ? _value.zoomMin
                : zoomMin // ignore: cast_nullable_to_non_nullable
                      as int,
            zoomMax: null == zoomMax
                ? _value.zoomMax
                : zoomMax // ignore: cast_nullable_to_non_nullable
                      as int,
            downloadedAt: null == downloadedAt
                ? _value.downloadedAt
                : downloadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OfflineRegionStatus,
          )
          as $Val,
    );
  }

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OfflineRegionBoundsCopyWith<$Res> get bounds {
    return $OfflineRegionBoundsCopyWith<$Res>(_value.bounds, (value) {
      return _then(_value.copyWith(bounds: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OfflineRegionImplCopyWith<$Res>
    implements $OfflineRegionCopyWith<$Res> {
  factory _$$OfflineRegionImplCopyWith(
    _$OfflineRegionImpl value,
    $Res Function(_$OfflineRegionImpl) then,
  ) = __$$OfflineRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String label,
    OfflineRegionBounds bounds,
    int zoomMin,
    int zoomMax,
    DateTime downloadedAt,
    int sizeBytes,
    OfflineRegionStatus status,
  });

  @override
  $OfflineRegionBoundsCopyWith<$Res> get bounds;
}

/// @nodoc
class __$$OfflineRegionImplCopyWithImpl<$Res>
    extends _$OfflineRegionCopyWithImpl<$Res, _$OfflineRegionImpl>
    implements _$$OfflineRegionImplCopyWith<$Res> {
  __$$OfflineRegionImplCopyWithImpl(
    _$OfflineRegionImpl _value,
    $Res Function(_$OfflineRegionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? bounds = null,
    Object? zoomMin = null,
    Object? zoomMax = null,
    Object? downloadedAt = null,
    Object? sizeBytes = null,
    Object? status = null,
  }) {
    return _then(
      _$OfflineRegionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        bounds: null == bounds
            ? _value.bounds
            : bounds // ignore: cast_nullable_to_non_nullable
                  as OfflineRegionBounds,
        zoomMin: null == zoomMin
            ? _value.zoomMin
            : zoomMin // ignore: cast_nullable_to_non_nullable
                  as int,
        zoomMax: null == zoomMax
            ? _value.zoomMax
            : zoomMax // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedAt: null == downloadedAt
            ? _value.downloadedAt
            : downloadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OfflineRegionStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OfflineRegionImpl implements _OfflineRegion {
  const _$OfflineRegionImpl({
    required this.id,
    required this.label,
    required this.bounds,
    required this.zoomMin,
    required this.zoomMax,
    required this.downloadedAt,
    required this.sizeBytes,
    required this.status,
  });

  factory _$OfflineRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfflineRegionImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final OfflineRegionBounds bounds;
  @override
  final int zoomMin;
  @override
  final int zoomMax;
  @override
  final DateTime downloadedAt;
  @override
  final int sizeBytes;
  @override
  final OfflineRegionStatus status;

  @override
  String toString() {
    return 'OfflineRegion(id: $id, label: $label, bounds: $bounds, zoomMin: $zoomMin, zoomMax: $zoomMax, downloadedAt: $downloadedAt, sizeBytes: $sizeBytes, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfflineRegionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.bounds, bounds) || other.bounds == bounds) &&
            (identical(other.zoomMin, zoomMin) || other.zoomMin == zoomMin) &&
            (identical(other.zoomMax, zoomMax) || other.zoomMax == zoomMax) &&
            (identical(other.downloadedAt, downloadedAt) ||
                other.downloadedAt == downloadedAt) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    bounds,
    zoomMin,
    zoomMax,
    downloadedAt,
    sizeBytes,
    status,
  );

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfflineRegionImplCopyWith<_$OfflineRegionImpl> get copyWith =>
      __$$OfflineRegionImplCopyWithImpl<_$OfflineRegionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OfflineRegionImplToJson(this);
  }
}

abstract class _OfflineRegion implements OfflineRegion {
  const factory _OfflineRegion({
    required final String id,
    required final String label,
    required final OfflineRegionBounds bounds,
    required final int zoomMin,
    required final int zoomMax,
    required final DateTime downloadedAt,
    required final int sizeBytes,
    required final OfflineRegionStatus status,
  }) = _$OfflineRegionImpl;

  factory _OfflineRegion.fromJson(Map<String, dynamic> json) =
      _$OfflineRegionImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  OfflineRegionBounds get bounds;
  @override
  int get zoomMin;
  @override
  int get zoomMax;
  @override
  DateTime get downloadedAt;
  @override
  int get sizeBytes;
  @override
  OfflineRegionStatus get status;

  /// Create a copy of OfflineRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfflineRegionImplCopyWith<_$OfflineRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
