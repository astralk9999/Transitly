// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_card_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserCardModel {

 String get id; String get userId; String get cardNumber; String get operatorId; double get balance; String get cardType;
/// Create a copy of UserCardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCardModelCopyWith<UserCardModel> get copyWith => _$UserCardModelCopyWithImpl<UserCardModel>(this as UserCardModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.cardType, cardType) || other.cardType == cardType));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,cardNumber,operatorId,balance,cardType);

@override
String toString() {
  return 'UserCardModel(id: $id, userId: $userId, cardNumber: $cardNumber, operatorId: $operatorId, balance: $balance, cardType: $cardType)';
}


}

/// @nodoc
abstract mixin class $UserCardModelCopyWith<$Res>  {
  factory $UserCardModelCopyWith(UserCardModel value, $Res Function(UserCardModel) _then) = _$UserCardModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String cardNumber, String operatorId, double balance, String cardType
});




}
/// @nodoc
class _$UserCardModelCopyWithImpl<$Res>
    implements $UserCardModelCopyWith<$Res> {
  _$UserCardModelCopyWithImpl(this._self, this._then);

  final UserCardModel _self;
  final $Res Function(UserCardModel) _then;

/// Create a copy of UserCardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? cardNumber = null,Object? operatorId = null,Object? balance = null,Object? cardType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserCardModel].
extension UserCardModelPatterns on UserCardModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCardModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCardModel value)  $default,){
final _that = this;
switch (_that) {
case _UserCardModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCardModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserCardModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String cardNumber,  String operatorId,  double balance,  String cardType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCardModel() when $default != null:
return $default(_that.id,_that.userId,_that.cardNumber,_that.operatorId,_that.balance,_that.cardType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String cardNumber,  String operatorId,  double balance,  String cardType)  $default,) {final _that = this;
switch (_that) {
case _UserCardModel():
return $default(_that.id,_that.userId,_that.cardNumber,_that.operatorId,_that.balance,_that.cardType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String cardNumber,  String operatorId,  double balance,  String cardType)?  $default,) {final _that = this;
switch (_that) {
case _UserCardModel() when $default != null:
return $default(_that.id,_that.userId,_that.cardNumber,_that.operatorId,_that.balance,_that.cardType);case _:
  return null;

}
}

}

/// @nodoc


class _UserCardModel extends UserCardModel {
  const _UserCardModel({required this.id, required this.userId, required this.cardNumber, required this.operatorId, required this.balance, required this.cardType}): super._();
  

@override final  String id;
@override final  String userId;
@override final  String cardNumber;
@override final  String operatorId;
@override final  double balance;
@override final  String cardType;

/// Create a copy of UserCardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCardModelCopyWith<_UserCardModel> get copyWith => __$UserCardModelCopyWithImpl<_UserCardModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.cardType, cardType) || other.cardType == cardType));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,cardNumber,operatorId,balance,cardType);

@override
String toString() {
  return 'UserCardModel(id: $id, userId: $userId, cardNumber: $cardNumber, operatorId: $operatorId, balance: $balance, cardType: $cardType)';
}


}

/// @nodoc
abstract mixin class _$UserCardModelCopyWith<$Res> implements $UserCardModelCopyWith<$Res> {
  factory _$UserCardModelCopyWith(_UserCardModel value, $Res Function(_UserCardModel) _then) = __$UserCardModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String cardNumber, String operatorId, double balance, String cardType
});




}
/// @nodoc
class __$UserCardModelCopyWithImpl<$Res>
    implements _$UserCardModelCopyWith<$Res> {
  __$UserCardModelCopyWithImpl(this._self, this._then);

  final _UserCardModel _self;
  final $Res Function(_UserCardModel) _then;

/// Create a copy of UserCardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? cardNumber = null,Object? operatorId = null,Object? balance = null,Object? cardType = null,}) {
  return _then(_UserCardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
