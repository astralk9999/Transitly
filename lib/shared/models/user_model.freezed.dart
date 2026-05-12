// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @Deprecated('Use role instead')
  List<String> get roles => throw _privateConstructorUsedError;
  UserRole get role => throw _privateConstructorUsedError;
  List<String> get driverOperatorIds => throw _privateConstructorUsedError;
  String? get primaryZoneId => throw _privateConstructorUsedError;
  int get reputationScore => throw _privateConstructorUsedError;
  ReputationLevel get reputationLevel => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String email,
    @Deprecated('Use role instead') List<String> roles,
    UserRole role,
    List<String> driverOperatorIds,
    String? primaryZoneId,
    int reputationScore,
    ReputationLevel reputationLevel,
  });
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? roles = null,
    Object? role = null,
    Object? driverOperatorIds = null,
    Object? primaryZoneId = freezed,
    Object? reputationScore = null,
    Object? reputationLevel = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as UserRole,
            driverOperatorIds: null == driverOperatorIds
                ? _value.driverOperatorIds
                : driverOperatorIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            primaryZoneId: freezed == primaryZoneId
                ? _value.primaryZoneId
                : primaryZoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            reputationScore: null == reputationScore
                ? _value.reputationScore
                : reputationScore // ignore: cast_nullable_to_non_nullable
                      as int,
            reputationLevel: null == reputationLevel
                ? _value.reputationLevel
                : reputationLevel // ignore: cast_nullable_to_non_nullable
                      as ReputationLevel,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String email,
    @Deprecated('Use role instead') List<String> roles,
    UserRole role,
    List<String> driverOperatorIds,
    String? primaryZoneId,
    int reputationScore,
    ReputationLevel reputationLevel,
  });
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? roles = null,
    Object? role = null,
    Object? driverOperatorIds = null,
    Object? primaryZoneId = freezed,
    Object? reputationScore = null,
    Object? reputationLevel = null,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as UserRole,
        driverOperatorIds: null == driverOperatorIds
            ? _value._driverOperatorIds
            : driverOperatorIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        primaryZoneId: freezed == primaryZoneId
            ? _value.primaryZoneId
            : primaryZoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        reputationScore: null == reputationScore
            ? _value.reputationScore
            : reputationScore // ignore: cast_nullable_to_non_nullable
                  as int,
        reputationLevel: null == reputationLevel
            ? _value.reputationLevel
            : reputationLevel // ignore: cast_nullable_to_non_nullable
                  as ReputationLevel,
      ),
    );
  }
}

/// @nodoc

class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl({
    required this.id,
    required this.name,
    required this.email,
    @Deprecated('Use role instead') final List<String> roles = const <String>[],
    this.role = UserRole.passenger,
    final List<String> driverOperatorIds = const <String>[],
    this.primaryZoneId,
    this.reputationScore = 0,
    this.reputationLevel = ReputationLevel.new_,
  }) : _roles = roles,
       _driverOperatorIds = driverOperatorIds,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String email;
  final List<String> _roles;
  @override
  @JsonKey()
  @Deprecated('Use role instead')
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  @JsonKey()
  final UserRole role;
  final List<String> _driverOperatorIds;
  @override
  @JsonKey()
  List<String> get driverOperatorIds {
    if (_driverOperatorIds is EqualUnmodifiableListView)
      return _driverOperatorIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_driverOperatorIds);
  }

  @override
  final String? primaryZoneId;
  @override
  @JsonKey()
  final int reputationScore;
  @override
  @JsonKey()
  final ReputationLevel reputationLevel;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, roles: $roles, role: $role, driverOperatorIds: $driverOperatorIds, primaryZoneId: $primaryZoneId, reputationScore: $reputationScore, reputationLevel: $reputationLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(
              other._driverOperatorIds,
              _driverOperatorIds,
            ) &&
            (identical(other.primaryZoneId, primaryZoneId) ||
                other.primaryZoneId == primaryZoneId) &&
            (identical(other.reputationScore, reputationScore) ||
                other.reputationScore == reputationScore) &&
            (identical(other.reputationLevel, reputationLevel) ||
                other.reputationLevel == reputationLevel));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    email,
    const DeepCollectionEquality().hash(_roles),
    role,
    const DeepCollectionEquality().hash(_driverOperatorIds),
    primaryZoneId,
    reputationScore,
    reputationLevel,
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);
}

abstract class _UserModel extends UserModel {
  const factory _UserModel({
    required final String id,
    required final String name,
    required final String email,
    @Deprecated('Use role instead') final List<String> roles,
    final UserRole role,
    final List<String> driverOperatorIds,
    final String? primaryZoneId,
    final int reputationScore,
    final ReputationLevel reputationLevel,
  }) = _$UserModelImpl;
  const _UserModel._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get email;
  @override
  @Deprecated('Use role instead')
  List<String> get roles;
  @override
  UserRole get role;
  @override
  List<String> get driverOperatorIds;
  @override
  String? get primaryZoneId;
  @override
  int get reputationScore;
  @override
  ReputationLevel get reputationLevel;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
