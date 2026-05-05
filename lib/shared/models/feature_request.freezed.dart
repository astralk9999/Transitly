// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FeatureRequest _$FeatureRequestFromJson(Map<String, dynamic> json) {
  return _FeatureRequest.fromJson(json);
}

/// @nodoc
mixin _$FeatureRequest {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get submittedBy => throw _privateConstructorUsedError;
  FeatureRequestCategory get category => throw _privateConstructorUsedError;
  FeatureRequestPriority get priority => throw _privateConstructorUsedError;
  FeatureRequestStatus get status => throw _privateConstructorUsedError;
  int get votes => throw _privateConstructorUsedError;
  Map<String, dynamic>? get payload => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get adminNotes => throw _privateConstructorUsedError;
  String? get assigneeId => throw _privateConstructorUsedError;

  /// Serializes this FeatureRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeatureRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeatureRequestCopyWith<FeatureRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeatureRequestCopyWith<$Res> {
  factory $FeatureRequestCopyWith(
    FeatureRequest value,
    $Res Function(FeatureRequest) then,
  ) = _$FeatureRequestCopyWithImpl<$Res, FeatureRequest>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String submittedBy,
    FeatureRequestCategory category,
    FeatureRequestPriority priority,
    FeatureRequestStatus status,
    int votes,
    Map<String, dynamic>? payload,
    DateTime createdAt,
    DateTime updatedAt,
    String? adminNotes,
    String? assigneeId,
  });
}

/// @nodoc
class _$FeatureRequestCopyWithImpl<$Res, $Val extends FeatureRequest>
    implements $FeatureRequestCopyWith<$Res> {
  _$FeatureRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeatureRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? submittedBy = null,
    Object? category = null,
    Object? priority = null,
    Object? status = null,
    Object? votes = null,
    Object? payload = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? adminNotes = freezed,
    Object? assigneeId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            submittedBy: null == submittedBy
                ? _value.submittedBy
                : submittedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as FeatureRequestCategory,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as FeatureRequestPriority,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as FeatureRequestStatus,
            votes: null == votes
                ? _value.votes
                : votes // ignore: cast_nullable_to_non_nullable
                      as int,
            payload: freezed == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            adminNotes: freezed == adminNotes
                ? _value.adminNotes
                : adminNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            assigneeId: freezed == assigneeId
                ? _value.assigneeId
                : assigneeId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeatureRequestImplCopyWith<$Res>
    implements $FeatureRequestCopyWith<$Res> {
  factory _$$FeatureRequestImplCopyWith(
    _$FeatureRequestImpl value,
    $Res Function(_$FeatureRequestImpl) then,
  ) = __$$FeatureRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String submittedBy,
    FeatureRequestCategory category,
    FeatureRequestPriority priority,
    FeatureRequestStatus status,
    int votes,
    Map<String, dynamic>? payload,
    DateTime createdAt,
    DateTime updatedAt,
    String? adminNotes,
    String? assigneeId,
  });
}

/// @nodoc
class __$$FeatureRequestImplCopyWithImpl<$Res>
    extends _$FeatureRequestCopyWithImpl<$Res, _$FeatureRequestImpl>
    implements _$$FeatureRequestImplCopyWith<$Res> {
  __$$FeatureRequestImplCopyWithImpl(
    _$FeatureRequestImpl _value,
    $Res Function(_$FeatureRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeatureRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? submittedBy = null,
    Object? category = null,
    Object? priority = null,
    Object? status = null,
    Object? votes = null,
    Object? payload = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? adminNotes = freezed,
    Object? assigneeId = freezed,
  }) {
    return _then(
      _$FeatureRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        submittedBy: null == submittedBy
            ? _value.submittedBy
            : submittedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as FeatureRequestCategory,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as FeatureRequestPriority,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as FeatureRequestStatus,
        votes: null == votes
            ? _value.votes
            : votes // ignore: cast_nullable_to_non_nullable
                  as int,
        payload: freezed == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        adminNotes: freezed == adminNotes
            ? _value.adminNotes
            : adminNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        assigneeId: freezed == assigneeId
            ? _value.assigneeId
            : assigneeId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeatureRequestImpl implements _FeatureRequest {
  const _$FeatureRequestImpl({
    required this.id,
    required this.title,
    required this.description,
    required this.submittedBy,
    required this.category,
    this.priority = FeatureRequestPriority.normal,
    this.status = FeatureRequestStatus.open,
    this.votes = 0,
    final Map<String, dynamic>? payload,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
    this.assigneeId,
  }) : _payload = payload;

  factory _$FeatureRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeatureRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String submittedBy;
  @override
  final FeatureRequestCategory category;
  @override
  @JsonKey()
  final FeatureRequestPriority priority;
  @override
  @JsonKey()
  final FeatureRequestStatus status;
  @override
  @JsonKey()
  final int votes;
  final Map<String, dynamic>? _payload;
  @override
  Map<String, dynamic>? get payload {
    final value = _payload;
    if (value == null) return null;
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? adminNotes;
  @override
  final String? assigneeId;

  @override
  String toString() {
    return 'FeatureRequest(id: $id, title: $title, description: $description, submittedBy: $submittedBy, category: $category, priority: $priority, status: $status, votes: $votes, payload: $payload, createdAt: $createdAt, updatedAt: $updatedAt, adminNotes: $adminNotes, assigneeId: $assigneeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeatureRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.submittedBy, submittedBy) ||
                other.submittedBy == submittedBy) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.votes, votes) || other.votes == votes) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.adminNotes, adminNotes) ||
                other.adminNotes == adminNotes) &&
            (identical(other.assigneeId, assigneeId) ||
                other.assigneeId == assigneeId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    submittedBy,
    category,
    priority,
    status,
    votes,
    const DeepCollectionEquality().hash(_payload),
    createdAt,
    updatedAt,
    adminNotes,
    assigneeId,
  );

  /// Create a copy of FeatureRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeatureRequestImplCopyWith<_$FeatureRequestImpl> get copyWith =>
      __$$FeatureRequestImplCopyWithImpl<_$FeatureRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FeatureRequestImplToJson(this);
  }
}

abstract class _FeatureRequest implements FeatureRequest {
  const factory _FeatureRequest({
    required final String id,
    required final String title,
    required final String description,
    required final String submittedBy,
    required final FeatureRequestCategory category,
    final FeatureRequestPriority priority,
    final FeatureRequestStatus status,
    final int votes,
    final Map<String, dynamic>? payload,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? adminNotes,
    final String? assigneeId,
  }) = _$FeatureRequestImpl;

  factory _FeatureRequest.fromJson(Map<String, dynamic> json) =
      _$FeatureRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get submittedBy;
  @override
  FeatureRequestCategory get category;
  @override
  FeatureRequestPriority get priority;
  @override
  FeatureRequestStatus get status;
  @override
  int get votes;
  @override
  Map<String, dynamic>? get payload;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get adminNotes;
  @override
  String? get assigneeId;

  /// Create a copy of FeatureRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeatureRequestImplCopyWith<_$FeatureRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
