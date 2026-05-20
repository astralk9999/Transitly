// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_changelog_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteChangelogModel {

 String get id; String get routeId; ChangeType get changeType; String get description; String get changedBy; DateTime get createdAt;
/// Create a copy of RouteChangelogModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteChangelogModelCopyWith<RouteChangelogModel> get copyWith => _$RouteChangelogModelCopyWithImpl<RouteChangelogModel>(this as RouteChangelogModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteChangelogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.description, description) || other.description == description)&&(identical(other.changedBy, changedBy) || other.changedBy == changedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,routeId,changeType,description,changedBy,createdAt);

@override
String toString() {
  return 'RouteChangelogModel(id: $id, routeId: $routeId, changeType: $changeType, description: $description, changedBy: $changedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RouteChangelogModelCopyWith<$Res>  {
  factory $RouteChangelogModelCopyWith(RouteChangelogModel value, $Res Function(RouteChangelogModel) _then) = _$RouteChangelogModelCopyWithImpl;
@useResult
$Res call({
 String id, String routeId, ChangeType changeType, String description, String changedBy, DateTime createdAt
});




}
/// @nodoc
class _$RouteChangelogModelCopyWithImpl<$Res>
    implements $RouteChangelogModelCopyWith<$Res> {
  _$RouteChangelogModelCopyWithImpl(this._self, this._then);

  final RouteChangelogModel _self;
  final $Res Function(RouteChangelogModel) _then;

/// Create a copy of RouteChangelogModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routeId = null,Object? changeType = null,Object? description = null,Object? changedBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as ChangeType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,changedBy: null == changedBy ? _self.changedBy : changedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteChangelogModel].
extension RouteChangelogModelPatterns on RouteChangelogModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteChangelogModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteChangelogModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteChangelogModel value)  $default,){
final _that = this;
switch (_that) {
case _RouteChangelogModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteChangelogModel value)?  $default,){
final _that = this;
switch (_that) {
case _RouteChangelogModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String routeId,  ChangeType changeType,  String description,  String changedBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteChangelogModel() when $default != null:
return $default(_that.id,_that.routeId,_that.changeType,_that.description,_that.changedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String routeId,  ChangeType changeType,  String description,  String changedBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RouteChangelogModel():
return $default(_that.id,_that.routeId,_that.changeType,_that.description,_that.changedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String routeId,  ChangeType changeType,  String description,  String changedBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteChangelogModel() when $default != null:
return $default(_that.id,_that.routeId,_that.changeType,_that.description,_that.changedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _RouteChangelogModel extends RouteChangelogModel {
  const _RouteChangelogModel({required this.id, required this.routeId, required this.changeType, required this.description, required this.changedBy, required this.createdAt}): super._();
  

@override final  String id;
@override final  String routeId;
@override final  ChangeType changeType;
@override final  String description;
@override final  String changedBy;
@override final  DateTime createdAt;

/// Create a copy of RouteChangelogModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteChangelogModelCopyWith<_RouteChangelogModel> get copyWith => __$RouteChangelogModelCopyWithImpl<_RouteChangelogModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteChangelogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.description, description) || other.description == description)&&(identical(other.changedBy, changedBy) || other.changedBy == changedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,routeId,changeType,description,changedBy,createdAt);

@override
String toString() {
  return 'RouteChangelogModel(id: $id, routeId: $routeId, changeType: $changeType, description: $description, changedBy: $changedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RouteChangelogModelCopyWith<$Res> implements $RouteChangelogModelCopyWith<$Res> {
  factory _$RouteChangelogModelCopyWith(_RouteChangelogModel value, $Res Function(_RouteChangelogModel) _then) = __$RouteChangelogModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String routeId, ChangeType changeType, String description, String changedBy, DateTime createdAt
});




}
/// @nodoc
class __$RouteChangelogModelCopyWithImpl<$Res>
    implements _$RouteChangelogModelCopyWith<$Res> {
  __$RouteChangelogModelCopyWithImpl(this._self, this._then);

  final _RouteChangelogModel _self;
  final $Res Function(_RouteChangelogModel) _then;

/// Create a copy of RouteChangelogModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routeId = null,Object? changeType = null,Object? description = null,Object? changedBy = null,Object? createdAt = null,}) {
  return _then(_RouteChangelogModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as ChangeType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,changedBy: null == changedBy ? _self.changedBy : changedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
