// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeatureRequest {

 String get id; String get title; String get description; String get submittedBy; FeatureRequestCategory get category; FeatureRequestPriority get priority; FeatureRequestStatus get status; int get votes; Map<String, dynamic>? get payload; DateTime get createdAt; DateTime get updatedAt; String? get adminNotes; String? get assigneeId;
/// Create a copy of FeatureRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureRequestCopyWith<FeatureRequest> get copyWith => _$FeatureRequestCopyWithImpl<FeatureRequest>(this as FeatureRequest, _$identity);

  /// Serializes this FeatureRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.submittedBy, submittedBy) || other.submittedBy == submittedBy)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.votes, votes) || other.votes == votes)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.adminNotes, adminNotes) || other.adminNotes == adminNotes)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,submittedBy,category,priority,status,votes,const DeepCollectionEquality().hash(payload),createdAt,updatedAt,adminNotes,assigneeId);

@override
String toString() {
  return 'FeatureRequest(id: $id, title: $title, description: $description, submittedBy: $submittedBy, category: $category, priority: $priority, status: $status, votes: $votes, payload: $payload, createdAt: $createdAt, updatedAt: $updatedAt, adminNotes: $adminNotes, assigneeId: $assigneeId)';
}


}

/// @nodoc
abstract mixin class $FeatureRequestCopyWith<$Res>  {
  factory $FeatureRequestCopyWith(FeatureRequest value, $Res Function(FeatureRequest) _then) = _$FeatureRequestCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String submittedBy, FeatureRequestCategory category, FeatureRequestPriority priority, FeatureRequestStatus status, int votes, Map<String, dynamic>? payload, DateTime createdAt, DateTime updatedAt, String? adminNotes, String? assigneeId
});




}
/// @nodoc
class _$FeatureRequestCopyWithImpl<$Res>
    implements $FeatureRequestCopyWith<$Res> {
  _$FeatureRequestCopyWithImpl(this._self, this._then);

  final FeatureRequest _self;
  final $Res Function(FeatureRequest) _then;

/// Create a copy of FeatureRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? submittedBy = null,Object? category = null,Object? priority = null,Object? status = null,Object? votes = null,Object? payload = freezed,Object? createdAt = null,Object? updatedAt = null,Object? adminNotes = freezed,Object? assigneeId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,submittedBy: null == submittedBy ? _self.submittedBy : submittedBy // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FeatureRequestCategory,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as FeatureRequestPriority,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeatureRequestStatus,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as int,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,adminNotes: freezed == adminNotes ? _self.adminNotes : adminNotes // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureRequest].
extension FeatureRequestPatterns on FeatureRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureRequest value)  $default,){
final _that = this;
switch (_that) {
case _FeatureRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureRequest value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String submittedBy,  FeatureRequestCategory category,  FeatureRequestPriority priority,  FeatureRequestStatus status,  int votes,  Map<String, dynamic>? payload,  DateTime createdAt,  DateTime updatedAt,  String? adminNotes,  String? assigneeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureRequest() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.submittedBy,_that.category,_that.priority,_that.status,_that.votes,_that.payload,_that.createdAt,_that.updatedAt,_that.adminNotes,_that.assigneeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String submittedBy,  FeatureRequestCategory category,  FeatureRequestPriority priority,  FeatureRequestStatus status,  int votes,  Map<String, dynamic>? payload,  DateTime createdAt,  DateTime updatedAt,  String? adminNotes,  String? assigneeId)  $default,) {final _that = this;
switch (_that) {
case _FeatureRequest():
return $default(_that.id,_that.title,_that.description,_that.submittedBy,_that.category,_that.priority,_that.status,_that.votes,_that.payload,_that.createdAt,_that.updatedAt,_that.adminNotes,_that.assigneeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String submittedBy,  FeatureRequestCategory category,  FeatureRequestPriority priority,  FeatureRequestStatus status,  int votes,  Map<String, dynamic>? payload,  DateTime createdAt,  DateTime updatedAt,  String? adminNotes,  String? assigneeId)?  $default,) {final _that = this;
switch (_that) {
case _FeatureRequest() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.submittedBy,_that.category,_that.priority,_that.status,_that.votes,_that.payload,_that.createdAt,_that.updatedAt,_that.adminNotes,_that.assigneeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeatureRequest implements FeatureRequest {
  const _FeatureRequest({required this.id, required this.title, required this.description, required this.submittedBy, required this.category, this.priority = FeatureRequestPriority.normal, this.status = FeatureRequestStatus.open, this.votes = 0, final  Map<String, dynamic>? payload, required this.createdAt, required this.updatedAt, this.adminNotes, this.assigneeId}): _payload = payload;
  factory _FeatureRequest.fromJson(Map<String, dynamic> json) => _$FeatureRequestFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String submittedBy;
@override final  FeatureRequestCategory category;
@override@JsonKey() final  FeatureRequestPriority priority;
@override@JsonKey() final  FeatureRequestStatus status;
@override@JsonKey() final  int votes;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? adminNotes;
@override final  String? assigneeId;

/// Create a copy of FeatureRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureRequestCopyWith<_FeatureRequest> get copyWith => __$FeatureRequestCopyWithImpl<_FeatureRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeatureRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.submittedBy, submittedBy) || other.submittedBy == submittedBy)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.votes, votes) || other.votes == votes)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.adminNotes, adminNotes) || other.adminNotes == adminNotes)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,submittedBy,category,priority,status,votes,const DeepCollectionEquality().hash(_payload),createdAt,updatedAt,adminNotes,assigneeId);

@override
String toString() {
  return 'FeatureRequest(id: $id, title: $title, description: $description, submittedBy: $submittedBy, category: $category, priority: $priority, status: $status, votes: $votes, payload: $payload, createdAt: $createdAt, updatedAt: $updatedAt, adminNotes: $adminNotes, assigneeId: $assigneeId)';
}


}

/// @nodoc
abstract mixin class _$FeatureRequestCopyWith<$Res> implements $FeatureRequestCopyWith<$Res> {
  factory _$FeatureRequestCopyWith(_FeatureRequest value, $Res Function(_FeatureRequest) _then) = __$FeatureRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String submittedBy, FeatureRequestCategory category, FeatureRequestPriority priority, FeatureRequestStatus status, int votes, Map<String, dynamic>? payload, DateTime createdAt, DateTime updatedAt, String? adminNotes, String? assigneeId
});




}
/// @nodoc
class __$FeatureRequestCopyWithImpl<$Res>
    implements _$FeatureRequestCopyWith<$Res> {
  __$FeatureRequestCopyWithImpl(this._self, this._then);

  final _FeatureRequest _self;
  final $Res Function(_FeatureRequest) _then;

/// Create a copy of FeatureRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? submittedBy = null,Object? category = null,Object? priority = null,Object? status = null,Object? votes = null,Object? payload = freezed,Object? createdAt = null,Object? updatedAt = null,Object? adminNotes = freezed,Object? assigneeId = freezed,}) {
  return _then(_FeatureRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,submittedBy: null == submittedBy ? _self.submittedBy : submittedBy // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FeatureRequestCategory,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as FeatureRequestPriority,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeatureRequestStatus,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as int,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,adminNotes: freezed == adminNotes ? _self.adminNotes : adminNotes // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
