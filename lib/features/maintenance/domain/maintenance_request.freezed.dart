// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceRequest {

 String get id;@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'contract_id') String? get contractId;@JsonKey(name: 'reporter_id') String get reporterId; String get title; MaintenanceCategory get category; String? get description; MaintenanceStatus get status; MaintenancePriority get priority;@JsonKey(name: 'photos_urls') List<String> get photosUrls;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceRequestCopyWith<MaintenanceRequest> get copyWith => _$MaintenanceRequestCopyWithImpl<MaintenanceRequest>(this as MaintenanceRequest, _$identity);

  /// Serializes this MaintenanceRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.photosUrls, photosUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,contractId,reporterId,title,category,description,status,priority,const DeepCollectionEquality().hash(photosUrls),createdAt,updatedAt);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, propertyId: $propertyId, contractId: $contractId, reporterId: $reporterId, title: $title, category: $category, description: $description, status: $status, priority: $priority, photosUrls: $photosUrls, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MaintenanceRequestCopyWith<$Res>  {
  factory $MaintenanceRequestCopyWith(MaintenanceRequest value, $Res Function(MaintenanceRequest) _then) = _$MaintenanceRequestCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'reporter_id') String reporterId, String title, MaintenanceCategory category, String? description, MaintenanceStatus status, MaintenancePriority priority,@JsonKey(name: 'photos_urls') List<String> photosUrls,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$MaintenanceRequestCopyWithImpl<$Res>
    implements $MaintenanceRequestCopyWith<$Res> {
  _$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final MaintenanceRequest _self;
  final $Res Function(MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? contractId = freezed,Object? reporterId = null,Object? title = null,Object? category = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? photosUrls = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,photosUrls: null == photosUrls ? _self.photosUrls : photosUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceRequest].
extension MaintenanceRequestPatterns on MaintenanceRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceRequest value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title,  MaintenanceCategory category,  String? description,  MaintenanceStatus status,  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title,  MaintenanceCategory category,  String? description,  MaintenanceStatus status,  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest():
return $default(_that.id,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title,  MaintenanceCategory category,  String? description,  MaintenanceStatus status,  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceRequest implements MaintenanceRequest {
  const _MaintenanceRequest({required this.id, @JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'contract_id') this.contractId, @JsonKey(name: 'reporter_id') required this.reporterId, required this.title, this.category = MaintenanceCategory.other, this.description, this.status = MaintenanceStatus.open, this.priority = MaintenancePriority.normal, @JsonKey(name: 'photos_urls') final  List<String> photosUrls = const [], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _photosUrls = photosUrls;
  factory _MaintenanceRequest.fromJson(Map<String, dynamic> json) => _$MaintenanceRequestFromJson(json);

@override final  String id;
@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'contract_id') final  String? contractId;
@override@JsonKey(name: 'reporter_id') final  String reporterId;
@override final  String title;
@override@JsonKey() final  MaintenanceCategory category;
@override final  String? description;
@override@JsonKey() final  MaintenanceStatus status;
@override@JsonKey() final  MaintenancePriority priority;
 final  List<String> _photosUrls;
@override@JsonKey(name: 'photos_urls') List<String> get photosUrls {
  if (_photosUrls is EqualUnmodifiableListView) return _photosUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photosUrls);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceRequestCopyWith<_MaintenanceRequest> get copyWith => __$MaintenanceRequestCopyWithImpl<_MaintenanceRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._photosUrls, _photosUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,contractId,reporterId,title,category,description,status,priority,const DeepCollectionEquality().hash(_photosUrls),createdAt,updatedAt);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, propertyId: $propertyId, contractId: $contractId, reporterId: $reporterId, title: $title, category: $category, description: $description, status: $status, priority: $priority, photosUrls: $photosUrls, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceRequestCopyWith<$Res> implements $MaintenanceRequestCopyWith<$Res> {
  factory _$MaintenanceRequestCopyWith(_MaintenanceRequest value, $Res Function(_MaintenanceRequest) _then) = __$MaintenanceRequestCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'reporter_id') String reporterId, String title, MaintenanceCategory category, String? description, MaintenanceStatus status, MaintenancePriority priority,@JsonKey(name: 'photos_urls') List<String> photosUrls,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$MaintenanceRequestCopyWithImpl<$Res>
    implements _$MaintenanceRequestCopyWith<$Res> {
  __$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final _MaintenanceRequest _self;
  final $Res Function(_MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? contractId = freezed,Object? reporterId = null,Object? title = null,Object? category = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? photosUrls = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MaintenanceRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,photosUrls: null == photosUrls ? _self._photosUrls : photosUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
