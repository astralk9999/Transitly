// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_invitation_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DriverInvitationCode _$DriverInvitationCodeFromJson(Map<String, dynamic> json) {
  return _DriverInvitationCode.fromJson(json);
}

/// @nodoc
mixin _$DriverInvitationCode {
  String get code => throw _privateConstructorUsedError;
  String get operatorId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  int get maxUses => throw _privateConstructorUsedError;
  int get uses => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  InvitationKind get kind => throw _privateConstructorUsedError;

  /// Serializes this DriverInvitationCode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DriverInvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriverInvitationCodeCopyWith<DriverInvitationCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriverInvitationCodeCopyWith<$Res> {
  factory $DriverInvitationCodeCopyWith(
    DriverInvitationCode value,
    $Res Function(DriverInvitationCode) then,
  ) = _$DriverInvitationCodeCopyWithImpl<$Res, DriverInvitationCode>;
  @useResult
  $Res call({
    String code,
    String operatorId,
    String createdBy,
    int maxUses,
    int uses,
    DateTime expiresAt,
    InvitationKind kind,
  });
}

/// @nodoc
class _$DriverInvitationCodeCopyWithImpl<
  $Res,
  $Val extends DriverInvitationCode
>
    implements $DriverInvitationCodeCopyWith<$Res> {
  _$DriverInvitationCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriverInvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? operatorId = null,
    Object? createdBy = null,
    Object? maxUses = null,
    Object? uses = null,
    Object? expiresAt = null,
    Object? kind = null,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            operatorId: null == operatorId
                ? _value.operatorId
                : operatorId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            maxUses: null == maxUses
                ? _value.maxUses
                : maxUses // ignore: cast_nullable_to_non_nullable
                      as int,
            uses: null == uses
                ? _value.uses
                : uses // ignore: cast_nullable_to_non_nullable
                      as int,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as InvitationKind,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DriverInvitationCodeImplCopyWith<$Res>
    implements $DriverInvitationCodeCopyWith<$Res> {
  factory _$$DriverInvitationCodeImplCopyWith(
    _$DriverInvitationCodeImpl value,
    $Res Function(_$DriverInvitationCodeImpl) then,
  ) = __$$DriverInvitationCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String operatorId,
    String createdBy,
    int maxUses,
    int uses,
    DateTime expiresAt,
    InvitationKind kind,
  });
}

/// @nodoc
class __$$DriverInvitationCodeImplCopyWithImpl<$Res>
    extends _$DriverInvitationCodeCopyWithImpl<$Res, _$DriverInvitationCodeImpl>
    implements _$$DriverInvitationCodeImplCopyWith<$Res> {
  __$$DriverInvitationCodeImplCopyWithImpl(
    _$DriverInvitationCodeImpl _value,
    $Res Function(_$DriverInvitationCodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriverInvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? operatorId = null,
    Object? createdBy = null,
    Object? maxUses = null,
    Object? uses = null,
    Object? expiresAt = null,
    Object? kind = null,
  }) {
    return _then(
      _$DriverInvitationCodeImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        operatorId: null == operatorId
            ? _value.operatorId
            : operatorId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        maxUses: null == maxUses
            ? _value.maxUses
            : maxUses // ignore: cast_nullable_to_non_nullable
                  as int,
        uses: null == uses
            ? _value.uses
            : uses // ignore: cast_nullable_to_non_nullable
                  as int,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as InvitationKind,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DriverInvitationCodeImpl implements _DriverInvitationCode {
  const _$DriverInvitationCodeImpl({
    required this.code,
    required this.operatorId,
    required this.createdBy,
    this.maxUses = 1,
    this.uses = 0,
    required this.expiresAt,
    this.kind = InvitationKind.driver,
  });

  factory _$DriverInvitationCodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriverInvitationCodeImplFromJson(json);

  @override
  final String code;
  @override
  final String operatorId;
  @override
  final String createdBy;
  @override
  @JsonKey()
  final int maxUses;
  @override
  @JsonKey()
  final int uses;
  @override
  final DateTime expiresAt;
  @override
  @JsonKey()
  final InvitationKind kind;

  @override
  String toString() {
    return 'DriverInvitationCode(code: $code, operatorId: $operatorId, createdBy: $createdBy, maxUses: $maxUses, uses: $uses, expiresAt: $expiresAt, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriverInvitationCodeImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.operatorId, operatorId) ||
                other.operatorId == operatorId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.maxUses, maxUses) || other.maxUses == maxUses) &&
            (identical(other.uses, uses) || other.uses == uses) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    operatorId,
    createdBy,
    maxUses,
    uses,
    expiresAt,
    kind,
  );

  /// Create a copy of DriverInvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriverInvitationCodeImplCopyWith<_$DriverInvitationCodeImpl>
  get copyWith =>
      __$$DriverInvitationCodeImplCopyWithImpl<_$DriverInvitationCodeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DriverInvitationCodeImplToJson(this);
  }
}

abstract class _DriverInvitationCode implements DriverInvitationCode {
  const factory _DriverInvitationCode({
    required final String code,
    required final String operatorId,
    required final String createdBy,
    final int maxUses,
    final int uses,
    required final DateTime expiresAt,
    final InvitationKind kind,
  }) = _$DriverInvitationCodeImpl;

  factory _DriverInvitationCode.fromJson(Map<String, dynamic> json) =
      _$DriverInvitationCodeImpl.fromJson;

  @override
  String get code;
  @override
  String get operatorId;
  @override
  String get createdBy;
  @override
  int get maxUses;
  @override
  int get uses;
  @override
  DateTime get expiresAt;
  @override
  InvitationKind get kind;

  /// Create a copy of DriverInvitationCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriverInvitationCodeImplCopyWith<_$DriverInvitationCodeImpl>
  get copyWith => throw _privateConstructorUsedError;
}
