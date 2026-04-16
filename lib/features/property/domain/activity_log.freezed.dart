// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityLog {

 String get id;@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'user_id') String? get userId; String get type; Map<String, dynamic> get metadata;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityLogCopyWith<ActivityLog> get copyWith => _$ActivityLogCopyWithImpl<ActivityLog>(this as ActivityLog, _$identity);

  /// Serializes this ActivityLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityLog&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,userId,type,const DeepCollectionEquality().hash(metadata),createdAt);

@override
String toString() {
  return 'ActivityLog(id: $id, propertyId: $propertyId, userId: $userId, type: $type, metadata: $metadata, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ActivityLogCopyWith<$Res>  {
  factory $ActivityLogCopyWith(ActivityLog value, $Res Function(ActivityLog) _then) = _$ActivityLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'user_id') String? userId, String type, Map<String, dynamic> metadata,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$ActivityLogCopyWithImpl<$Res>
    implements $ActivityLogCopyWith<$Res> {
  _$ActivityLogCopyWithImpl(this._self, this._then);

  final ActivityLog _self;
  final $Res Function(ActivityLog) _then;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? userId = freezed,Object? type = null,Object? metadata = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityLog].
extension ActivityLogPatterns on ActivityLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityLog value)  $default,){
final _that = this;
switch (_that) {
case _ActivityLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityLog value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'user_id')  String? userId,  String type,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
return $default(_that.id,_that.propertyId,_that.userId,_that.type,_that.metadata,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'user_id')  String? userId,  String type,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityLog():
return $default(_that.id,_that.propertyId,_that.userId,_that.type,_that.metadata,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'user_id')  String? userId,  String type,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
return $default(_that.id,_that.propertyId,_that.userId,_that.type,_that.metadata,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityLog implements ActivityLog {
  const _ActivityLog({required this.id, @JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'user_id') this.userId, required this.type, final  Map<String, dynamic> metadata = const {}, @JsonKey(name: 'created_at') required this.createdAt}): _metadata = metadata;
  factory _ActivityLog.fromJson(Map<String, dynamic> json) => _$ActivityLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'user_id') final  String? userId;
@override final  String type;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityLogCopyWith<_ActivityLog> get copyWith => __$ActivityLogCopyWithImpl<_ActivityLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityLog&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,userId,type,const DeepCollectionEquality().hash(_metadata),createdAt);

@override
String toString() {
  return 'ActivityLog(id: $id, propertyId: $propertyId, userId: $userId, type: $type, metadata: $metadata, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityLogCopyWith<$Res> implements $ActivityLogCopyWith<$Res> {
  factory _$ActivityLogCopyWith(_ActivityLog value, $Res Function(_ActivityLog) _then) = __$ActivityLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'user_id') String? userId, String type, Map<String, dynamic> metadata,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$ActivityLogCopyWithImpl<$Res>
    implements _$ActivityLogCopyWith<$Res> {
  __$ActivityLogCopyWithImpl(this._self, this._then);

  final _ActivityLog _self;
  final $Res Function(_ActivityLog) _then;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? userId = freezed,Object? type = null,Object? metadata = null,Object? createdAt = null,}) {
  return _then(_ActivityLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
