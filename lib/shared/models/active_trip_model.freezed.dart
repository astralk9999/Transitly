// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ActiveTripModel {
  String get id => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;
  String? get driverId => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  double? get currentLat => throw _privateConstructorUsedError;
  double? get currentLng => throw _privateConstructorUsedError;
  double? get currentBearing => throw _privateConstructorUsedError;
  int? get currentStopIndex => throw _privateConstructorUsedError;
  TripStatus get status => throw _privateConstructorUsedError;
  int get delayMinutes => throw _privateConstructorUsedError;
  BusCapacity get capacity => throw _privateConstructorUsedError;
  String? get vehicleNumber => throw _privateConstructorUsedError;
  String? get driverMessage => throw _privateConstructorUsedError;

  /// Create a copy of ActiveTripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActiveTripModelCopyWith<ActiveTripModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveTripModelCopyWith<$Res> {
  factory $ActiveTripModelCopyWith(
    ActiveTripModel value,
    $Res Function(ActiveTripModel) then,
  ) = _$ActiveTripModelCopyWithImpl<$Res, ActiveTripModel>;
  @useResult
  $Res call({
    String id,
    String routeId,
    String? driverId,
    DateTime? startedAt,
    double? currentLat,
    double? currentLng,
    double? currentBearing,
    int? currentStopIndex,
    TripStatus status,
    int delayMinutes,
    BusCapacity capacity,
    String? vehicleNumber,
    String? driverMessage,
  });
}

/// @nodoc
class _$ActiveTripModelCopyWithImpl<$Res, $Val extends ActiveTripModel>
    implements $ActiveTripModelCopyWith<$Res> {
  _$ActiveTripModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActiveTripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? driverId = freezed,
    Object? startedAt = freezed,
    Object? currentLat = freezed,
    Object? currentLng = freezed,
    Object? currentBearing = freezed,
    Object? currentStopIndex = freezed,
    Object? status = null,
    Object? delayMinutes = null,
    Object? capacity = null,
    Object? vehicleNumber = freezed,
    Object? driverMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            driverId: freezed == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
                      as String?,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            currentLat: freezed == currentLat
                ? _value.currentLat
                : currentLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            currentLng: freezed == currentLng
                ? _value.currentLng
                : currentLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            currentBearing: freezed == currentBearing
                ? _value.currentBearing
                : currentBearing // ignore: cast_nullable_to_non_nullable
                      as double?,
            currentStopIndex: freezed == currentStopIndex
                ? _value.currentStopIndex
                : currentStopIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TripStatus,
            delayMinutes: null == delayMinutes
                ? _value.delayMinutes
                : delayMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            capacity: null == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as BusCapacity,
            vehicleNumber: freezed == vehicleNumber
                ? _value.vehicleNumber
                : vehicleNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            driverMessage: freezed == driverMessage
                ? _value.driverMessage
                : driverMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActiveTripModelImplCopyWith<$Res>
    implements $ActiveTripModelCopyWith<$Res> {
  factory _$$ActiveTripModelImplCopyWith(
    _$ActiveTripModelImpl value,
    $Res Function(_$ActiveTripModelImpl) then,
  ) = __$$ActiveTripModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String routeId,
    String? driverId,
    DateTime? startedAt,
    double? currentLat,
    double? currentLng,
    double? currentBearing,
    int? currentStopIndex,
    TripStatus status,
    int delayMinutes,
    BusCapacity capacity,
    String? vehicleNumber,
    String? driverMessage,
  });
}

/// @nodoc
class __$$ActiveTripModelImplCopyWithImpl<$Res>
    extends _$ActiveTripModelCopyWithImpl<$Res, _$ActiveTripModelImpl>
    implements _$$ActiveTripModelImplCopyWith<$Res> {
  __$$ActiveTripModelImplCopyWithImpl(
    _$ActiveTripModelImpl _value,
    $Res Function(_$ActiveTripModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActiveTripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? driverId = freezed,
    Object? startedAt = freezed,
    Object? currentLat = freezed,
    Object? currentLng = freezed,
    Object? currentBearing = freezed,
    Object? currentStopIndex = freezed,
    Object? status = null,
    Object? delayMinutes = null,
    Object? capacity = null,
    Object? vehicleNumber = freezed,
    Object? driverMessage = freezed,
  }) {
    return _then(
      _$ActiveTripModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverId: freezed == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String?,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        currentLat: freezed == currentLat
            ? _value.currentLat
            : currentLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        currentLng: freezed == currentLng
            ? _value.currentLng
            : currentLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        currentBearing: freezed == currentBearing
            ? _value.currentBearing
            : currentBearing // ignore: cast_nullable_to_non_nullable
                  as double?,
        currentStopIndex: freezed == currentStopIndex
            ? _value.currentStopIndex
            : currentStopIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TripStatus,
        delayMinutes: null == delayMinutes
            ? _value.delayMinutes
            : delayMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        capacity: null == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as BusCapacity,
        vehicleNumber: freezed == vehicleNumber
            ? _value.vehicleNumber
            : vehicleNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        driverMessage: freezed == driverMessage
            ? _value.driverMessage
            : driverMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ActiveTripModelImpl extends _ActiveTripModel {
  const _$ActiveTripModelImpl({
    required this.id,
    required this.routeId,
    this.driverId,
    this.startedAt,
    this.currentLat,
    this.currentLng,
    this.currentBearing,
    this.currentStopIndex,
    required this.status,
    this.delayMinutes = 0,
    required this.capacity,
    this.vehicleNumber,
    this.driverMessage,
  }) : super._();

  @override
  final String id;
  @override
  final String routeId;
  @override
  final String? driverId;
  @override
  final DateTime? startedAt;
  @override
  final double? currentLat;
  @override
  final double? currentLng;
  @override
  final double? currentBearing;
  @override
  final int? currentStopIndex;
  @override
  final TripStatus status;
  @override
  @JsonKey()
  final int delayMinutes;
  @override
  final BusCapacity capacity;
  @override
  final String? vehicleNumber;
  @override
  final String? driverMessage;

  @override
  String toString() {
    return 'ActiveTripModel(id: $id, routeId: $routeId, driverId: $driverId, startedAt: $startedAt, currentLat: $currentLat, currentLng: $currentLng, currentBearing: $currentBearing, currentStopIndex: $currentStopIndex, status: $status, delayMinutes: $delayMinutes, capacity: $capacity, vehicleNumber: $vehicleNumber, driverMessage: $driverMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveTripModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.currentLat, currentLat) ||
                other.currentLat == currentLat) &&
            (identical(other.currentLng, currentLng) ||
                other.currentLng == currentLng) &&
            (identical(other.currentBearing, currentBearing) ||
                other.currentBearing == currentBearing) &&
            (identical(other.currentStopIndex, currentStopIndex) ||
                other.currentStopIndex == currentStopIndex) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.delayMinutes, delayMinutes) ||
                other.delayMinutes == delayMinutes) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.vehicleNumber, vehicleNumber) ||
                other.vehicleNumber == vehicleNumber) &&
            (identical(other.driverMessage, driverMessage) ||
                other.driverMessage == driverMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    routeId,
    driverId,
    startedAt,
    currentLat,
    currentLng,
    currentBearing,
    currentStopIndex,
    status,
    delayMinutes,
    capacity,
    vehicleNumber,
    driverMessage,
  );

  /// Create a copy of ActiveTripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveTripModelImplCopyWith<_$ActiveTripModelImpl> get copyWith =>
      __$$ActiveTripModelImplCopyWithImpl<_$ActiveTripModelImpl>(
        this,
        _$identity,
      );
}

abstract class _ActiveTripModel extends ActiveTripModel {
  const factory _ActiveTripModel({
    required final String id,
    required final String routeId,
    final String? driverId,
    final DateTime? startedAt,
    final double? currentLat,
    final double? currentLng,
    final double? currentBearing,
    final int? currentStopIndex,
    required final TripStatus status,
    final int delayMinutes,
    required final BusCapacity capacity,
    final String? vehicleNumber,
    final String? driverMessage,
  }) = _$ActiveTripModelImpl;
  const _ActiveTripModel._() : super._();

  @override
  String get id;
  @override
  String get routeId;
  @override
  String? get driverId;
  @override
  DateTime? get startedAt;
  @override
  double? get currentLat;
  @override
  double? get currentLng;
  @override
  double? get currentBearing;
  @override
  int? get currentStopIndex;
  @override
  TripStatus get status;
  @override
  int get delayMinutes;
  @override
  BusCapacity get capacity;
  @override
  String? get vehicleNumber;
  @override
  String? get driverMessage;

  /// Create a copy of ActiveTripModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActiveTripModelImplCopyWith<_$ActiveTripModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
