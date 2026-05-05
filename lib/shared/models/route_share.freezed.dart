// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteShare _$RouteShareFromJson(Map<String, dynamic> json) {
  return _RouteShare.fromJson(json);
}

/// @nodoc
mixin _$RouteShare {
  String get routeId => throw _privateConstructorUsedError;
  String get sharedWithId => throw _privateConstructorUsedError;
  String get sharedById => throw _privateConstructorUsedError;
  RouteSharePermission get permission => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this RouteShare to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteShareCopyWith<RouteShare> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteShareCopyWith<$Res> {
  factory $RouteShareCopyWith(
    RouteShare value,
    $Res Function(RouteShare) then,
  ) = _$RouteShareCopyWithImpl<$Res, RouteShare>;
  @useResult
  $Res call({
    String routeId,
    String sharedWithId,
    String sharedById,
    RouteSharePermission permission,
    DateTime createdAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class _$RouteShareCopyWithImpl<$Res, $Val extends RouteShare>
    implements $RouteShareCopyWith<$Res> {
  _$RouteShareCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? sharedWithId = null,
    Object? sharedById = null,
    Object? permission = null,
    Object? createdAt = null,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            sharedWithId: null == sharedWithId
                ? _value.sharedWithId
                : sharedWithId // ignore: cast_nullable_to_non_nullable
                      as String,
            sharedById: null == sharedById
                ? _value.sharedById
                : sharedById // ignore: cast_nullable_to_non_nullable
                      as String,
            permission: null == permission
                ? _value.permission
                : permission // ignore: cast_nullable_to_non_nullable
                      as RouteSharePermission,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteShareImplCopyWith<$Res>
    implements $RouteShareCopyWith<$Res> {
  factory _$$RouteShareImplCopyWith(
    _$RouteShareImpl value,
    $Res Function(_$RouteShareImpl) then,
  ) = __$$RouteShareImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String routeId,
    String sharedWithId,
    String sharedById,
    RouteSharePermission permission,
    DateTime createdAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class __$$RouteShareImplCopyWithImpl<$Res>
    extends _$RouteShareCopyWithImpl<$Res, _$RouteShareImpl>
    implements _$$RouteShareImplCopyWith<$Res> {
  __$$RouteShareImplCopyWithImpl(
    _$RouteShareImpl _value,
    $Res Function(_$RouteShareImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? sharedWithId = null,
    Object? sharedById = null,
    Object? permission = null,
    Object? createdAt = null,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _$RouteShareImpl(
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        sharedWithId: null == sharedWithId
            ? _value.sharedWithId
            : sharedWithId // ignore: cast_nullable_to_non_nullable
                  as String,
        sharedById: null == sharedById
            ? _value.sharedById
            : sharedById // ignore: cast_nullable_to_non_nullable
                  as String,
        permission: null == permission
            ? _value.permission
            : permission // ignore: cast_nullable_to_non_nullable
                  as RouteSharePermission,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteShareImpl implements _RouteShare {
  const _$RouteShareImpl({
    required this.routeId,
    required this.sharedWithId,
    required this.sharedById,
    this.permission = RouteSharePermission.view,
    required this.createdAt,
    this.expiresAt,
  });

  factory _$RouteShareImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteShareImplFromJson(json);

  @override
  final String routeId;
  @override
  final String sharedWithId;
  @override
  final String sharedById;
  @override
  @JsonKey()
  final RouteSharePermission permission;
  @override
  final DateTime createdAt;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'RouteShare(routeId: $routeId, sharedWithId: $sharedWithId, sharedById: $sharedById, permission: $permission, createdAt: $createdAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteShareImpl &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.sharedWithId, sharedWithId) ||
                other.sharedWithId == sharedWithId) &&
            (identical(other.sharedById, sharedById) ||
                other.sharedById == sharedById) &&
            (identical(other.permission, permission) ||
                other.permission == permission) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    routeId,
    sharedWithId,
    sharedById,
    permission,
    createdAt,
    expiresAt,
  );

  /// Create a copy of RouteShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteShareImplCopyWith<_$RouteShareImpl> get copyWith =>
      __$$RouteShareImplCopyWithImpl<_$RouteShareImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteShareImplToJson(this);
  }
}

abstract class _RouteShare implements RouteShare {
  const factory _RouteShare({
    required final String routeId,
    required final String sharedWithId,
    required final String sharedById,
    final RouteSharePermission permission,
    required final DateTime createdAt,
    final DateTime? expiresAt,
  }) = _$RouteShareImpl;

  factory _RouteShare.fromJson(Map<String, dynamic> json) =
      _$RouteShareImpl.fromJson;

  @override
  String get routeId;
  @override
  String get sharedWithId;
  @override
  String get sharedById;
  @override
  RouteSharePermission get permission;
  @override
  DateTime get createdAt;
  @override
  DateTime? get expiresAt;

  /// Create a copy of RouteShare
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteShareImplCopyWith<_$RouteShareImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
