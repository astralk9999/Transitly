// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_card_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserCardModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get cardNumber => throw _privateConstructorUsedError;
  String get operatorId => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;
  String get cardType => throw _privateConstructorUsedError;

  /// Create a copy of UserCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCardModelCopyWith<UserCardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCardModelCopyWith<$Res> {
  factory $UserCardModelCopyWith(
    UserCardModel value,
    $Res Function(UserCardModel) then,
  ) = _$UserCardModelCopyWithImpl<$Res, UserCardModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String cardNumber,
    String operatorId,
    double balance,
    String cardType,
  });
}

/// @nodoc
class _$UserCardModelCopyWithImpl<$Res, $Val extends UserCardModel>
    implements $UserCardModelCopyWith<$Res> {
  _$UserCardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cardNumber = null,
    Object? operatorId = null,
    Object? balance = null,
    Object? cardType = null,
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
            cardNumber: null == cardNumber
                ? _value.cardNumber
                : cardNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            operatorId: null == operatorId
                ? _value.operatorId
                : operatorId // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
            cardType: null == cardType
                ? _value.cardType
                : cardType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserCardModelImplCopyWith<$Res>
    implements $UserCardModelCopyWith<$Res> {
  factory _$$UserCardModelImplCopyWith(
    _$UserCardModelImpl value,
    $Res Function(_$UserCardModelImpl) then,
  ) = __$$UserCardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String cardNumber,
    String operatorId,
    double balance,
    String cardType,
  });
}

/// @nodoc
class __$$UserCardModelImplCopyWithImpl<$Res>
    extends _$UserCardModelCopyWithImpl<$Res, _$UserCardModelImpl>
    implements _$$UserCardModelImplCopyWith<$Res> {
  __$$UserCardModelImplCopyWithImpl(
    _$UserCardModelImpl _value,
    $Res Function(_$UserCardModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cardNumber = null,
    Object? operatorId = null,
    Object? balance = null,
    Object? cardType = null,
  }) {
    return _then(
      _$UserCardModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        cardNumber: null == cardNumber
            ? _value.cardNumber
            : cardNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        operatorId: null == operatorId
            ? _value.operatorId
            : operatorId // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        cardType: null == cardType
            ? _value.cardType
            : cardType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UserCardModelImpl extends _UserCardModel {
  const _$UserCardModelImpl({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.operatorId,
    required this.balance,
    required this.cardType,
  }) : super._();

  @override
  final String id;
  @override
  final String userId;
  @override
  final String cardNumber;
  @override
  final String operatorId;
  @override
  final double balance;
  @override
  final String cardType;

  @override
  String toString() {
    return 'UserCardModel(id: $id, userId: $userId, cardNumber: $cardNumber, operatorId: $operatorId, balance: $balance, cardType: $cardType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCardModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.cardNumber, cardNumber) ||
                other.cardNumber == cardNumber) &&
            (identical(other.operatorId, operatorId) ||
                other.operatorId == operatorId) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.cardType, cardType) ||
                other.cardType == cardType));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    cardNumber,
    operatorId,
    balance,
    cardType,
  );

  /// Create a copy of UserCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCardModelImplCopyWith<_$UserCardModelImpl> get copyWith =>
      __$$UserCardModelImplCopyWithImpl<_$UserCardModelImpl>(this, _$identity);
}

abstract class _UserCardModel extends UserCardModel {
  const factory _UserCardModel({
    required final String id,
    required final String userId,
    required final String cardNumber,
    required final String operatorId,
    required final double balance,
    required final String cardType,
  }) = _$UserCardModelImpl;
  const _UserCardModel._() : super._();

  @override
  String get id;
  @override
  String get userId;
  @override
  String get cardNumber;
  @override
  String get operatorId;
  @override
  double get balance;
  @override
  String get cardType;

  /// Create a copy of UserCardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCardModelImplCopyWith<_$UserCardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
