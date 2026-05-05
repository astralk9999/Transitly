// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AlertModel {
  String get id => throw _privateConstructorUsedError;
  String get operatorId => throw _privateConstructorUsedError;
  String? get routeId => throw _privateConstructorUsedError;
  AlertSeverity get severity => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  DateTime? get activeFrom => throw _privateConstructorUsedError;
  DateTime? get activeUntil => throw _privateConstructorUsedError;

  /// Create a copy of AlertModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlertModelCopyWith<AlertModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlertModelCopyWith<$Res> {
  factory $AlertModelCopyWith(
    AlertModel value,
    $Res Function(AlertModel) then,
  ) = _$AlertModelCopyWithImpl<$Res, AlertModel>;
  @useResult
  $Res call({
    String id,
    String operatorId,
    String? routeId,
    AlertSeverity severity,
    String title,
    String body,
    DateTime? activeFrom,
    DateTime? activeUntil,
  });
}

/// @nodoc
class _$AlertModelCopyWithImpl<$Res, $Val extends AlertModel>
    implements $AlertModelCopyWith<$Res> {
  _$AlertModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlertModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? operatorId = null,
    Object? routeId = freezed,
    Object? severity = null,
    Object? title = null,
    Object? body = null,
    Object? activeFrom = freezed,
    Object? activeUntil = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            operatorId: null == operatorId
                ? _value.operatorId
                : operatorId // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: freezed == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as AlertSeverity,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            activeFrom: freezed == activeFrom
                ? _value.activeFrom
                : activeFrom // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            activeUntil: freezed == activeUntil
                ? _value.activeUntil
                : activeUntil // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlertModelImplCopyWith<$Res>
    implements $AlertModelCopyWith<$Res> {
  factory _$$AlertModelImplCopyWith(
    _$AlertModelImpl value,
    $Res Function(_$AlertModelImpl) then,
  ) = __$$AlertModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String operatorId,
    String? routeId,
    AlertSeverity severity,
    String title,
    String body,
    DateTime? activeFrom,
    DateTime? activeUntil,
  });
}

/// @nodoc
class __$$AlertModelImplCopyWithImpl<$Res>
    extends _$AlertModelCopyWithImpl<$Res, _$AlertModelImpl>
    implements _$$AlertModelImplCopyWith<$Res> {
  __$$AlertModelImplCopyWithImpl(
    _$AlertModelImpl _value,
    $Res Function(_$AlertModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlertModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? operatorId = null,
    Object? routeId = freezed,
    Object? severity = null,
    Object? title = null,
    Object? body = null,
    Object? activeFrom = freezed,
    Object? activeUntil = freezed,
  }) {
    return _then(
      _$AlertModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        operatorId: null == operatorId
            ? _value.operatorId
            : operatorId // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: freezed == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as AlertSeverity,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        activeFrom: freezed == activeFrom
            ? _value.activeFrom
            : activeFrom // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        activeUntil: freezed == activeUntil
            ? _value.activeUntil
            : activeUntil // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$AlertModelImpl extends _AlertModel {
  const _$AlertModelImpl({
    required this.id,
    required this.operatorId,
    this.routeId,
    required this.severity,
    required this.title,
    required this.body,
    this.activeFrom,
    this.activeUntil,
  }) : super._();

  @override
  final String id;
  @override
  final String operatorId;
  @override
  final String? routeId;
  @override
  final AlertSeverity severity;
  @override
  final String title;
  @override
  final String body;
  @override
  final DateTime? activeFrom;
  @override
  final DateTime? activeUntil;

  @override
  String toString() {
    return 'AlertModel(id: $id, operatorId: $operatorId, routeId: $routeId, severity: $severity, title: $title, body: $body, activeFrom: $activeFrom, activeUntil: $activeUntil)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlertModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.operatorId, operatorId) ||
                other.operatorId == operatorId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.activeFrom, activeFrom) ||
                other.activeFrom == activeFrom) &&
            (identical(other.activeUntil, activeUntil) ||
                other.activeUntil == activeUntil));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    operatorId,
    routeId,
    severity,
    title,
    body,
    activeFrom,
    activeUntil,
  );

  /// Create a copy of AlertModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlertModelImplCopyWith<_$AlertModelImpl> get copyWith =>
      __$$AlertModelImplCopyWithImpl<_$AlertModelImpl>(this, _$identity);
}

abstract class _AlertModel extends AlertModel {
  const factory _AlertModel({
    required final String id,
    required final String operatorId,
    final String? routeId,
    required final AlertSeverity severity,
    required final String title,
    required final String body,
    final DateTime? activeFrom,
    final DateTime? activeUntil,
  }) = _$AlertModelImpl;
  const _AlertModel._() : super._();

  @override
  String get id;
  @override
  String get operatorId;
  @override
  String? get routeId;
  @override
  AlertSeverity get severity;
  @override
  String get title;
  @override
  String get body;
  @override
  DateTime? get activeFrom;
  @override
  DateTime? get activeUntil;

  /// Create a copy of AlertModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlertModelImplCopyWith<_$AlertModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
