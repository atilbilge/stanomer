import 'package:flutter/foundation.dart';

@immutable
class MaintenanceCharge {
  final String id;
  final String maintenanceRequestId;
  final String propertyId;
  final String? createdBy;
  final String? title;
  final String chargeType; // 'direct_charge', 'agency_advance', 'reimbursement'
  final String approverRole; // 'agency', 'counterparty'
  final String? debtorId;
  final String? creditorId;
  final String? contractorName;
  final double amount;
  final double settledAmount;
  final String currency;
  final String status; // 'pending', 'declared', 'disputed', 'approved', 'rejected', 'paid'
  final String? contractorPaymentStatus; // 'unpaid', 'paid'
  final DateTime? contractorPaymentDate;
  final String? settlementMethod; // 'separate_payment', 'rent_offset'
  final String? receiptUrl;
  final String? disputeReason;
  final String? rejectionReason;
  final String? rejectedBy;
  final DateTime? declaredAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceCharge({
    required this.id,
    required this.maintenanceRequestId,
    required this.propertyId,
    this.createdBy,
    this.title,
    this.chargeType = 'direct_charge',
    this.approverRole = 'counterparty',
    this.debtorId,
    this.creditorId,
    this.contractorName,
    required this.amount,
    this.settledAmount = 0.00,
    this.currency = 'EUR',
    this.status = 'pending',
    this.contractorPaymentStatus,
    this.contractorPaymentDate,
    this.settlementMethod,
    this.receiptUrl,
    this.disputeReason,
    this.rejectionReason,
    this.rejectedBy,
    this.declaredAt,
    this.approvedAt,
    this.approvedBy,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => (amount - settledAmount).clamp(0.0, double.infinity);
  bool get isPaid => status == 'paid';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'declared';
  bool get isRejected => status == 'rejected';
  bool get isDisputed => status == 'disputed';
  bool get isRentOffset => settlementMethod == 'rent_offset';
  bool get isSeparatePayment => settlementMethod == 'separate_payment';
  bool get isAgencyAdvance => chargeType == 'agency_advance';
  bool get isReimbursement => chargeType == 'reimbursement';

  factory MaintenanceCharge.fromJson(Map<String, dynamic> json) {
    return MaintenanceCharge(
      id: json['id'] as String,
      maintenanceRequestId: json['maintenance_request_id'] as String,
      propertyId: json['property_id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String?,
      chargeType: json['charge_type'] as String? ?? 'direct_charge',
      approverRole: json['approver_role'] as String? ?? 'counterparty',
      debtorId: json['debtor_id'] as String?,
      creditorId: json['creditor_id'] as String?,
      contractorName: json['contractor_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      settledAmount: (json['settled_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      status: json['status'] as String? ?? 'pending',
      contractorPaymentStatus: json['contractor_payment_status'] as String?,
      contractorPaymentDate: json['contractor_payment_date'] != null
          ? DateTime.tryParse(json['contractor_payment_date'] as String)
          : null,
      settlementMethod: json['settlement_method'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      disputeReason: json['dispute_reason'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      rejectedBy: json['rejected_by'] as String?,
      declaredAt: json['declared_at'] != null
          ? DateTime.tryParse(json['declared_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maintenance_request_id': maintenanceRequestId,
      'property_id': propertyId,
      if (createdBy != null) 'created_by': createdBy,
      if (title != null) 'title': title,
      'charge_type': chargeType,
      'approver_role': approverRole,
      if (debtorId != null) 'debtor_id': debtorId,
      if (creditorId != null) 'creditor_id': creditorId,
      if (contractorName != null) 'contractor_name': contractorName,
      'amount': amount,
      'settled_amount': settledAmount,
      'currency': currency,
      'status': status,
      if (contractorPaymentStatus != null) 'contractor_payment_status': contractorPaymentStatus,
      if (contractorPaymentDate != null) 'contractor_payment_date': contractorPaymentDate!.toIso8601String(),
      if (settlementMethod != null) 'settlement_method': settlementMethod,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (disputeReason != null) 'dispute_reason': disputeReason,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (rejectedBy != null) 'rejected_by': rejectedBy,
      if (declaredAt != null) 'declared_at': declaredAt!.toIso8601String(),
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      if (approvedBy != null) 'approved_by': approvedBy,
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaintenanceCharge copyWith({
    String? id,
    String? maintenanceRequestId,
    String? propertyId,
    String? createdBy,
    String? title,
    String? chargeType,
    String? approverRole,
    String? debtorId,
    String? creditorId,
    String? contractorName,
    double? amount,
    double? settledAmount,
    String? currency,
    String? status,
    String? contractorPaymentStatus,
    DateTime? contractorPaymentDate,
    String? settlementMethod,
    String? receiptUrl,
    String? disputeReason,
    String? rejectionReason,
    String? rejectedBy,
    DateTime? declaredAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceCharge(
      id: id ?? this.id,
      maintenanceRequestId: maintenanceRequestId ?? this.maintenanceRequestId,
      propertyId: propertyId ?? this.propertyId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      chargeType: chargeType ?? this.chargeType,
      approverRole: approverRole ?? this.approverRole,
      debtorId: debtorId ?? this.debtorId,
      creditorId: creditorId ?? this.creditorId,
      contractorName: contractorName ?? this.contractorName,
      amount: amount ?? this.amount,
      settledAmount: settledAmount ?? this.settledAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      contractorPaymentStatus: contractorPaymentStatus ?? this.contractorPaymentStatus,
      contractorPaymentDate: contractorPaymentDate ?? this.contractorPaymentDate,
      settlementMethod: settlementMethod ?? this.settlementMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      disputeReason: disputeReason ?? this.disputeReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      declaredAt: declaredAt ?? this.declaredAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
