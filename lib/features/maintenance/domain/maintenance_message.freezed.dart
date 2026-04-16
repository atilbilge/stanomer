// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceMessage {

 String get id;@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'user_id') String get userId; String get message;@JsonKey(name: 'photo_url') String? get photoUrl;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of MaintenanceMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceMessageCopyWith<MaintenanceMessage> get copyWith => _$MaintenanceMessageCopyWithImpl<MaintenanceMessage>(this as MaintenanceMessage, _$identity);

  /// Serializes this MaintenanceMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,requestId,userId,message,photoUrl,createdAt);

@override
String toString() {
  return 'MaintenanceMessage(id: $id, requestId: $requestId, userId: $userId, message: $message, photoUrl: $photoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MaintenanceMessageCopyWith<$Res>  {
  factory $MaintenanceMessageCopyWith(MaintenanceMessage value, $Res Function(MaintenanceMessage) _then) = _$MaintenanceMessageCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'user_id') String userId, String message,@JsonKey(name: 'photo_url') String? photoUrl,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$MaintenanceMessageCopyWithImpl<$Res>
    implements $MaintenanceMessageCopyWith<$Res> {
  _$MaintenanceMessageCopyWithImpl(this._self, this._then);

  final MaintenanceMessage _self;
  final $Res Function(MaintenanceMessage) _then;

/// Create a copy of MaintenanceMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? userId = null,Object? message = null,Object? photoUrl = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceMessage].
extension MaintenanceMessagePatterns on MaintenanceMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceMessage value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceMessage value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'user_id')  String userId,  String message, @JsonKey(name: 'photo_url')  String? photoUrl, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceMessage() when $default != null:
return $default(_that.id,_that.requestId,_that.userId,_that.message,_that.photoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'user_id')  String userId,  String message, @JsonKey(name: 'photo_url')  String? photoUrl, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceMessage():
return $default(_that.id,_that.requestId,_that.userId,_that.message,_that.photoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'user_id')  String userId,  String message, @JsonKey(name: 'photo_url')  String? photoUrl, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceMessage() when $default != null:
return $default(_that.id,_that.requestId,_that.userId,_that.message,_that.photoUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceMessage implements MaintenanceMessage {
  const _MaintenanceMessage({required this.id, @JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'user_id') required this.userId, required this.message, @JsonKey(name: 'photo_url') this.photoUrl, @JsonKey(name: 'created_at') required this.createdAt});
  factory _MaintenanceMessage.fromJson(Map<String, dynamic> json) => _$MaintenanceMessageFromJson(json);

@override final  String id;
@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String message;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of MaintenanceMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceMessageCopyWith<_MaintenanceMessage> get copyWith => __$MaintenanceMessageCopyWithImpl<_MaintenanceMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,requestId,userId,message,photoUrl,createdAt);

@override
String toString() {
  return 'MaintenanceMessage(id: $id, requestId: $requestId, userId: $userId, message: $message, photoUrl: $photoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceMessageCopyWith<$Res> implements $MaintenanceMessageCopyWith<$Res> {
  factory _$MaintenanceMessageCopyWith(_MaintenanceMessage value, $Res Function(_MaintenanceMessage) _then) = __$MaintenanceMessageCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'user_id') String userId, String message,@JsonKey(name: 'photo_url') String? photoUrl,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$MaintenanceMessageCopyWithImpl<$Res>
    implements _$MaintenanceMessageCopyWith<$Res> {
  __$MaintenanceMessageCopyWithImpl(this._self, this._then);

  final _MaintenanceMessage _self;
  final $Res Function(_MaintenanceMessage) _then;

/// Create a copy of MaintenanceMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? userId = null,Object? message = null,Object? photoUrl = freezed,Object? createdAt = null,}) {
  return _then(_MaintenanceMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
