// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operator_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OperatorModel {

 String get id; String get name; String get shortName; String get slug; String get region; String get website; String get contactEmail; String get phone; String get color; bool get isActive;
/// Create a copy of OperatorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperatorModelCopyWith<OperatorModel> get copyWith => _$OperatorModelCopyWithImpl<OperatorModel>(this as OperatorModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperatorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.region, region) || other.region == region)&&(identical(other.website, website) || other.website == website)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,shortName,slug,region,website,contactEmail,phone,color,isActive);

@override
String toString() {
  return 'OperatorModel(id: $id, name: $name, shortName: $shortName, slug: $slug, region: $region, website: $website, contactEmail: $contactEmail, phone: $phone, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $OperatorModelCopyWith<$Res>  {
  factory $OperatorModelCopyWith(OperatorModel value, $Res Function(OperatorModel) _then) = _$OperatorModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String shortName, String slug, String region, String website, String contactEmail, String phone, String color, bool isActive
});




}
/// @nodoc
class _$OperatorModelCopyWithImpl<$Res>
    implements $OperatorModelCopyWith<$Res> {
  _$OperatorModelCopyWithImpl(this._self, this._then);

  final OperatorModel _self;
  final $Res Function(OperatorModel) _then;

/// Create a copy of OperatorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? shortName = null,Object? slug = null,Object? region = null,Object? website = null,Object? contactEmail = null,Object? phone = null,Object? color = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OperatorModel].
extension OperatorModelPatterns on OperatorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperatorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperatorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperatorModel value)  $default,){
final _that = this;
switch (_that) {
case _OperatorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperatorModel value)?  $default,){
final _that = this;
switch (_that) {
case _OperatorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String shortName,  String slug,  String region,  String website,  String contactEmail,  String phone,  String color,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperatorModel() when $default != null:
return $default(_that.id,_that.name,_that.shortName,_that.slug,_that.region,_that.website,_that.contactEmail,_that.phone,_that.color,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String shortName,  String slug,  String region,  String website,  String contactEmail,  String phone,  String color,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _OperatorModel():
return $default(_that.id,_that.name,_that.shortName,_that.slug,_that.region,_that.website,_that.contactEmail,_that.phone,_that.color,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String shortName,  String slug,  String region,  String website,  String contactEmail,  String phone,  String color,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _OperatorModel() when $default != null:
return $default(_that.id,_that.name,_that.shortName,_that.slug,_that.region,_that.website,_that.contactEmail,_that.phone,_that.color,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc


class _OperatorModel extends OperatorModel {
  const _OperatorModel({required this.id, required this.name, required this.shortName, required this.slug, required this.region, this.website = '', this.contactEmail = '', this.phone = '', this.color = '', this.isActive = true}): super._();
  

@override final  String id;
@override final  String name;
@override final  String shortName;
@override final  String slug;
@override final  String region;
@override@JsonKey() final  String website;
@override@JsonKey() final  String contactEmail;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String color;
@override@JsonKey() final  bool isActive;

/// Create a copy of OperatorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperatorModelCopyWith<_OperatorModel> get copyWith => __$OperatorModelCopyWithImpl<_OperatorModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperatorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.region, region) || other.region == region)&&(identical(other.website, website) || other.website == website)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,shortName,slug,region,website,contactEmail,phone,color,isActive);

@override
String toString() {
  return 'OperatorModel(id: $id, name: $name, shortName: $shortName, slug: $slug, region: $region, website: $website, contactEmail: $contactEmail, phone: $phone, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$OperatorModelCopyWith<$Res> implements $OperatorModelCopyWith<$Res> {
  factory _$OperatorModelCopyWith(_OperatorModel value, $Res Function(_OperatorModel) _then) = __$OperatorModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String shortName, String slug, String region, String website, String contactEmail, String phone, String color, bool isActive
});




}
/// @nodoc
class __$OperatorModelCopyWithImpl<$Res>
    implements _$OperatorModelCopyWith<$Res> {
  __$OperatorModelCopyWithImpl(this._self, this._then);

  final _OperatorModel _self;
  final $Res Function(_OperatorModel) _then;

/// Create a copy of OperatorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? shortName = null,Object? slug = null,Object? region = null,Object? website = null,Object? contactEmail = null,Object? phone = null,Object? color = null,Object? isActive = null,}) {
  return _then(_OperatorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
