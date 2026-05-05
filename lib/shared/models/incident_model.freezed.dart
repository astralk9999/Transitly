// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incident_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$IncidentModel {
  String get id => throw _privateConstructorUsedError;
  String get reporterId => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;
  String? get stopId => throw _privateConstructorUsedError;
  IncidentType get incidentType => throw _privateConstructorUsedError;
  IncidentCategory get category => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get confirmations => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IncidentModelCopyWith<IncidentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncidentModelCopyWith<$Res> {
  factory $IncidentModelCopyWith(
    IncidentModel value,
    $Res Function(IncidentModel) then,
  ) = _$IncidentModelCopyWithImpl<$Res, IncidentModel>;
  @useResult
  $Res call({
    String id,
    String reporterId,
    String routeId,
    String? stopId,
    IncidentType incidentType,
    IncidentCategory category,
    String? comment,
    String status,
    int confirmations,
    DateTime createdAt,
  });
}

/// @nodoc
class _$IncidentModelCopyWithImpl<$Res, $Val extends IncidentModel>
    implements $IncidentModelCopyWith<$Res> {
  _$IncidentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? routeId = null,
    Object? stopId = freezed,
    Object? incidentType = null,
    Object? category = null,
    Object? comment = freezed,
    Object? status = null,
    Object? confirmations = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            reporterId: null == reporterId
                ? _value.reporterId
                : reporterId // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            stopId: freezed == stopId
                ? _value.stopId
                : stopId // ignore: cast_nullable_to_non_nullable
                      as String?,
            incidentType: null == incidentType
                ? _value.incidentType
                : incidentType // ignore: cast_nullable_to_non_nullable
                      as IncidentType,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as IncidentCategory,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            confirmations: null == confirmations
                ? _value.confirmations
                : confirmations // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IncidentModelImplCopyWith<$Res>
    implements $IncidentModelCopyWith<$Res> {
  factory _$$IncidentModelImplCopyWith(
    _$IncidentModelImpl value,
    $Res Function(_$IncidentModelImpl) then,
  ) = __$$IncidentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reporterId,
    String routeId,
    String? stopId,
    IncidentType incidentType,
    IncidentCategory category,
    String? comment,
    String status,
    int confirmations,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$IncidentModelImplCopyWithImpl<$Res>
    extends _$IncidentModelCopyWithImpl<$Res, _$IncidentModelImpl>
    implements _$$IncidentModelImplCopyWith<$Res> {
  __$$IncidentModelImplCopyWithImpl(
    _$IncidentModelImpl _value,
    $Res Function(_$IncidentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? routeId = null,
    Object? stopId = freezed,
    Object? incidentType = null,
    Object? category = null,
    Object? comment = freezed,
    Object? status = null,
    Object? confirmations = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$IncidentModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reporterId: null == reporterId
            ? _value.reporterId
            : reporterId // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        stopId: freezed == stopId
            ? _value.stopId
            : stopId // ignore: cast_nullable_to_non_nullable
                  as String?,
        incidentType: null == incidentType
            ? _value.incidentType
            : incidentType // ignore: cast_nullable_to_non_nullable
                  as IncidentType,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as IncidentCategory,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        confirmations: null == confirmations
            ? _value.confirmations
            : confirmations // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$IncidentModelImpl extends _IncidentModel {
  const _$IncidentModelImpl({
    required this.id,
    required this.reporterId,
    required this.routeId,
    this.stopId,
    required this.incidentType,
    required this.category,
    this.comment,
    required this.status,
    this.confirmations = 0,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String reporterId;
  @override
  final String routeId;
  @override
  final String? stopId;
  @override
  final IncidentType incidentType;
  @override
  final IncidentCategory category;
  @override
  final String? comment;
  @override
  final String status;
  @override
  @JsonKey()
  final int confirmations;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'IncidentModel(id: $id, reporterId: $reporterId, routeId: $routeId, stopId: $stopId, incidentType: $incidentType, category: $category, comment: $comment, status: $status, confirmations: $confirmations, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncidentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reporterId, reporterId) ||
                other.reporterId == reporterId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.stopId, stopId) || other.stopId == stopId) &&
            (identical(other.incidentType, incidentType) ||
                other.incidentType == incidentType) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.confirmations, confirmations) ||
                other.confirmations == confirmations) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reporterId,
    routeId,
    stopId,
    incidentType,
    category,
    comment,
    status,
    confirmations,
    createdAt,
  );

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      __$$IncidentModelImplCopyWithImpl<_$IncidentModelImpl>(this, _$identity);
}

abstract class _IncidentModel extends IncidentModel {
  const factory _IncidentModel({
    required final String id,
    required final String reporterId,
    required final String routeId,
    final String? stopId,
    required final IncidentType incidentType,
    required final IncidentCategory category,
    final String? comment,
    required final String status,
    final int confirmations,
    required final DateTime createdAt,
  }) = _$IncidentModelImpl;
  const _IncidentModel._() : super._();

  @override
  String get id;
  @override
  String get reporterId;
  @override
  String get routeId;
  @override
  String? get stopId;
  @override
  IncidentType get incidentType;
  @override
  IncidentCategory get category;
  @override
  String? get comment;
  @override
  String get status;
  @override
  int get confirmations;
  @override
  DateTime get createdAt;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
