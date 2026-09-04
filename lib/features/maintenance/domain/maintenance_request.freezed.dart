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

 String get id;@JsonKey(name: 'ticket_number') String? get ticketNumber;@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'contract_id') String? get contractId;@JsonKey(name: 'reporter_id') String get reporterId; String get title;@JsonKey(unknownEnumValue: MaintenanceCategory.other) MaintenanceCategory get category; String? get description;@JsonKey(unknownEnumValue: MaintenanceStatus.open) MaintenanceStatus get status;@JsonKey(unknownEnumValue: MaintenancePriority.normal) MaintenancePriority get priority;@JsonKey(name: 'photos_urls') List<String> get photosUrls;@JsonKey(name: 'cost_amount') double? get costAmount;@JsonKey(name: 'settled_amount') double get settledAmount; String? get currency;@JsonKey(name: 'paid_by') String? get paidBy;@JsonKey(name: 'payment_date') DateTime? get paymentDate;@JsonKey(name: 'payment_status') String get paymentStatus;@JsonKey(name: 'invoice_pdf_url') String? get invoicePdfUrl;@JsonKey(name: 'rejection_reason') String? get rejectionReason;@JsonKey(name: 'rejected_by') String? get rejectedBy;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceRequestCopyWith<MaintenanceRequest> get copyWith => _$MaintenanceRequestCopyWithImpl<MaintenanceRequest>(this as MaintenanceRequest, _$identity);

  /// Serializes this MaintenanceRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.photosUrls, photosUrls)&&(identical(other.costAmount, costAmount) || other.costAmount == costAmount)&&(identical(other.settledAmount, settledAmount) || other.settledAmount == settledAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.invoicePdfUrl, invoicePdfUrl) || other.invoicePdfUrl == invoicePdfUrl)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.rejectedBy, rejectedBy) || other.rejectedBy == rejectedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ticketNumber,propertyId,contractId,reporterId,title,category,description,status,priority,const DeepCollectionEquality().hash(photosUrls),costAmount,settledAmount,currency,paidBy,paymentDate,paymentStatus,invoicePdfUrl,rejectionReason,rejectedBy,createdAt,updatedAt]);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, ticketNumber: $ticketNumber, propertyId: $propertyId, contractId: $contractId, reporterId: $reporterId, title: $title, category: $category, description: $description, status: $status, priority: $priority, photosUrls: $photosUrls, costAmount: $costAmount, settledAmount: $settledAmount, currency: $currency, paidBy: $paidBy, paymentDate: $paymentDate, paymentStatus: $paymentStatus, invoicePdfUrl: $invoicePdfUrl, rejectionReason: $rejectionReason, rejectedBy: $rejectedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MaintenanceRequestCopyWith<$Res>  {
  factory $MaintenanceRequestCopyWith(MaintenanceRequest value, $Res Function(MaintenanceRequest) _then) = _$MaintenanceRequestCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'ticket_number') String? ticketNumber,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'reporter_id') String reporterId, String title,@JsonKey(unknownEnumValue: MaintenanceCategory.other) MaintenanceCategory category, String? description,@JsonKey(unknownEnumValue: MaintenanceStatus.open) MaintenanceStatus status,@JsonKey(unknownEnumValue: MaintenancePriority.normal) MaintenancePriority priority,@JsonKey(name: 'photos_urls') List<String> photosUrls,@JsonKey(name: 'cost_amount') double? costAmount,@JsonKey(name: 'settled_amount') double settledAmount, String? currency,@JsonKey(name: 'paid_by') String? paidBy,@JsonKey(name: 'payment_date') DateTime? paymentDate,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'invoice_pdf_url') String? invoicePdfUrl,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'rejected_by') String? rejectedBy,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketNumber = freezed,Object? propertyId = null,Object? contractId = freezed,Object? reporterId = null,Object? title = null,Object? category = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? photosUrls = null,Object? costAmount = freezed,Object? settledAmount = null,Object? currency = freezed,Object? paidBy = freezed,Object? paymentDate = freezed,Object? paymentStatus = null,Object? invoicePdfUrl = freezed,Object? rejectionReason = freezed,Object? rejectedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: freezed == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as String?,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,photosUrls: null == photosUrls ? _self.photosUrls : photosUrls // ignore: cast_nullable_to_non_nullable
as List<String>,costAmount: freezed == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as double?,settledAmount: null == settledAmount ? _self.settledAmount : settledAmount // ignore: cast_nullable_to_non_nullable
as double,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,paidBy: freezed == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String?,paymentDate: freezed == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,invoicePdfUrl: freezed == invoicePdfUrl ? _self.invoicePdfUrl : invoicePdfUrl // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,rejectedBy: freezed == rejectedBy ? _self.rejectedBy : rejectedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_number')  String? ticketNumber, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title, @JsonKey(unknownEnumValue: MaintenanceCategory.other)  MaintenanceCategory category,  String? description, @JsonKey(unknownEnumValue: MaintenanceStatus.open)  MaintenanceStatus status, @JsonKey(unknownEnumValue: MaintenancePriority.normal)  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'cost_amount')  double? costAmount, @JsonKey(name: 'settled_amount')  double settledAmount,  String? currency, @JsonKey(name: 'paid_by')  String? paidBy, @JsonKey(name: 'payment_date')  DateTime? paymentDate, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'invoice_pdf_url')  String? invoicePdfUrl, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'rejected_by')  String? rejectedBy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.costAmount,_that.settledAmount,_that.currency,_that.paidBy,_that.paymentDate,_that.paymentStatus,_that.invoicePdfUrl,_that.rejectionReason,_that.rejectedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_number')  String? ticketNumber, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title, @JsonKey(unknownEnumValue: MaintenanceCategory.other)  MaintenanceCategory category,  String? description, @JsonKey(unknownEnumValue: MaintenanceStatus.open)  MaintenanceStatus status, @JsonKey(unknownEnumValue: MaintenancePriority.normal)  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'cost_amount')  double? costAmount, @JsonKey(name: 'settled_amount')  double settledAmount,  String? currency, @JsonKey(name: 'paid_by')  String? paidBy, @JsonKey(name: 'payment_date')  DateTime? paymentDate, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'invoice_pdf_url')  String? invoicePdfUrl, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'rejected_by')  String? rejectedBy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest():
return $default(_that.id,_that.ticketNumber,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.costAmount,_that.settledAmount,_that.currency,_that.paidBy,_that.paymentDate,_that.paymentStatus,_that.invoicePdfUrl,_that.rejectionReason,_that.rejectedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'ticket_number')  String? ticketNumber, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'reporter_id')  String reporterId,  String title, @JsonKey(unknownEnumValue: MaintenanceCategory.other)  MaintenanceCategory category,  String? description, @JsonKey(unknownEnumValue: MaintenanceStatus.open)  MaintenanceStatus status, @JsonKey(unknownEnumValue: MaintenancePriority.normal)  MaintenancePriority priority, @JsonKey(name: 'photos_urls')  List<String> photosUrls, @JsonKey(name: 'cost_amount')  double? costAmount, @JsonKey(name: 'settled_amount')  double settledAmount,  String? currency, @JsonKey(name: 'paid_by')  String? paidBy, @JsonKey(name: 'payment_date')  DateTime? paymentDate, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'invoice_pdf_url')  String? invoicePdfUrl, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'rejected_by')  String? rejectedBy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.propertyId,_that.contractId,_that.reporterId,_that.title,_that.category,_that.description,_that.status,_that.priority,_that.photosUrls,_that.costAmount,_that.settledAmount,_that.currency,_that.paidBy,_that.paymentDate,_that.paymentStatus,_that.invoicePdfUrl,_that.rejectionReason,_that.rejectedBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceRequest implements MaintenanceRequest {
  const _MaintenanceRequest({required this.id, @JsonKey(name: 'ticket_number') this.ticketNumber, @JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'contract_id') this.contractId, @JsonKey(name: 'reporter_id') required this.reporterId, required this.title, @JsonKey(unknownEnumValue: MaintenanceCategory.other) this.category = MaintenanceCategory.other, this.description, @JsonKey(unknownEnumValue: MaintenanceStatus.open) this.status = MaintenanceStatus.open, @JsonKey(unknownEnumValue: MaintenancePriority.normal) this.priority = MaintenancePriority.normal, @JsonKey(name: 'photos_urls') final  List<String> photosUrls = const [], @JsonKey(name: 'cost_amount') this.costAmount, @JsonKey(name: 'settled_amount') this.settledAmount = 0.0, this.currency, @JsonKey(name: 'paid_by') this.paidBy, @JsonKey(name: 'payment_date') this.paymentDate, @JsonKey(name: 'payment_status') this.paymentStatus = 'pending_review', @JsonKey(name: 'invoice_pdf_url') this.invoicePdfUrl, @JsonKey(name: 'rejection_reason') this.rejectionReason, @JsonKey(name: 'rejected_by') this.rejectedBy, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _photosUrls = photosUrls;
  factory _MaintenanceRequest.fromJson(Map<String, dynamic> json) => _$MaintenanceRequestFromJson(json);

@override final  String id;
@override@JsonKey(name: 'ticket_number') final  String? ticketNumber;
@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'contract_id') final  String? contractId;
@override@JsonKey(name: 'reporter_id') final  String reporterId;
@override final  String title;
@override@JsonKey(unknownEnumValue: MaintenanceCategory.other) final  MaintenanceCategory category;
@override final  String? description;
@override@JsonKey(unknownEnumValue: MaintenanceStatus.open) final  MaintenanceStatus status;
@override@JsonKey(unknownEnumValue: MaintenancePriority.normal) final  MaintenancePriority priority;
 final  List<String> _photosUrls;
@override@JsonKey(name: 'photos_urls') List<String> get photosUrls {
  if (_photosUrls is EqualUnmodifiableListView) return _photosUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photosUrls);
}

@override@JsonKey(name: 'cost_amount') final  double? costAmount;
@override@JsonKey(name: 'settled_amount') final  double settledAmount;
@override final  String? currency;
@override@JsonKey(name: 'paid_by') final  String? paidBy;
@override@JsonKey(name: 'payment_date') final  DateTime? paymentDate;
@override@JsonKey(name: 'payment_status') final  String paymentStatus;
@override@JsonKey(name: 'invoice_pdf_url') final  String? invoicePdfUrl;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
@override@JsonKey(name: 'rejected_by') final  String? rejectedBy;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._photosUrls, _photosUrls)&&(identical(other.costAmount, costAmount) || other.costAmount == costAmount)&&(identical(other.settledAmount, settledAmount) || other.settledAmount == settledAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.invoicePdfUrl, invoicePdfUrl) || other.invoicePdfUrl == invoicePdfUrl)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.rejectedBy, rejectedBy) || other.rejectedBy == rejectedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ticketNumber,propertyId,contractId,reporterId,title,category,description,status,priority,const DeepCollectionEquality().hash(_photosUrls),costAmount,settledAmount,currency,paidBy,paymentDate,paymentStatus,invoicePdfUrl,rejectionReason,rejectedBy,createdAt,updatedAt]);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, ticketNumber: $ticketNumber, propertyId: $propertyId, contractId: $contractId, reporterId: $reporterId, title: $title, category: $category, description: $description, status: $status, priority: $priority, photosUrls: $photosUrls, costAmount: $costAmount, settledAmount: $settledAmount, currency: $currency, paidBy: $paidBy, paymentDate: $paymentDate, paymentStatus: $paymentStatus, invoicePdfUrl: $invoicePdfUrl, rejectionReason: $rejectionReason, rejectedBy: $rejectedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceRequestCopyWith<$Res> implements $MaintenanceRequestCopyWith<$Res> {
  factory _$MaintenanceRequestCopyWith(_MaintenanceRequest value, $Res Function(_MaintenanceRequest) _then) = __$MaintenanceRequestCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'ticket_number') String? ticketNumber,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'reporter_id') String reporterId, String title,@JsonKey(unknownEnumValue: MaintenanceCategory.other) MaintenanceCategory category, String? description,@JsonKey(unknownEnumValue: MaintenanceStatus.open) MaintenanceStatus status,@JsonKey(unknownEnumValue: MaintenancePriority.normal) MaintenancePriority priority,@JsonKey(name: 'photos_urls') List<String> photosUrls,@JsonKey(name: 'cost_amount') double? costAmount,@JsonKey(name: 'settled_amount') double settledAmount, String? currency,@JsonKey(name: 'paid_by') String? paidBy,@JsonKey(name: 'payment_date') DateTime? paymentDate,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'invoice_pdf_url') String? invoicePdfUrl,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'rejected_by') String? rejectedBy,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketNumber = freezed,Object? propertyId = null,Object? contractId = freezed,Object? reporterId = null,Object? title = null,Object? category = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? photosUrls = null,Object? costAmount = freezed,Object? settledAmount = null,Object? currency = freezed,Object? paidBy = freezed,Object? paymentDate = freezed,Object? paymentStatus = null,Object? invoicePdfUrl = freezed,Object? rejectionReason = freezed,Object? rejectedBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MaintenanceRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: freezed == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as String?,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,photosUrls: null == photosUrls ? _self._photosUrls : photosUrls // ignore: cast_nullable_to_non_nullable
as List<String>,costAmount: freezed == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as double?,settledAmount: null == settledAmount ? _self.settledAmount : settledAmount // ignore: cast_nullable_to_non_nullable
as double,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,paidBy: freezed == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String?,paymentDate: freezed == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,invoicePdfUrl: freezed == invoicePdfUrl ? _self.invoicePdfUrl : invoicePdfUrl // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,rejectedBy: freezed == rejectedBy ? _self.rejectedBy : rejectedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
