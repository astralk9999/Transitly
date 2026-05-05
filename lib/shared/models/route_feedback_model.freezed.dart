// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_feedback_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RouteFeedbackModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;
  String? get stopId => throw _privateConstructorUsedError;
  FeedbackType get feedbackType => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  FeedbackStatus get status => throw _privateConstructorUsedError;
  Priority get autoPriority => throw _privateConstructorUsedError;
  int get similarFeedbackCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of RouteFeedbackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteFeedbackModelCopyWith<RouteFeedbackModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteFeedbackModelCopyWith<$Res> {
  factory $RouteFeedbackModelCopyWith(
    RouteFeedbackModel value,
    $Res Function(RouteFeedbackModel) then,
  ) = _$RouteFeedbackModelCopyWithImpl<$Res, RouteFeedbackModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String routeId,
    String? stopId,
    FeedbackType feedbackType,
    String description,
    List<String> photoUrls,
    FeedbackStatus status,
    Priority autoPriority,
    int similarFeedbackCount,
    DateTime createdAt,
  });
}

/// @nodoc
class _$RouteFeedbackModelCopyWithImpl<$Res, $Val extends RouteFeedbackModel>
    implements $RouteFeedbackModelCopyWith<$Res> {
  _$RouteFeedbackModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteFeedbackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = null,
    Object? stopId = freezed,
    Object? feedbackType = null,
    Object? description = null,
    Object? photoUrls = null,
    Object? status = null,
    Object? autoPriority = null,
    Object? similarFeedbackCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            stopId: freezed == stopId
                ? _value.stopId
                : stopId // ignore: cast_nullable_to_non_nullable
                      as String?,
            feedbackType: null == feedbackType
                ? _value.feedbackType
                : feedbackType // ignore: cast_nullable_to_non_nullable
                      as FeedbackType,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            photoUrls: null == photoUrls
                ? _value.photoUrls
                : photoUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as FeedbackStatus,
            autoPriority: null == autoPriority
                ? _value.autoPriority
                : autoPriority // ignore: cast_nullable_to_non_nullable
                      as Priority,
            similarFeedbackCount: null == similarFeedbackCount
                ? _value.similarFeedbackCount
                : similarFeedbackCount // ignore: cast_nullable_to_non_nullable
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
abstract class _$$RouteFeedbackModelImplCopyWith<$Res>
    implements $RouteFeedbackModelCopyWith<$Res> {
  factory _$$RouteFeedbackModelImplCopyWith(
    _$RouteFeedbackModelImpl value,
    $Res Function(_$RouteFeedbackModelImpl) then,
  ) = __$$RouteFeedbackModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String routeId,
    String? stopId,
    FeedbackType feedbackType,
    String description,
    List<String> photoUrls,
    FeedbackStatus status,
    Priority autoPriority,
    int similarFeedbackCount,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$RouteFeedbackModelImplCopyWithImpl<$Res>
    extends _$RouteFeedbackModelCopyWithImpl<$Res, _$RouteFeedbackModelImpl>
    implements _$$RouteFeedbackModelImplCopyWith<$Res> {
  __$$RouteFeedbackModelImplCopyWithImpl(
    _$RouteFeedbackModelImpl _value,
    $Res Function(_$RouteFeedbackModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteFeedbackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = null,
    Object? stopId = freezed,
    Object? feedbackType = null,
    Object? description = null,
    Object? photoUrls = null,
    Object? status = null,
    Object? autoPriority = null,
    Object? similarFeedbackCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$RouteFeedbackModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        stopId: freezed == stopId
            ? _value.stopId
            : stopId // ignore: cast_nullable_to_non_nullable
                  as String?,
        feedbackType: null == feedbackType
            ? _value.feedbackType
            : feedbackType // ignore: cast_nullable_to_non_nullable
                  as FeedbackType,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        photoUrls: null == photoUrls
            ? _value._photoUrls
            : photoUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as FeedbackStatus,
        autoPriority: null == autoPriority
            ? _value.autoPriority
            : autoPriority // ignore: cast_nullable_to_non_nullable
                  as Priority,
        similarFeedbackCount: null == similarFeedbackCount
            ? _value.similarFeedbackCount
            : similarFeedbackCount // ignore: cast_nullable_to_non_nullable
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

class _$RouteFeedbackModelImpl extends _RouteFeedbackModel {
  const _$RouteFeedbackModelImpl({
    required this.id,
    required this.userId,
    required this.routeId,
    this.stopId,
    required this.feedbackType,
    required this.description,
    final List<String> photoUrls = const <String>[],
    required this.status,
    this.autoPriority = Priority.medium,
    this.similarFeedbackCount = 0,
    required this.createdAt,
  }) : _photoUrls = photoUrls,
       super._();

  @override
  final String id;
  @override
  final String userId;
  @override
  final String routeId;
  @override
  final String? stopId;
  @override
  final FeedbackType feedbackType;
  @override
  final String description;
  final List<String> _photoUrls;
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

  @override
  final FeedbackStatus status;
  @override
  @JsonKey()
  final Priority autoPriority;
  @override
  @JsonKey()
  final int similarFeedbackCount;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'RouteFeedbackModel(id: $id, userId: $userId, routeId: $routeId, stopId: $stopId, feedbackType: $feedbackType, description: $description, photoUrls: $photoUrls, status: $status, autoPriority: $autoPriority, similarFeedbackCount: $similarFeedbackCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteFeedbackModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.stopId, stopId) || other.stopId == stopId) &&
            (identical(other.feedbackType, feedbackType) ||
                other.feedbackType == feedbackType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._photoUrls,
              _photoUrls,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.autoPriority, autoPriority) ||
                other.autoPriority == autoPriority) &&
            (identical(other.similarFeedbackCount, similarFeedbackCount) ||
                other.similarFeedbackCount == similarFeedbackCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    routeId,
    stopId,
    feedbackType,
    description,
    const DeepCollectionEquality().hash(_photoUrls),
    status,
    autoPriority,
    similarFeedbackCount,
    createdAt,
  );

  /// Create a copy of RouteFeedbackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteFeedbackModelImplCopyWith<_$RouteFeedbackModelImpl> get copyWith =>
      __$$RouteFeedbackModelImplCopyWithImpl<_$RouteFeedbackModelImpl>(
        this,
        _$identity,
      );
}

abstract class _RouteFeedbackModel extends RouteFeedbackModel {
  const factory _RouteFeedbackModel({
    required final String id,
    required final String userId,
    required final String routeId,
    final String? stopId,
    required final FeedbackType feedbackType,
    required final String description,
    final List<String> photoUrls,
    required final FeedbackStatus status,
    final Priority autoPriority,
    final int similarFeedbackCount,
    required final DateTime createdAt,
  }) = _$RouteFeedbackModelImpl;
  const _RouteFeedbackModel._() : super._();

  @override
  String get id;
  @override
  String get userId;
  @override
  String get routeId;
  @override
  String? get stopId;
  @override
  FeedbackType get feedbackType;
  @override
  String get description;
  @override
  List<String> get photoUrls;
  @override
  FeedbackStatus get status;
  @override
  Priority get autoPriority;
  @override
  int get similarFeedbackCount;
  @override
  DateTime get createdAt;

  /// Create a copy of RouteFeedbackModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteFeedbackModelImplCopyWith<_$RouteFeedbackModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
