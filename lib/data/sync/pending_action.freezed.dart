// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingAction {

 String get id; PendingActionKind get kind; Map<String, dynamic> get payload; DateTime get createdAt; int get attempts; String? get lastError;
/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingActionCopyWith<PendingAction> get copyWith => _$PendingActionCopyWithImpl<PendingAction>(this as PendingAction, _$identity);

  /// Serializes this PendingAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingAction&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,const DeepCollectionEquality().hash(payload),createdAt,attempts,lastError);

@override
String toString() {
  return 'PendingAction(id: $id, kind: $kind, payload: $payload, createdAt: $createdAt, attempts: $attempts, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $PendingActionCopyWith<$Res>  {
  factory $PendingActionCopyWith(PendingAction value, $Res Function(PendingAction) _then) = _$PendingActionCopyWithImpl;
@useResult
$Res call({
 String id, PendingActionKind kind, Map<String, dynamic> payload, DateTime createdAt, int attempts, String? lastError
});




}
/// @nodoc
class _$PendingActionCopyWithImpl<$Res>
    implements $PendingActionCopyWith<$Res> {
  _$PendingActionCopyWithImpl(this._self, this._then);

  final PendingAction _self;
  final $Res Function(PendingAction) _then;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? payload = null,Object? createdAt = null,Object? attempts = null,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PendingActionKind,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingAction].
extension PendingActionPatterns on PendingAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingAction value)  $default,){
final _that = this;
switch (_that) {
case _PendingAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingAction value)?  $default,){
final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PendingActionKind kind,  Map<String, dynamic> payload,  DateTime createdAt,  int attempts,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PendingActionKind kind,  Map<String, dynamic> payload,  DateTime createdAt,  int attempts,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _PendingAction():
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PendingActionKind kind,  Map<String, dynamic> payload,  DateTime createdAt,  int attempts,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingAction implements PendingAction {
  const _PendingAction({required this.id, required this.kind, final  Map<String, dynamic> payload = const <String, dynamic>{}, required this.createdAt, this.attempts = 0, this.lastError}): _payload = payload;
  factory _PendingAction.fromJson(Map<String, dynamic> json) => _$PendingActionFromJson(json);

@override final  String id;
@override final  PendingActionKind kind;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  DateTime createdAt;
@override@JsonKey() final  int attempts;
@override final  String? lastError;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingActionCopyWith<_PendingAction> get copyWith => __$PendingActionCopyWithImpl<_PendingAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingAction&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,const DeepCollectionEquality().hash(_payload),createdAt,attempts,lastError);

@override
String toString() {
  return 'PendingAction(id: $id, kind: $kind, payload: $payload, createdAt: $createdAt, attempts: $attempts, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$PendingActionCopyWith<$Res> implements $PendingActionCopyWith<$Res> {
  factory _$PendingActionCopyWith(_PendingAction value, $Res Function(_PendingAction) _then) = __$PendingActionCopyWithImpl;
@override @useResult
$Res call({
 String id, PendingActionKind kind, Map<String, dynamic> payload, DateTime createdAt, int attempts, String? lastError
});




}
/// @nodoc
class __$PendingActionCopyWithImpl<$Res>
    implements _$PendingActionCopyWith<$Res> {
  __$PendingActionCopyWithImpl(this._self, this._then);

  final _PendingAction _self;
  final $Res Function(_PendingAction) _then;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? payload = null,Object? createdAt = null,Object? attempts = null,Object? lastError = freezed,}) {
  return _then(_PendingAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PendingActionKind,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
