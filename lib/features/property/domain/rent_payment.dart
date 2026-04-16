import 'package:freezed_annotation/freezed_annotation.dart';

part 'rent_payment.freezed.dart';
part 'rent_payment.g.dart';

@freezed
abstract class RentPayment with _$RentPayment {
  const factory RentPayment({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'contract_id') String? contractId,
    @JsonKey(name: 'tenant_id') String? tenantId,
    required double amount,
    required String currency,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    required String status, // 'pending', 'declared', or 'paid'
    @JsonKey(name: 'receipt_url') String? receiptUrl,
    @JsonKey(name: 'invoice_url') String? invoiceUrl,
    @JsonKey(name: 'declared_at') DateTime? declaredAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'dispute_reason') String? disputeReason,
    @JsonKey(name: 'disputed_at') DateTime? disputedAt,
    @JsonKey(name: 'owner_note') String? ownerNote,
    @Default('Kira') String title,
    @Default('owner') @JsonKey(name: 'receiver_type') String receiverType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _RentPayment;

  factory RentPayment.fromJson(Map<String, dynamic> json) => _$RentPaymentFromJson(json);
}

