// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rent_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RentPayment {

 String get id;@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'contract_id') String? get contractId;@JsonKey(name: 'tenant_id') String? get tenantId; double get amount; String get currency;@JsonKey(name: 'due_date') DateTime get dueDate; String get status;// 'pending', 'declared', or 'paid'
@JsonKey(name: 'receipt_url') String? get receiptUrl;@JsonKey(name: 'invoice_url') String? get invoiceUrl;@JsonKey(name: 'declared_at') DateTime? get declaredAt;@JsonKey(name: 'paid_at') DateTime? get paidAt;@JsonKey(name: 'dispute_reason') String? get disputeReason;@JsonKey(name: 'disputed_at') DateTime? get disputedAt;@JsonKey(name: 'owner_note') String? get ownerNote; String get title;@JsonKey(name: 'receiver_type') String get receiverType;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of RentPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RentPaymentCopyWith<RentPayment> get copyWith => _$RentPaymentCopyWithImpl<RentPayment>(this as RentPayment, _$identity);

  /// Serializes this RentPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RentPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.invoiceUrl, invoiceUrl) || other.invoiceUrl == invoiceUrl)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.disputeReason, disputeReason) || other.disputeReason == disputeReason)&&(identical(other.disputedAt, disputedAt) || other.disputedAt == disputedAt)&&(identical(other.ownerNote, ownerNote) || other.ownerNote == ownerNote)&&(identical(other.title, title) || other.title == title)&&(identical(other.receiverType, receiverType) || other.receiverType == receiverType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,contractId,tenantId,amount,currency,dueDate,status,receiptUrl,invoiceUrl,declaredAt,paidAt,disputeReason,disputedAt,ownerNote,title,receiverType,createdAt);

@override
String toString() {
  return 'RentPayment(id: $id, propertyId: $propertyId, contractId: $contractId, tenantId: $tenantId, amount: $amount, currency: $currency, dueDate: $dueDate, status: $status, receiptUrl: $receiptUrl, invoiceUrl: $invoiceUrl, declaredAt: $declaredAt, paidAt: $paidAt, disputeReason: $disputeReason, disputedAt: $disputedAt, ownerNote: $ownerNote, title: $title, receiverType: $receiverType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RentPaymentCopyWith<$Res>  {
  factory $RentPaymentCopyWith(RentPayment value, $Res Function(RentPayment) _then) = _$RentPaymentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'tenant_id') String? tenantId, double amount, String currency,@JsonKey(name: 'due_date') DateTime dueDate, String status,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'invoice_url') String? invoiceUrl,@JsonKey(name: 'declared_at') DateTime? declaredAt,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'dispute_reason') String? disputeReason,@JsonKey(name: 'disputed_at') DateTime? disputedAt,@JsonKey(name: 'owner_note') String? ownerNote, String title,@JsonKey(name: 'receiver_type') String receiverType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$RentPaymentCopyWithImpl<$Res>
    implements $RentPaymentCopyWith<$Res> {
  _$RentPaymentCopyWithImpl(this._self, this._then);

  final RentPayment _self;
  final $Res Function(RentPayment) _then;

/// Create a copy of RentPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? contractId = freezed,Object? tenantId = freezed,Object? amount = null,Object? currency = null,Object? dueDate = null,Object? status = null,Object? receiptUrl = freezed,Object? invoiceUrl = freezed,Object? declaredAt = freezed,Object? paidAt = freezed,Object? disputeReason = freezed,Object? disputedAt = freezed,Object? ownerNote = freezed,Object? title = null,Object? receiverType = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,invoiceUrl: freezed == invoiceUrl ? _self.invoiceUrl : invoiceUrl // ignore: cast_nullable_to_non_nullable
as String?,declaredAt: freezed == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disputeReason: freezed == disputeReason ? _self.disputeReason : disputeReason // ignore: cast_nullable_to_non_nullable
as String?,disputedAt: freezed == disputedAt ? _self.disputedAt : disputedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerNote: freezed == ownerNote ? _self.ownerNote : ownerNote // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,receiverType: null == receiverType ? _self.receiverType : receiverType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RentPayment].
extension RentPaymentPatterns on RentPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RentPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RentPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RentPayment value)  $default,){
final _that = this;
switch (_that) {
case _RentPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RentPayment value)?  $default,){
final _that = this;
switch (_that) {
case _RentPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'tenant_id')  String? tenantId,  double amount,  String currency, @JsonKey(name: 'due_date')  DateTime dueDate,  String status, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'invoice_url')  String? invoiceUrl, @JsonKey(name: 'declared_at')  DateTime? declaredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'dispute_reason')  String? disputeReason, @JsonKey(name: 'disputed_at')  DateTime? disputedAt, @JsonKey(name: 'owner_note')  String? ownerNote,  String title, @JsonKey(name: 'receiver_type')  String receiverType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RentPayment() when $default != null:
return $default(_that.id,_that.propertyId,_that.contractId,_that.tenantId,_that.amount,_that.currency,_that.dueDate,_that.status,_that.receiptUrl,_that.invoiceUrl,_that.declaredAt,_that.paidAt,_that.disputeReason,_that.disputedAt,_that.ownerNote,_that.title,_that.receiverType,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'tenant_id')  String? tenantId,  double amount,  String currency, @JsonKey(name: 'due_date')  DateTime dueDate,  String status, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'invoice_url')  String? invoiceUrl, @JsonKey(name: 'declared_at')  DateTime? declaredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'dispute_reason')  String? disputeReason, @JsonKey(name: 'disputed_at')  DateTime? disputedAt, @JsonKey(name: 'owner_note')  String? ownerNote,  String title, @JsonKey(name: 'receiver_type')  String receiverType, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _RentPayment():
return $default(_that.id,_that.propertyId,_that.contractId,_that.tenantId,_that.amount,_that.currency,_that.dueDate,_that.status,_that.receiptUrl,_that.invoiceUrl,_that.declaredAt,_that.paidAt,_that.disputeReason,_that.disputedAt,_that.ownerNote,_that.title,_that.receiverType,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'contract_id')  String? contractId, @JsonKey(name: 'tenant_id')  String? tenantId,  double amount,  String currency, @JsonKey(name: 'due_date')  DateTime dueDate,  String status, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'invoice_url')  String? invoiceUrl, @JsonKey(name: 'declared_at')  DateTime? declaredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'dispute_reason')  String? disputeReason, @JsonKey(name: 'disputed_at')  DateTime? disputedAt, @JsonKey(name: 'owner_note')  String? ownerNote,  String title, @JsonKey(name: 'receiver_type')  String receiverType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RentPayment() when $default != null:
return $default(_that.id,_that.propertyId,_that.contractId,_that.tenantId,_that.amount,_that.currency,_that.dueDate,_that.status,_that.receiptUrl,_that.invoiceUrl,_that.declaredAt,_that.paidAt,_that.disputeReason,_that.disputedAt,_that.ownerNote,_that.title,_that.receiverType,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RentPayment implements RentPayment {
  const _RentPayment({required this.id, @JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'contract_id') this.contractId, @JsonKey(name: 'tenant_id') this.tenantId, required this.amount, required this.currency, @JsonKey(name: 'due_date') required this.dueDate, required this.status, @JsonKey(name: 'receipt_url') this.receiptUrl, @JsonKey(name: 'invoice_url') this.invoiceUrl, @JsonKey(name: 'declared_at') this.declaredAt, @JsonKey(name: 'paid_at') this.paidAt, @JsonKey(name: 'dispute_reason') this.disputeReason, @JsonKey(name: 'disputed_at') this.disputedAt, @JsonKey(name: 'owner_note') this.ownerNote, this.title = 'Kira', @JsonKey(name: 'receiver_type') this.receiverType = 'owner', @JsonKey(name: 'created_at') this.createdAt});
  factory _RentPayment.fromJson(Map<String, dynamic> json) => _$RentPaymentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'contract_id') final  String? contractId;
@override@JsonKey(name: 'tenant_id') final  String? tenantId;
@override final  double amount;
@override final  String currency;
@override@JsonKey(name: 'due_date') final  DateTime dueDate;
@override final  String status;
// 'pending', 'declared', or 'paid'
@override@JsonKey(name: 'receipt_url') final  String? receiptUrl;
@override@JsonKey(name: 'invoice_url') final  String? invoiceUrl;
@override@JsonKey(name: 'declared_at') final  DateTime? declaredAt;
@override@JsonKey(name: 'paid_at') final  DateTime? paidAt;
@override@JsonKey(name: 'dispute_reason') final  String? disputeReason;
@override@JsonKey(name: 'disputed_at') final  DateTime? disputedAt;
@override@JsonKey(name: 'owner_note') final  String? ownerNote;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'receiver_type') final  String receiverType;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of RentPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RentPaymentCopyWith<_RentPayment> get copyWith => __$RentPaymentCopyWithImpl<_RentPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RentPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RentPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.invoiceUrl, invoiceUrl) || other.invoiceUrl == invoiceUrl)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.disputeReason, disputeReason) || other.disputeReason == disputeReason)&&(identical(other.disputedAt, disputedAt) || other.disputedAt == disputedAt)&&(identical(other.ownerNote, ownerNote) || other.ownerNote == ownerNote)&&(identical(other.title, title) || other.title == title)&&(identical(other.receiverType, receiverType) || other.receiverType == receiverType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,contractId,tenantId,amount,currency,dueDate,status,receiptUrl,invoiceUrl,declaredAt,paidAt,disputeReason,disputedAt,ownerNote,title,receiverType,createdAt);

@override
String toString() {
  return 'RentPayment(id: $id, propertyId: $propertyId, contractId: $contractId, tenantId: $tenantId, amount: $amount, currency: $currency, dueDate: $dueDate, status: $status, receiptUrl: $receiptUrl, invoiceUrl: $invoiceUrl, declaredAt: $declaredAt, paidAt: $paidAt, disputeReason: $disputeReason, disputedAt: $disputedAt, ownerNote: $ownerNote, title: $title, receiverType: $receiverType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RentPaymentCopyWith<$Res> implements $RentPaymentCopyWith<$Res> {
  factory _$RentPaymentCopyWith(_RentPayment value, $Res Function(_RentPayment) _then) = __$RentPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'contract_id') String? contractId,@JsonKey(name: 'tenant_id') String? tenantId, double amount, String currency,@JsonKey(name: 'due_date') DateTime dueDate, String status,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'invoice_url') String? invoiceUrl,@JsonKey(name: 'declared_at') DateTime? declaredAt,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'dispute_reason') String? disputeReason,@JsonKey(name: 'disputed_at') DateTime? disputedAt,@JsonKey(name: 'owner_note') String? ownerNote, String title,@JsonKey(name: 'receiver_type') String receiverType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$RentPaymentCopyWithImpl<$Res>
    implements _$RentPaymentCopyWith<$Res> {
  __$RentPaymentCopyWithImpl(this._self, this._then);

  final _RentPayment _self;
  final $Res Function(_RentPayment) _then;

/// Create a copy of RentPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? contractId = freezed,Object? tenantId = freezed,Object? amount = null,Object? currency = null,Object? dueDate = null,Object? status = null,Object? receiptUrl = freezed,Object? invoiceUrl = freezed,Object? declaredAt = freezed,Object? paidAt = freezed,Object? disputeReason = freezed,Object? disputedAt = freezed,Object? ownerNote = freezed,Object? title = null,Object? receiverType = null,Object? createdAt = freezed,}) {
  return _then(_RentPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,invoiceUrl: freezed == invoiceUrl ? _self.invoiceUrl : invoiceUrl // ignore: cast_nullable_to_non_nullable
as String?,declaredAt: freezed == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disputeReason: freezed == disputeReason ? _self.disputeReason : disputeReason // ignore: cast_nullable_to_non_nullable
as String?,disputedAt: freezed == disputedAt ? _self.disputedAt : disputedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerNote: freezed == ownerNote ? _self.ownerNote : ownerNote // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,receiverType: null == receiverType ? _self.receiverType : receiverType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
