// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rent_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RentPayment _$RentPaymentFromJson(Map<String, dynamic> json) => _RentPayment(
  id: json['id'] as String,
  propertyId: json['property_id'] as String,
  contractId: json['contract_id'] as String?,
  tenantId: json['tenant_id'] as String?,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  dueDate: DateTime.parse(json['due_date'] as String),
  status: json['status'] as String,
  receiptUrl: json['receipt_url'] as String?,
  invoiceUrl: json['invoice_url'] as String?,
  declaredAt: json['declared_at'] == null
      ? null
      : DateTime.parse(json['declared_at'] as String),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  disputeReason: json['dispute_reason'] as String?,
  disputedAt: json['disputed_at'] == null
      ? null
      : DateTime.parse(json['disputed_at'] as String),
  ownerNote: json['owner_note'] as String?,
  title: json['title'] as String? ?? 'Kira',
  receiverType: json['receiver_type'] as String? ?? 'owner',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RentPaymentToJson(_RentPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'contract_id': instance.contractId,
      'tenant_id': instance.tenantId,
      'amount': instance.amount,
      'currency': instance.currency,
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'receipt_url': instance.receiptUrl,
      'invoice_url': instance.invoiceUrl,
      'declared_at': instance.declaredAt?.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'dispute_reason': instance.disputeReason,
      'disputed_at': instance.disputedAt?.toIso8601String(),
      'owner_note': instance.ownerNote,
      'title': instance.title,
      'receiver_type': instance.receiverType,
      'created_at': instance.createdAt?.toIso8601String(),
    };
