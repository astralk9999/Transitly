// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PendingAction _$PendingActionFromJson(Map<String, dynamic> json) {
  return _PendingAction.fromJson(json);
}

/// @nodoc
mixin _$PendingAction {
  String get id => throw _privateConstructorUsedError;
  PendingActionKind get kind => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get attempts => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;

  /// Serializes this PendingAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PendingAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PendingActionCopyWith<PendingAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PendingActionCopyWith<$Res> {
  factory $PendingActionCopyWith(
    PendingAction value,
    $Res Function(PendingAction) then,
  ) = _$PendingActionCopyWithImpl<$Res, PendingAction>;
  @useResult
  $Res call({
    String id,
    PendingActionKind kind,
    Map<String, dynamic> payload,
    DateTime createdAt,
    int attempts,
    String? lastError,
  });
}

/// @nodoc
class _$PendingActionCopyWithImpl<$Res, $Val extends PendingAction>
    implements $PendingActionCopyWith<$Res> {
  _$PendingActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PendingAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? attempts = null,
    Object? lastError = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as PendingActionKind,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            attempts: null == attempts
                ? _value.attempts
                : attempts // ignore: cast_nullable_to_non_nullable
                      as int,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PendingActionImplCopyWith<$Res>
    implements $PendingActionCopyWith<$Res> {
  factory _$$PendingActionImplCopyWith(
    _$PendingActionImpl value,
    $Res Function(_$PendingActionImpl) then,
  ) = __$$PendingActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PendingActionKind kind,
    Map<String, dynamic> payload,
    DateTime createdAt,
    int attempts,
    String? lastError,
  });
}

/// @nodoc
class __$$PendingActionImplCopyWithImpl<$Res>
    extends _$PendingActionCopyWithImpl<$Res, _$PendingActionImpl>
    implements _$$PendingActionImplCopyWith<$Res> {
  __$$PendingActionImplCopyWithImpl(
    _$PendingActionImpl _value,
    $Res Function(_$PendingActionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PendingAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? attempts = null,
    Object? lastError = freezed,
  }) {
    return _then(
      _$PendingActionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as PendingActionKind,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        attempts: null == attempts
            ? _value.attempts
            : attempts // ignore: cast_nullable_to_non_nullable
                  as int,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PendingActionImpl implements _PendingAction {
  const _$PendingActionImpl({
    required this.id,
    required this.kind,
    final Map<String, dynamic> payload = const <String, dynamic>{},
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  }) : _payload = payload;

  factory _$PendingActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PendingActionImplFromJson(json);

  @override
  final String id;
  @override
  final PendingActionKind kind;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final int attempts;
  @override
  final String? lastError;

  @override
  String toString() {
    return 'PendingAction(id: $id, kind: $kind, payload: $payload, createdAt: $createdAt, attempts: $attempts, lastError: $lastError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    const DeepCollectionEquality().hash(_payload),
    createdAt,
    attempts,
    lastError,
  );

  /// Create a copy of PendingAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingActionImplCopyWith<_$PendingActionImpl> get copyWith =>
      __$$PendingActionImplCopyWithImpl<_$PendingActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PendingActionImplToJson(this);
  }
}

abstract class _PendingAction implements PendingAction {
  const factory _PendingAction({
    required final String id,
    required final PendingActionKind kind,
    final Map<String, dynamic> payload,
    required final DateTime createdAt,
    final int attempts,
    final String? lastError,
  }) = _$PendingActionImpl;

  factory _PendingAction.fromJson(Map<String, dynamic> json) =
      _$PendingActionImpl.fromJson;

  @override
  String get id;
  @override
  PendingActionKind get kind;
  @override
  Map<String, dynamic> get payload;
  @override
  DateTime get createdAt;
  @override
  int get attempts;
  @override
  String? get lastError;

  /// Create a copy of PendingAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PendingActionImplCopyWith<_$PendingActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
