// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_stop_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RouteStopModel {
  String get routeId => throw _privateConstructorUsedError;
  String get stopId => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  RouteDirection get direction => throw _privateConstructorUsedError;
  int? get timeFromStartMinutes => throw _privateConstructorUsedError;
  double? get distanceFromStartKm => throw _privateConstructorUsedError;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteStopModelCopyWith<RouteStopModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteStopModelCopyWith<$Res> {
  factory $RouteStopModelCopyWith(
    RouteStopModel value,
    $Res Function(RouteStopModel) then,
  ) = _$RouteStopModelCopyWithImpl<$Res, RouteStopModel>;
  @useResult
  $Res call({
    String routeId,
    String stopId,
    int orderIndex,
    RouteDirection direction,
    int? timeFromStartMinutes,
    double? distanceFromStartKm,
  });
}

/// @nodoc
class _$RouteStopModelCopyWithImpl<$Res, $Val extends RouteStopModel>
    implements $RouteStopModelCopyWith<$Res> {
  _$RouteStopModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? stopId = null,
    Object? orderIndex = null,
    Object? direction = null,
    Object? timeFromStartMinutes = freezed,
    Object? distanceFromStartKm = freezed,
  }) {
    return _then(
      _value.copyWith(
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            stopId: null == stopId
                ? _value.stopId
                : stopId // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as RouteDirection,
            timeFromStartMinutes: freezed == timeFromStartMinutes
                ? _value.timeFromStartMinutes
                : timeFromStartMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            distanceFromStartKm: freezed == distanceFromStartKm
                ? _value.distanceFromStartKm
                : distanceFromStartKm // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteStopModelImplCopyWith<$Res>
    implements $RouteStopModelCopyWith<$Res> {
  factory _$$RouteStopModelImplCopyWith(
    _$RouteStopModelImpl value,
    $Res Function(_$RouteStopModelImpl) then,
  ) = __$$RouteStopModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String routeId,
    String stopId,
    int orderIndex,
    RouteDirection direction,
    int? timeFromStartMinutes,
    double? distanceFromStartKm,
  });
}

/// @nodoc
class __$$RouteStopModelImplCopyWithImpl<$Res>
    extends _$RouteStopModelCopyWithImpl<$Res, _$RouteStopModelImpl>
    implements _$$RouteStopModelImplCopyWith<$Res> {
  __$$RouteStopModelImplCopyWithImpl(
    _$RouteStopModelImpl _value,
    $Res Function(_$RouteStopModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? stopId = null,
    Object? orderIndex = null,
    Object? direction = null,
    Object? timeFromStartMinutes = freezed,
    Object? distanceFromStartKm = freezed,
  }) {
    return _then(
      _$RouteStopModelImpl(
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        stopId: null == stopId
            ? _value.stopId
            : stopId // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as RouteDirection,
        timeFromStartMinutes: freezed == timeFromStartMinutes
            ? _value.timeFromStartMinutes
            : timeFromStartMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        distanceFromStartKm: freezed == distanceFromStartKm
            ? _value.distanceFromStartKm
            : distanceFromStartKm // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$RouteStopModelImpl extends _RouteStopModel {
  const _$RouteStopModelImpl({
    required this.routeId,
    required this.stopId,
    required this.orderIndex,
    this.direction = RouteDirection.outbound,
    this.timeFromStartMinutes,
    this.distanceFromStartKm,
  }) : super._();

  @override
  final String routeId;
  @override
  final String stopId;
  @override
  final int orderIndex;
  @override
  @JsonKey()
  final RouteDirection direction;
  @override
  final int? timeFromStartMinutes;
  @override
  final double? distanceFromStartKm;

  @override
  String toString() {
    return 'RouteStopModel(routeId: $routeId, stopId: $stopId, orderIndex: $orderIndex, direction: $direction, timeFromStartMinutes: $timeFromStartMinutes, distanceFromStartKm: $distanceFromStartKm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteStopModelImpl &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.stopId, stopId) || other.stopId == stopId) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.timeFromStartMinutes, timeFromStartMinutes) ||
                other.timeFromStartMinutes == timeFromStartMinutes) &&
            (identical(other.distanceFromStartKm, distanceFromStartKm) ||
                other.distanceFromStartKm == distanceFromStartKm));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    routeId,
    stopId,
    orderIndex,
    direction,
    timeFromStartMinutes,
    distanceFromStartKm,
  );

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteStopModelImplCopyWith<_$RouteStopModelImpl> get copyWith =>
      __$$RouteStopModelImplCopyWithImpl<_$RouteStopModelImpl>(
        this,
        _$identity,
      );
}

abstract class _RouteStopModel extends RouteStopModel {
  const factory _RouteStopModel({
    required final String routeId,
    required final String stopId,
    required final int orderIndex,
    final RouteDirection direction,
    final int? timeFromStartMinutes,
    final double? distanceFromStartKm,
  }) = _$RouteStopModelImpl;
  const _RouteStopModel._() : super._();

  @override
  String get routeId;
  @override
  String get stopId;
  @override
  int get orderIndex;
  @override
  RouteDirection get direction;
  @override
  int? get timeFromStartMinutes;
  @override
  double? get distanceFromStartKm;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteStopModelImplCopyWith<_$RouteStopModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
