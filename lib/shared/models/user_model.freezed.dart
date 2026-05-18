// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserModel {

 String get id; String get name; String get email;@Deprecated('Use role instead') List<String> get roles; UserRole get role; List<String> get driverOperatorIds; String? get primaryZoneId; int get reputationScore; ReputationLevel get reputationLevel;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.driverOperatorIds, driverOperatorIds)&&(identical(other.primaryZoneId, primaryZoneId) || other.primaryZoneId == primaryZoneId)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.reputationLevel, reputationLevel) || other.reputationLevel == reputationLevel));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,const DeepCollectionEquality().hash(roles),role,const DeepCollectionEquality().hash(driverOperatorIds),primaryZoneId,reputationScore,reputationLevel);

@override
String toString() {
  return 'UserModel(id: $id, name: $name, email: $email, roles: $roles, role: $role, driverOperatorIds: $driverOperatorIds, primaryZoneId: $primaryZoneId, reputationScore: $reputationScore, reputationLevel: $reputationLevel)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email,@Deprecated('Use role instead') List<String> roles, UserRole role, List<String> driverOperatorIds, String? primaryZoneId, int reputationScore, ReputationLevel reputationLevel
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? roles = null,Object? role = null,Object? driverOperatorIds = null,Object? primaryZoneId = freezed,Object? reputationScore = null,Object? reputationLevel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,driverOperatorIds: null == driverOperatorIds ? _self.driverOperatorIds : driverOperatorIds // ignore: cast_nullable_to_non_nullable
as List<String>,primaryZoneId: freezed == primaryZoneId ? _self.primaryZoneId : primaryZoneId // ignore: cast_nullable_to_non_nullable
as String?,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as int,reputationLevel: null == reputationLevel ? _self.reputationLevel : reputationLevel // ignore: cast_nullable_to_non_nullable
as ReputationLevel,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email, @Deprecated('Use role instead')  List<String> roles,  UserRole role,  List<String> driverOperatorIds,  String? primaryZoneId,  int reputationScore,  ReputationLevel reputationLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.roles,_that.role,_that.driverOperatorIds,_that.primaryZoneId,_that.reputationScore,_that.reputationLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email, @Deprecated('Use role instead')  List<String> roles,  UserRole role,  List<String> driverOperatorIds,  String? primaryZoneId,  int reputationScore,  ReputationLevel reputationLevel)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.name,_that.email,_that.roles,_that.role,_that.driverOperatorIds,_that.primaryZoneId,_that.reputationScore,_that.reputationLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email, @Deprecated('Use role instead')  List<String> roles,  UserRole role,  List<String> driverOperatorIds,  String? primaryZoneId,  int reputationScore,  ReputationLevel reputationLevel)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.roles,_that.role,_that.driverOperatorIds,_that.primaryZoneId,_that.reputationScore,_that.reputationLevel);case _:
  return null;

}
}

}

/// @nodoc


class _UserModel extends UserModel {
  const _UserModel({required this.id, required this.name, required this.email, @Deprecated('Use role instead') final  List<String> roles = const <String>[], this.role = UserRole.passenger, final  List<String> driverOperatorIds = const <String>[], this.primaryZoneId, this.reputationScore = 0, this.reputationLevel = ReputationLevel.new_}): _roles = roles,_driverOperatorIds = driverOperatorIds,super._();
  

@override final  String id;
@override final  String name;
@override final  String email;
 final  List<String> _roles;
@override@JsonKey()@Deprecated('Use role instead') List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override@JsonKey() final  UserRole role;
 final  List<String> _driverOperatorIds;
@override@JsonKey() List<String> get driverOperatorIds {
  if (_driverOperatorIds is EqualUnmodifiableListView) return _driverOperatorIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_driverOperatorIds);
}

@override final  String? primaryZoneId;
@override@JsonKey() final  int reputationScore;
@override@JsonKey() final  ReputationLevel reputationLevel;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._driverOperatorIds, _driverOperatorIds)&&(identical(other.primaryZoneId, primaryZoneId) || other.primaryZoneId == primaryZoneId)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.reputationLevel, reputationLevel) || other.reputationLevel == reputationLevel));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,const DeepCollectionEquality().hash(_roles),role,const DeepCollectionEquality().hash(_driverOperatorIds),primaryZoneId,reputationScore,reputationLevel);

@override
String toString() {
  return 'UserModel(id: $id, name: $name, email: $email, roles: $roles, role: $role, driverOperatorIds: $driverOperatorIds, primaryZoneId: $primaryZoneId, reputationScore: $reputationScore, reputationLevel: $reputationLevel)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email,@Deprecated('Use role instead') List<String> roles, UserRole role, List<String> driverOperatorIds, String? primaryZoneId, int reputationScore, ReputationLevel reputationLevel
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? roles = null,Object? role = null,Object? driverOperatorIds = null,Object? primaryZoneId = freezed,Object? reputationScore = null,Object? reputationLevel = null,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,driverOperatorIds: null == driverOperatorIds ? _self._driverOperatorIds : driverOperatorIds // ignore: cast_nullable_to_non_nullable
as List<String>,primaryZoneId: freezed == primaryZoneId ? _self.primaryZoneId : primaryZoneId // ignore: cast_nullable_to_non_nullable
as String?,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as int,reputationLevel: null == reputationLevel ? _self.reputationLevel : reputationLevel // ignore: cast_nullable_to_non_nullable
as ReputationLevel,
  ));
}


}

// dart format on
