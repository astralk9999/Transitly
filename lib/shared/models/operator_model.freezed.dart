// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operator_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OperatorModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get shortName => throw _privateConstructorUsedError;
  String get region => throw _privateConstructorUsedError;
  String get website => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;

  /// Create a copy of OperatorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OperatorModelCopyWith<OperatorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OperatorModelCopyWith<$Res> {
  factory $OperatorModelCopyWith(
    OperatorModel value,
    $Res Function(OperatorModel) then,
  ) = _$OperatorModelCopyWithImpl<$Res, OperatorModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String shortName,
    String region,
    String website,
    String phone,
  });
}

/// @nodoc
class _$OperatorModelCopyWithImpl<$Res, $Val extends OperatorModel>
    implements $OperatorModelCopyWith<$Res> {
  _$OperatorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OperatorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = null,
    Object? region = null,
    Object? website = null,
    Object? phone = null,
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
            shortName: null == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                      as String,
            region: null == region
                ? _value.region
                : region // ignore: cast_nullable_to_non_nullable
                      as String,
            website: null == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OperatorModelImplCopyWith<$Res>
    implements $OperatorModelCopyWith<$Res> {
  factory _$$OperatorModelImplCopyWith(
    _$OperatorModelImpl value,
    $Res Function(_$OperatorModelImpl) then,
  ) = __$$OperatorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String shortName,
    String region,
    String website,
    String phone,
  });
}

/// @nodoc
class __$$OperatorModelImplCopyWithImpl<$Res>
    extends _$OperatorModelCopyWithImpl<$Res, _$OperatorModelImpl>
    implements _$$OperatorModelImplCopyWith<$Res> {
  __$$OperatorModelImplCopyWithImpl(
    _$OperatorModelImpl _value,
    $Res Function(_$OperatorModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OperatorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = null,
    Object? region = null,
    Object? website = null,
    Object? phone = null,
  }) {
    return _then(
      _$OperatorModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shortName: null == shortName
            ? _value.shortName
            : shortName // ignore: cast_nullable_to_non_nullable
                  as String,
        region: null == region
            ? _value.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        website: null == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OperatorModelImpl extends _OperatorModel {
  const _$OperatorModelImpl({
    required this.id,
    required this.name,
    required this.shortName,
    required this.region,
    this.website = '',
    this.phone = '',
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String shortName;
  @override
  final String region;
  @override
  @JsonKey()
  final String website;
  @override
  @JsonKey()
  final String phone;

  @override
  String toString() {
    return 'OperatorModel(id: $id, name: $name, shortName: $shortName, region: $region, website: $website, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperatorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.phone, phone) || other.phone == phone));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, shortName, region, website, phone);

  /// Create a copy of OperatorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperatorModelImplCopyWith<_$OperatorModelImpl> get copyWith =>
      __$$OperatorModelImplCopyWithImpl<_$OperatorModelImpl>(this, _$identity);
}

abstract class _OperatorModel extends OperatorModel {
  const factory _OperatorModel({
    required final String id,
    required final String name,
    required final String shortName,
    required final String region,
    final String website,
    final String phone,
  }) = _$OperatorModelImpl;
  const _OperatorModel._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get shortName;
  @override
  String get region;
  @override
  String get website;
  @override
  String get phone;

  /// Create a copy of OperatorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperatorModelImplCopyWith<_$OperatorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
