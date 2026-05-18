// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_invitation_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverInvitationCode {

 String get code; String get operatorId; String get createdBy; int get maxUses; int get uses; DateTime get expiresAt; InvitationKind get kind;
/// Create a copy of DriverInvitationCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverInvitationCodeCopyWith<DriverInvitationCode> get copyWith => _$DriverInvitationCodeCopyWithImpl<DriverInvitationCode>(this as DriverInvitationCode, _$identity);

  /// Serializes this DriverInvitationCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverInvitationCode&&(identical(other.code, code) || other.code == code)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,operatorId,createdBy,maxUses,uses,expiresAt,kind);

@override
String toString() {
  return 'DriverInvitationCode(code: $code, operatorId: $operatorId, createdBy: $createdBy, maxUses: $maxUses, uses: $uses, expiresAt: $expiresAt, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $DriverInvitationCodeCopyWith<$Res>  {
  factory $DriverInvitationCodeCopyWith(DriverInvitationCode value, $Res Function(DriverInvitationCode) _then) = _$DriverInvitationCodeCopyWithImpl;
@useResult
$Res call({
 String code, String operatorId, String createdBy, int maxUses, int uses, DateTime expiresAt, InvitationKind kind
});




}
/// @nodoc
class _$DriverInvitationCodeCopyWithImpl<$Res>
    implements $DriverInvitationCodeCopyWith<$Res> {
  _$DriverInvitationCodeCopyWithImpl(this._self, this._then);

  final DriverInvitationCode _self;
  final $Res Function(DriverInvitationCode) _then;

/// Create a copy of DriverInvitationCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? operatorId = null,Object? createdBy = null,Object? maxUses = null,Object? uses = null,Object? expiresAt = null,Object? kind = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InvitationKind,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverInvitationCode].
extension DriverInvitationCodePatterns on DriverInvitationCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverInvitationCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverInvitationCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverInvitationCode value)  $default,){
final _that = this;
switch (_that) {
case _DriverInvitationCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverInvitationCode value)?  $default,){
final _that = this;
switch (_that) {
case _DriverInvitationCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String operatorId,  String createdBy,  int maxUses,  int uses,  DateTime expiresAt,  InvitationKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverInvitationCode() when $default != null:
return $default(_that.code,_that.operatorId,_that.createdBy,_that.maxUses,_that.uses,_that.expiresAt,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String operatorId,  String createdBy,  int maxUses,  int uses,  DateTime expiresAt,  InvitationKind kind)  $default,) {final _that = this;
switch (_that) {
case _DriverInvitationCode():
return $default(_that.code,_that.operatorId,_that.createdBy,_that.maxUses,_that.uses,_that.expiresAt,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String operatorId,  String createdBy,  int maxUses,  int uses,  DateTime expiresAt,  InvitationKind kind)?  $default,) {final _that = this;
switch (_that) {
case _DriverInvitationCode() when $default != null:
return $default(_that.code,_that.operatorId,_that.createdBy,_that.maxUses,_that.uses,_that.expiresAt,_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverInvitationCode implements DriverInvitationCode {
  const _DriverInvitationCode({required this.code, required this.operatorId, required this.createdBy, this.maxUses = 1, this.uses = 0, required this.expiresAt, this.kind = InvitationKind.driver});
  factory _DriverInvitationCode.fromJson(Map<String, dynamic> json) => _$DriverInvitationCodeFromJson(json);

@override final  String code;
@override final  String operatorId;
@override final  String createdBy;
@override@JsonKey() final  int maxUses;
@override@JsonKey() final  int uses;
@override final  DateTime expiresAt;
@override@JsonKey() final  InvitationKind kind;

/// Create a copy of DriverInvitationCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverInvitationCodeCopyWith<_DriverInvitationCode> get copyWith => __$DriverInvitationCodeCopyWithImpl<_DriverInvitationCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverInvitationCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverInvitationCode&&(identical(other.code, code) || other.code == code)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,operatorId,createdBy,maxUses,uses,expiresAt,kind);

@override
String toString() {
  return 'DriverInvitationCode(code: $code, operatorId: $operatorId, createdBy: $createdBy, maxUses: $maxUses, uses: $uses, expiresAt: $expiresAt, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$DriverInvitationCodeCopyWith<$Res> implements $DriverInvitationCodeCopyWith<$Res> {
  factory _$DriverInvitationCodeCopyWith(_DriverInvitationCode value, $Res Function(_DriverInvitationCode) _then) = __$DriverInvitationCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, String operatorId, String createdBy, int maxUses, int uses, DateTime expiresAt, InvitationKind kind
});




}
/// @nodoc
class __$DriverInvitationCodeCopyWithImpl<$Res>
    implements _$DriverInvitationCodeCopyWith<$Res> {
  __$DriverInvitationCodeCopyWithImpl(this._self, this._then);

  final _DriverInvitationCode _self;
  final $Res Function(_DriverInvitationCode) _then;

/// Create a copy of DriverInvitationCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? operatorId = null,Object? createdBy = null,Object? maxUses = null,Object? uses = null,Object? expiresAt = null,Object? kind = null,}) {
  return _then(_DriverInvitationCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InvitationKind,
  ));
}


}

// dart format on
