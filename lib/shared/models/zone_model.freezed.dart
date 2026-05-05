// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zone_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ZoneModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get zoneType => throw _privateConstructorUsedError;
  String? get parentZoneId => throw _privateConstructorUsedError;

  /// Create a copy of ZoneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ZoneModelCopyWith<ZoneModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ZoneModelCopyWith<$Res> {
  factory $ZoneModelCopyWith(ZoneModel value, $Res Function(ZoneModel) then) =
      _$ZoneModelCopyWithImpl<$Res, ZoneModel>;
  @useResult
  $Res call({String id, String name, String zoneType, String? parentZoneId});
}

/// @nodoc
class _$ZoneModelCopyWithImpl<$Res, $Val extends ZoneModel>
    implements $ZoneModelCopyWith<$Res> {
  _$ZoneModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ZoneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? zoneType = null,
    Object? parentZoneId = freezed,
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
            zoneType: null == zoneType
                ? _value.zoneType
                : zoneType // ignore: cast_nullable_to_non_nullable
                      as String,
            parentZoneId: freezed == parentZoneId
                ? _value.parentZoneId
                : parentZoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ZoneModelImplCopyWith<$Res>
    implements $ZoneModelCopyWith<$Res> {
  factory _$$ZoneModelImplCopyWith(
    _$ZoneModelImpl value,
    $Res Function(_$ZoneModelImpl) then,
  ) = __$$ZoneModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String zoneType, String? parentZoneId});
}

/// @nodoc
class __$$ZoneModelImplCopyWithImpl<$Res>
    extends _$ZoneModelCopyWithImpl<$Res, _$ZoneModelImpl>
    implements _$$ZoneModelImplCopyWith<$Res> {
  __$$ZoneModelImplCopyWithImpl(
    _$ZoneModelImpl _value,
    $Res Function(_$ZoneModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ZoneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? zoneType = null,
    Object? parentZoneId = freezed,
  }) {
    return _then(
      _$ZoneModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        zoneType: null == zoneType
            ? _value.zoneType
            : zoneType // ignore: cast_nullable_to_non_nullable
                  as String,
        parentZoneId: freezed == parentZoneId
            ? _value.parentZoneId
            : parentZoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ZoneModelImpl extends _ZoneModel {
  const _$ZoneModelImpl({
    required this.id,
    required this.name,
    required this.zoneType,
    this.parentZoneId,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String zoneType;
  @override
  final String? parentZoneId;

  @override
  String toString() {
    return 'ZoneModel(id: $id, name: $name, zoneType: $zoneType, parentZoneId: $parentZoneId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ZoneModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.zoneType, zoneType) ||
                other.zoneType == zoneType) &&
            (identical(other.parentZoneId, parentZoneId) ||
                other.parentZoneId == parentZoneId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, zoneType, parentZoneId);

  /// Create a copy of ZoneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ZoneModelImplCopyWith<_$ZoneModelImpl> get copyWith =>
      __$$ZoneModelImplCopyWithImpl<_$ZoneModelImpl>(this, _$identity);
}

abstract class _ZoneModel extends ZoneModel {
  const factory _ZoneModel({
    required final String id,
    required final String name,
    required final String zoneType,
    final String? parentZoneId,
  }) = _$ZoneModelImpl;
  const _ZoneModel._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get zoneType;
  @override
  String? get parentZoneId;

  /// Create a copy of ZoneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ZoneModelImplCopyWith<_$ZoneModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
