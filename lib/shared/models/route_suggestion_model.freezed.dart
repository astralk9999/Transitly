// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_suggestion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RouteSuggestionModel {
  String get id => throw _privateConstructorUsedError;
  String get suggestedBy => throw _privateConstructorUsedError;
  String get originText => throw _privateConstructorUsedError;
  double? get originLat => throw _privateConstructorUsedError;
  double? get originLng => throw _privateConstructorUsedError;
  String get destinationText => throw _privateConstructorUsedError;
  double? get destinationLat => throw _privateConstructorUsedError;
  double? get destinationLng => throw _privateConstructorUsedError;
  String? get routeCode => throw _privateConstructorUsedError;
  String? get operatorName => throw _privateConstructorUsedError;
  ServiceType? get serviceType => throw _privateConstructorUsedError;
  String? get detailLevel => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  SuggestionStatus get status => throw _privateConstructorUsedError;
  int get voteCount => throw _privateConstructorUsedError;
  int get contributionCount => throw _privateConstructorUsedError;
  Priority get priority => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of RouteSuggestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteSuggestionModelCopyWith<RouteSuggestionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteSuggestionModelCopyWith<$Res> {
  factory $RouteSuggestionModelCopyWith(
    RouteSuggestionModel value,
    $Res Function(RouteSuggestionModel) then,
  ) = _$RouteSuggestionModelCopyWithImpl<$Res, RouteSuggestionModel>;
  @useResult
  $Res call({
    String id,
    String suggestedBy,
    String originText,
    double? originLat,
    double? originLng,
    String destinationText,
    double? destinationLat,
    double? destinationLng,
    String? routeCode,
    String? operatorName,
    ServiceType? serviceType,
    String? detailLevel,
    String? source,
    String? notes,
    SuggestionStatus status,
    int voteCount,
    int contributionCount,
    Priority priority,
    DateTime createdAt,
  });
}

/// @nodoc
class _$RouteSuggestionModelCopyWithImpl<
  $Res,
  $Val extends RouteSuggestionModel
>
    implements $RouteSuggestionModelCopyWith<$Res> {
  _$RouteSuggestionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteSuggestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? suggestedBy = null,
    Object? originText = null,
    Object? originLat = freezed,
    Object? originLng = freezed,
    Object? destinationText = null,
    Object? destinationLat = freezed,
    Object? destinationLng = freezed,
    Object? routeCode = freezed,
    Object? operatorName = freezed,
    Object? serviceType = freezed,
    Object? detailLevel = freezed,
    Object? source = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? voteCount = null,
    Object? contributionCount = null,
    Object? priority = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            suggestedBy: null == suggestedBy
                ? _value.suggestedBy
                : suggestedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            originText: null == originText
                ? _value.originText
                : originText // ignore: cast_nullable_to_non_nullable
                      as String,
            originLat: freezed == originLat
                ? _value.originLat
                : originLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            originLng: freezed == originLng
                ? _value.originLng
                : originLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            destinationText: null == destinationText
                ? _value.destinationText
                : destinationText // ignore: cast_nullable_to_non_nullable
                      as String,
            destinationLat: freezed == destinationLat
                ? _value.destinationLat
                : destinationLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            destinationLng: freezed == destinationLng
                ? _value.destinationLng
                : destinationLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            routeCode: freezed == routeCode
                ? _value.routeCode
                : routeCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            operatorName: freezed == operatorName
                ? _value.operatorName
                : operatorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            serviceType: freezed == serviceType
                ? _value.serviceType
                : serviceType // ignore: cast_nullable_to_non_nullable
                      as ServiceType?,
            detailLevel: freezed == detailLevel
                ? _value.detailLevel
                : detailLevel // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SuggestionStatus,
            voteCount: null == voteCount
                ? _value.voteCount
                : voteCount // ignore: cast_nullable_to_non_nullable
                      as int,
            contributionCount: null == contributionCount
                ? _value.contributionCount
                : contributionCount // ignore: cast_nullable_to_non_nullable
                      as int,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as Priority,
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
abstract class _$$RouteSuggestionModelImplCopyWith<$Res>
    implements $RouteSuggestionModelCopyWith<$Res> {
  factory _$$RouteSuggestionModelImplCopyWith(
    _$RouteSuggestionModelImpl value,
    $Res Function(_$RouteSuggestionModelImpl) then,
  ) = __$$RouteSuggestionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String suggestedBy,
    String originText,
    double? originLat,
    double? originLng,
    String destinationText,
    double? destinationLat,
    double? destinationLng,
    String? routeCode,
    String? operatorName,
    ServiceType? serviceType,
    String? detailLevel,
    String? source,
    String? notes,
    SuggestionStatus status,
    int voteCount,
    int contributionCount,
    Priority priority,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$RouteSuggestionModelImplCopyWithImpl<$Res>
    extends _$RouteSuggestionModelCopyWithImpl<$Res, _$RouteSuggestionModelImpl>
    implements _$$RouteSuggestionModelImplCopyWith<$Res> {
  __$$RouteSuggestionModelImplCopyWithImpl(
    _$RouteSuggestionModelImpl _value,
    $Res Function(_$RouteSuggestionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteSuggestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? suggestedBy = null,
    Object? originText = null,
    Object? originLat = freezed,
    Object? originLng = freezed,
    Object? destinationText = null,
    Object? destinationLat = freezed,
    Object? destinationLng = freezed,
    Object? routeCode = freezed,
    Object? operatorName = freezed,
    Object? serviceType = freezed,
    Object? detailLevel = freezed,
    Object? source = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? voteCount = null,
    Object? contributionCount = null,
    Object? priority = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$RouteSuggestionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestedBy: null == suggestedBy
            ? _value.suggestedBy
            : suggestedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        originText: null == originText
            ? _value.originText
            : originText // ignore: cast_nullable_to_non_nullable
                  as String,
        originLat: freezed == originLat
            ? _value.originLat
            : originLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        originLng: freezed == originLng
            ? _value.originLng
            : originLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        destinationText: null == destinationText
            ? _value.destinationText
            : destinationText // ignore: cast_nullable_to_non_nullable
                  as String,
        destinationLat: freezed == destinationLat
            ? _value.destinationLat
            : destinationLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        destinationLng: freezed == destinationLng
            ? _value.destinationLng
            : destinationLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        routeCode: freezed == routeCode
            ? _value.routeCode
            : routeCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        operatorName: freezed == operatorName
            ? _value.operatorName
            : operatorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        serviceType: freezed == serviceType
            ? _value.serviceType
            : serviceType // ignore: cast_nullable_to_non_nullable
                  as ServiceType?,
        detailLevel: freezed == detailLevel
            ? _value.detailLevel
            : detailLevel // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SuggestionStatus,
        voteCount: null == voteCount
            ? _value.voteCount
            : voteCount // ignore: cast_nullable_to_non_nullable
                  as int,
        contributionCount: null == contributionCount
            ? _value.contributionCount
            : contributionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as Priority,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$RouteSuggestionModelImpl extends _RouteSuggestionModel {
  const _$RouteSuggestionModelImpl({
    required this.id,
    required this.suggestedBy,
    required this.originText,
    this.originLat,
    this.originLng,
    required this.destinationText,
    this.destinationLat,
    this.destinationLng,
    this.routeCode,
    this.operatorName,
    this.serviceType,
    this.detailLevel,
    this.source,
    this.notes,
    required this.status,
    this.voteCount = 0,
    this.contributionCount = 0,
    this.priority = Priority.medium,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String suggestedBy;
  @override
  final String originText;
  @override
  final double? originLat;
  @override
  final double? originLng;
  @override
  final String destinationText;
  @override
  final double? destinationLat;
  @override
  final double? destinationLng;
  @override
  final String? routeCode;
  @override
  final String? operatorName;
  @override
  final ServiceType? serviceType;
  @override
  final String? detailLevel;
  @override
  final String? source;
  @override
  final String? notes;
  @override
  final SuggestionStatus status;
  @override
  @JsonKey()
  final int voteCount;
  @override
  @JsonKey()
  final int contributionCount;
  @override
  @JsonKey()
  final Priority priority;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'RouteSuggestionModel(id: $id, suggestedBy: $suggestedBy, originText: $originText, originLat: $originLat, originLng: $originLng, destinationText: $destinationText, destinationLat: $destinationLat, destinationLng: $destinationLng, routeCode: $routeCode, operatorName: $operatorName, serviceType: $serviceType, detailLevel: $detailLevel, source: $source, notes: $notes, status: $status, voteCount: $voteCount, contributionCount: $contributionCount, priority: $priority, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteSuggestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.suggestedBy, suggestedBy) ||
                other.suggestedBy == suggestedBy) &&
            (identical(other.originText, originText) ||
                other.originText == originText) &&
            (identical(other.originLat, originLat) ||
                other.originLat == originLat) &&
            (identical(other.originLng, originLng) ||
                other.originLng == originLng) &&
            (identical(other.destinationText, destinationText) ||
                other.destinationText == destinationText) &&
            (identical(other.destinationLat, destinationLat) ||
                other.destinationLat == destinationLat) &&
            (identical(other.destinationLng, destinationLng) ||
                other.destinationLng == destinationLng) &&
            (identical(other.routeCode, routeCode) ||
                other.routeCode == routeCode) &&
            (identical(other.operatorName, operatorName) ||
                other.operatorName == operatorName) &&
            (identical(other.serviceType, serviceType) ||
                other.serviceType == serviceType) &&
            (identical(other.detailLevel, detailLevel) ||
                other.detailLevel == detailLevel) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.voteCount, voteCount) ||
                other.voteCount == voteCount) &&
            (identical(other.contributionCount, contributionCount) ||
                other.contributionCount == contributionCount) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    suggestedBy,
    originText,
    originLat,
    originLng,
    destinationText,
    destinationLat,
    destinationLng,
    routeCode,
    operatorName,
    serviceType,
    detailLevel,
    source,
    notes,
    status,
    voteCount,
    contributionCount,
    priority,
    createdAt,
  ]);

  /// Create a copy of RouteSuggestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteSuggestionModelImplCopyWith<_$RouteSuggestionModelImpl>
  get copyWith =>
      __$$RouteSuggestionModelImplCopyWithImpl<_$RouteSuggestionModelImpl>(
        this,
        _$identity,
      );
}

abstract class _RouteSuggestionModel extends RouteSuggestionModel {
  const factory _RouteSuggestionModel({
    required final String id,
    required final String suggestedBy,
    required final String originText,
    final double? originLat,
    final double? originLng,
    required final String destinationText,
    final double? destinationLat,
    final double? destinationLng,
    final String? routeCode,
    final String? operatorName,
    final ServiceType? serviceType,
    final String? detailLevel,
    final String? source,
    final String? notes,
    required final SuggestionStatus status,
    final int voteCount,
    final int contributionCount,
    final Priority priority,
    required final DateTime createdAt,
  }) = _$RouteSuggestionModelImpl;
  const _RouteSuggestionModel._() : super._();

  @override
  String get id;
  @override
  String get suggestedBy;
  @override
  String get originText;
  @override
  double? get originLat;
  @override
  double? get originLng;
  @override
  String get destinationText;
  @override
  double? get destinationLat;
  @override
  double? get destinationLng;
  @override
  String? get routeCode;
  @override
  String? get operatorName;
  @override
  ServiceType? get serviceType;
  @override
  String? get detailLevel;
  @override
  String? get source;
  @override
  String? get notes;
  @override
  SuggestionStatus get status;
  @override
  int get voteCount;
  @override
  int get contributionCount;
  @override
  Priority get priority;
  @override
  DateTime get createdAt;

  /// Create a copy of RouteSuggestionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteSuggestionModelImplCopyWith<_$RouteSuggestionModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
