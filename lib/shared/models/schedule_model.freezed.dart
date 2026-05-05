// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ScheduleModel {
  String get id => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;
  String get departureTime => throw _privateConstructorUsedError;
  DayType get dayType => throw _privateConstructorUsedError;
  List<int> get daysOfWeek => throw _privateConstructorUsedError;
  RouteDirection get direction => throw _privateConstructorUsedError;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleModelCopyWith<ScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleModelCopyWith<$Res> {
  factory $ScheduleModelCopyWith(
    ScheduleModel value,
    $Res Function(ScheduleModel) then,
  ) = _$ScheduleModelCopyWithImpl<$Res, ScheduleModel>;
  @useResult
  $Res call({
    String id,
    String routeId,
    String departureTime,
    DayType dayType,
    List<int> daysOfWeek,
    RouteDirection direction,
  });
}

/// @nodoc
class _$ScheduleModelCopyWithImpl<$Res, $Val extends ScheduleModel>
    implements $ScheduleModelCopyWith<$Res> {
  _$ScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? departureTime = null,
    Object? dayType = null,
    Object? daysOfWeek = null,
    Object? direction = null,
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
            departureTime: null == departureTime
                ? _value.departureTime
                : departureTime // ignore: cast_nullable_to_non_nullable
                      as String,
            dayType: null == dayType
                ? _value.dayType
                : dayType // ignore: cast_nullable_to_non_nullable
                      as DayType,
            daysOfWeek: null == daysOfWeek
                ? _value.daysOfWeek
                : daysOfWeek // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as RouteDirection,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScheduleModelImplCopyWith<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  factory _$$ScheduleModelImplCopyWith(
    _$ScheduleModelImpl value,
    $Res Function(_$ScheduleModelImpl) then,
  ) = __$$ScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String routeId,
    String departureTime,
    DayType dayType,
    List<int> daysOfWeek,
    RouteDirection direction,
  });
}

/// @nodoc
class __$$ScheduleModelImplCopyWithImpl<$Res>
    extends _$ScheduleModelCopyWithImpl<$Res, _$ScheduleModelImpl>
    implements _$$ScheduleModelImplCopyWith<$Res> {
  __$$ScheduleModelImplCopyWithImpl(
    _$ScheduleModelImpl _value,
    $Res Function(_$ScheduleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? departureTime = null,
    Object? dayType = null,
    Object? daysOfWeek = null,
    Object? direction = null,
  }) {
    return _then(
      _$ScheduleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        departureTime: null == departureTime
            ? _value.departureTime
            : departureTime // ignore: cast_nullable_to_non_nullable
                  as String,
        dayType: null == dayType
            ? _value.dayType
            : dayType // ignore: cast_nullable_to_non_nullable
                  as DayType,
        daysOfWeek: null == daysOfWeek
            ? _value._daysOfWeek
            : daysOfWeek // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as RouteDirection,
      ),
    );
  }
}

/// @nodoc

class _$ScheduleModelImpl extends _ScheduleModel {
  const _$ScheduleModelImpl({
    required this.id,
    required this.routeId,
    required this.departureTime,
    required this.dayType,
    final List<int> daysOfWeek = const <int>[],
    this.direction = RouteDirection.outbound,
  }) : _daysOfWeek = daysOfWeek,
       super._();

  @override
  final String id;
  @override
  final String routeId;
  @override
  final String departureTime;
  @override
  final DayType dayType;
  final List<int> _daysOfWeek;
  @override
  @JsonKey()
  List<int> get daysOfWeek {
    if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_daysOfWeek);
  }

  @override
  @JsonKey()
  final RouteDirection direction;

  @override
  String toString() {
    return 'ScheduleModel(id: $id, routeId: $routeId, departureTime: $departureTime, dayType: $dayType, daysOfWeek: $daysOfWeek, direction: $direction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.departureTime, departureTime) ||
                other.departureTime == departureTime) &&
            (identical(other.dayType, dayType) || other.dayType == dayType) &&
            const DeepCollectionEquality().equals(
              other._daysOfWeek,
              _daysOfWeek,
            ) &&
            (identical(other.direction, direction) ||
                other.direction == direction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    routeId,
    departureTime,
    dayType,
    const DeepCollectionEquality().hash(_daysOfWeek),
    direction,
  );

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      __$$ScheduleModelImplCopyWithImpl<_$ScheduleModelImpl>(this, _$identity);
}

abstract class _ScheduleModel extends ScheduleModel {
  const factory _ScheduleModel({
    required final String id,
    required final String routeId,
    required final String departureTime,
    required final DayType dayType,
    final List<int> daysOfWeek,
    final RouteDirection direction,
  }) = _$ScheduleModelImpl;
  const _ScheduleModel._() : super._();

  @override
  String get id;
  @override
  String get routeId;
  @override
  String get departureTime;
  @override
  DayType get dayType;
  @override
  List<int> get daysOfWeek;
  @override
  RouteDirection get direction;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
