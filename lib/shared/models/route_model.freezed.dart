// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteModel {

 String get id; String get operatorId; String get code; String get name; ServiceType get serviceType; Color get routeColor; bool get hasReturn; bool get isCircular; RouteStatus get status; RouteSource get source; bool get active; String? get ownerDisplayName; DateTime? get lastUpdatedAt;
/// Create a copy of RouteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteModelCopyWith<RouteModel> get copyWith => _$RouteModelCopyWithImpl<RouteModel>(this as RouteModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.routeColor, routeColor) || other.routeColor == routeColor)&&(identical(other.hasReturn, hasReturn) || other.hasReturn == hasReturn)&&(identical(other.isCircular, isCircular) || other.isCircular == isCircular)&&(identical(other.status, status) || other.status == status)&&(identical(other.source, source) || other.source == source)&&(identical(other.active, active) || other.active == active)&&(identical(other.ownerDisplayName, ownerDisplayName) || other.ownerDisplayName == ownerDisplayName)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,operatorId,code,name,serviceType,routeColor,hasReturn,isCircular,status,source,active,ownerDisplayName,lastUpdatedAt);

@override
String toString() {
  return 'RouteModel(id: $id, operatorId: $operatorId, code: $code, name: $name, serviceType: $serviceType, routeColor: $routeColor, hasReturn: $hasReturn, isCircular: $isCircular, status: $status, source: $source, active: $active, ownerDisplayName: $ownerDisplayName, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $RouteModelCopyWith<$Res>  {
  factory $RouteModelCopyWith(RouteModel value, $Res Function(RouteModel) _then) = _$RouteModelCopyWithImpl;
@useResult
$Res call({
 String id, String operatorId, String code, String name, ServiceType serviceType, Color routeColor, bool hasReturn, bool isCircular, RouteStatus status, RouteSource source, bool active, String? ownerDisplayName, DateTime? lastUpdatedAt
});




}
/// @nodoc
class _$RouteModelCopyWithImpl<$Res>
    implements $RouteModelCopyWith<$Res> {
  _$RouteModelCopyWithImpl(this._self, this._then);

  final RouteModel _self;
  final $Res Function(RouteModel) _then;

/// Create a copy of RouteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? operatorId = null,Object? code = null,Object? name = null,Object? serviceType = null,Object? routeColor = null,Object? hasReturn = null,Object? isCircular = null,Object? status = null,Object? source = null,Object? active = null,Object? ownerDisplayName = freezed,Object? lastUpdatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serviceType: null == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as ServiceType,routeColor: null == routeColor ? _self.routeColor : routeColor // ignore: cast_nullable_to_non_nullable
as Color,hasReturn: null == hasReturn ? _self.hasReturn : hasReturn // ignore: cast_nullable_to_non_nullable
as bool,isCircular: null == isCircular ? _self.isCircular : isCircular // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStatus,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RouteSource,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,ownerDisplayName: freezed == ownerDisplayName ? _self.ownerDisplayName : ownerDisplayName // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteModel].
extension RouteModelPatterns on RouteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteModel value)  $default,){
final _that = this;
switch (_that) {
case _RouteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteModel value)?  $default,){
final _that = this;
switch (_that) {
case _RouteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String operatorId,  String code,  String name,  ServiceType serviceType,  Color routeColor,  bool hasReturn,  bool isCircular,  RouteStatus status,  RouteSource source,  bool active,  String? ownerDisplayName,  DateTime? lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteModel() when $default != null:
return $default(_that.id,_that.operatorId,_that.code,_that.name,_that.serviceType,_that.routeColor,_that.hasReturn,_that.isCircular,_that.status,_that.source,_that.active,_that.ownerDisplayName,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String operatorId,  String code,  String name,  ServiceType serviceType,  Color routeColor,  bool hasReturn,  bool isCircular,  RouteStatus status,  RouteSource source,  bool active,  String? ownerDisplayName,  DateTime? lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _RouteModel():
return $default(_that.id,_that.operatorId,_that.code,_that.name,_that.serviceType,_that.routeColor,_that.hasReturn,_that.isCircular,_that.status,_that.source,_that.active,_that.ownerDisplayName,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String operatorId,  String code,  String name,  ServiceType serviceType,  Color routeColor,  bool hasReturn,  bool isCircular,  RouteStatus status,  RouteSource source,  bool active,  String? ownerDisplayName,  DateTime? lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteModel() when $default != null:
return $default(_that.id,_that.operatorId,_that.code,_that.name,_that.serviceType,_that.routeColor,_that.hasReturn,_that.isCircular,_that.status,_that.source,_that.active,_that.ownerDisplayName,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RouteModel extends RouteModel {
  const _RouteModel({required this.id, required this.operatorId, required this.code, required this.name, required this.serviceType, required this.routeColor, this.hasReturn = true, this.isCircular = false, this.status = RouteStatus.official, this.source = RouteSource.official, this.active = true, this.ownerDisplayName, this.lastUpdatedAt}): super._();
  

@override final  String id;
@override final  String operatorId;
@override final  String code;
@override final  String name;
@override final  ServiceType serviceType;
@override final  Color routeColor;
@override@JsonKey() final  bool hasReturn;
@override@JsonKey() final  bool isCircular;
@override@JsonKey() final  RouteStatus status;
@override@JsonKey() final  RouteSource source;
@override@JsonKey() final  bool active;
@override final  String? ownerDisplayName;
@override final  DateTime? lastUpdatedAt;

/// Create a copy of RouteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteModelCopyWith<_RouteModel> get copyWith => __$RouteModelCopyWithImpl<_RouteModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.routeColor, routeColor) || other.routeColor == routeColor)&&(identical(other.hasReturn, hasReturn) || other.hasReturn == hasReturn)&&(identical(other.isCircular, isCircular) || other.isCircular == isCircular)&&(identical(other.status, status) || other.status == status)&&(identical(other.source, source) || other.source == source)&&(identical(other.active, active) || other.active == active)&&(identical(other.ownerDisplayName, ownerDisplayName) || other.ownerDisplayName == ownerDisplayName)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,operatorId,code,name,serviceType,routeColor,hasReturn,isCircular,status,source,active,ownerDisplayName,lastUpdatedAt);

@override
String toString() {
  return 'RouteModel(id: $id, operatorId: $operatorId, code: $code, name: $name, serviceType: $serviceType, routeColor: $routeColor, hasReturn: $hasReturn, isCircular: $isCircular, status: $status, source: $source, active: $active, ownerDisplayName: $ownerDisplayName, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$RouteModelCopyWith<$Res> implements $RouteModelCopyWith<$Res> {
  factory _$RouteModelCopyWith(_RouteModel value, $Res Function(_RouteModel) _then) = __$RouteModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String operatorId, String code, String name, ServiceType serviceType, Color routeColor, bool hasReturn, bool isCircular, RouteStatus status, RouteSource source, bool active, String? ownerDisplayName, DateTime? lastUpdatedAt
});




}
/// @nodoc
class __$RouteModelCopyWithImpl<$Res>
    implements _$RouteModelCopyWith<$Res> {
  __$RouteModelCopyWithImpl(this._self, this._then);

  final _RouteModel _self;
  final $Res Function(_RouteModel) _then;

/// Create a copy of RouteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? operatorId = null,Object? code = null,Object? name = null,Object? serviceType = null,Object? routeColor = null,Object? hasReturn = null,Object? isCircular = null,Object? status = null,Object? source = null,Object? active = null,Object? ownerDisplayName = freezed,Object? lastUpdatedAt = freezed,}) {
  return _then(_RouteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serviceType: null == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as ServiceType,routeColor: null == routeColor ? _self.routeColor : routeColor // ignore: cast_nullable_to_non_nullable
as Color,hasReturn: null == hasReturn ? _self.hasReturn : hasReturn // ignore: cast_nullable_to_non_nullable
as bool,isCircular: null == isCircular ? _self.isCircular : isCircular // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStatus,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RouteSource,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,ownerDisplayName: freezed == ownerDisplayName ? _self.ownerDisplayName : ownerDisplayName // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
