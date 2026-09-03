import '../../../core/l10n/app_localizations.dart';
import 'tenant_secondary_contact.dart';

enum PaymentReceiver {
  unselected,
  included,
  utility,
  owner,
}

enum TaxType {
  included,
  added,
}

class ExpenseItem {
  final String name;
  final PaymentReceiver receiver;
  final double amount;
  final String paymentMethod; // 'bank_transfer' or 'cash'

  const ExpenseItem({
    required this.name,
    this.receiver = PaymentReceiver.included,
    this.amount = 0.0,
    this.paymentMethod = 'bank_transfer',
  });

  bool get isIncluded => receiver == PaymentReceiver.included;
  bool get isCash => paymentMethod == 'cash';

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      name: json['name'] as String,
      receiver: _parseReceiver(json['receiver'] as String?),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'bank_transfer',
    );
  }

  static PaymentReceiver _parseReceiver(String? receiver) {
    switch (receiver) {
      case 'included': return PaymentReceiver.included;
      case 'utility': return PaymentReceiver.utility;
      case 'owner': return PaymentReceiver.owner;
      default: return PaymentReceiver.unselected;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'receiver': receiver.name,
      'amount': amount,
      'payment_method': paymentMethod,
    };
  }

  ExpenseItem copyWith({String? name, PaymentReceiver? receiver, double? amount, String? paymentMethod}) {
    return ExpenseItem(
      name: name ?? this.name,
      receiver: receiver ?? this.receiver,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

enum ContractStatus {
  pending,
  negotiating,
  active,
  declined,
  expired,
  revisionRequested,
  terminationRequested,
  inactive,
}

extension ContractStatusX on ContractStatus {
  String label(AppLocalizations loc) {
    switch (this) {
      case ContractStatus.pending:
        return loc.statusPending;
      case ContractStatus.negotiating:
        return loc.statusNegotiating;
      case ContractStatus.active:
        return loc.statusActive;
      case ContractStatus.declined:
        return loc.statusDeclined;
      case ContractStatus.expired:
        return loc.statusExpired;
      case ContractStatus.revisionRequested:
        return this == ContractStatus.expired ? loc.statusExpired : loc.revisionRequested;
      case ContractStatus.terminationRequested:
        return loc.terminationRequested;
      case ContractStatus.inactive:
        return loc.statusInactive;
    }
  }
}

class ContractDocument {
  final String name;
  final String url;
  final DateTime? createdAt;

  const ContractDocument({
    required this.name,
    required this.url,
    this.createdAt,
  });

  factory ContractDocument.fromJson(Map<String, dynamic> json) {
    return ContractDocument(
      name: json['name'] as String,
      url: json['url'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Contract {
  final String id;
  final String propertyId;
  final String landlordId;
  final String? inviterName;
  final String? tenantId;
  /// Agency managing this contract (B2B2C: agency_id in profiles)
  final String? agencyId;
  final String inviteeEmail;
  final double monthlyRent;
  final double? depositAmount;
  final String currency;
  final String depositCurrency;
  final int dueDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ExpenseItem> expensesConfig;
  final TaxType taxType;
  final List<ContractDocument> additionalDocuments;
  final ContractStatus status;
  final String? tenantFeedback;
  final String token;
  final String? contractUrl;
  final Map<String, dynamic>? proposedChanges;
  final String? proposedBy;
  final bool terminationApproved;
  final String? tenantIdNumber;
  final String? tenantPhone;
  final String? tenantNotes;
  final String? tenantIdDocumentUrl;
  final List<TenantSecondaryContact> tenantSecondaryContacts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Contract({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    this.inviterName,
    this.tenantId,
    this.agencyId,
    required this.inviteeEmail,
    required this.monthlyRent,
    this.depositAmount,
    this.currency = 'EUR',
    this.depositCurrency = 'EUR',
    this.dueDay = 1,
    this.startDate,
    this.endDate,
    this.expensesConfig = const [],
    this.taxType = TaxType.included,
    this.additionalDocuments = const [],
    this.status = ContractStatus.pending,
    this.tenantFeedback,
    required this.token,
    this.contractUrl,
    this.proposedChanges,
    this.proposedBy,
    this.terminationApproved = false,
    this.tenantIdNumber,
    this.tenantPhone,
    this.tenantNotes,
    this.tenantIdDocumentUrl,
    this.tenantSecondaryContacts = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String? ?? '',
      propertyId: (json['property_id'] ?? json['propertyId']) as String? ?? '',
      landlordId: (json['landlord_id'] ?? json['landlordId']) as String? ?? '',
      inviterName: json['inviter_name'] as String?,
      tenantId: json['tenant_id'] as String?,
      agencyId: json['agency_id'] as String?,
      inviteeEmail: json['invitee_email'] as String? ?? '',
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      depositCurrency: json['deposit_currency'] as String? ?? json['currency'] as String? ?? 'EUR',
      dueDay: json['due_day'] as int? ?? 1,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      expensesConfig: (json['expenses_config'] as List?)
              ?.map((e) => e is ExpenseItem ? e : ExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      taxType: _parseTaxType(json['tax_type'] as String?),
      additionalDocuments: (json['additional_documents'] as List?)
              ?.map((e) => ContractDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(json['status'] as String?, json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null),
      tenantFeedback: json['tenant_feedback'] as String?,
      token: json['token'] as String? ?? '',
      contractUrl: json['contract_url'] as String?,
      proposedChanges: json['proposed_changes'] as Map<String, dynamic>?,
      proposedBy: json['proposed_by'] as String?,
      terminationApproved: json['termination_approved'] as bool? ?? false,
      tenantIdNumber: json['tenant_id_number'] as String?,
      tenantPhone: json['tenant_phone'] as String?,
      tenantNotes: json['tenant_notes'] as String?,
      tenantIdDocumentUrl: json['tenant_id_document_url'] as String?,
      tenantSecondaryContacts: (json['tenant_secondary_contacts'] as List?)
              ?.map((e) => TenantSecondaryContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  static TaxType _parseTaxType(String? type) {
    return type == 'added' ? TaxType.added : TaxType.included;
  }

  static ContractStatus _parseStatus(String? status, DateTime? endDate) {
    ContractStatus baseStatus;
    switch (status) {
      case 'negotiating': baseStatus = ContractStatus.negotiating; break;
      case 'active': baseStatus = ContractStatus.active; break;
      case 'declined': baseStatus = ContractStatus.declined; break;
      case 'expired': baseStatus = ContractStatus.expired; break;
      case 'revision_requested': baseStatus = ContractStatus.revisionRequested; break;
      case 'termination_requested': baseStatus = ContractStatus.terminationRequested; break;
      case 'inactive': baseStatus = ContractStatus.inactive; break;
      default: baseStatus = ContractStatus.pending;
    }

    if (endDate != null && (baseStatus == ContractStatus.active || baseStatus == ContractStatus.revisionRequested)) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final comparisonDate = DateTime(endDate.year, endDate.month, endDate.day);
      if (comparisonDate.isBefore(today) || comparisonDate.isAtSameMomentAs(today)) {
        return ContractStatus.expired;
      }
    }
    return baseStatus;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'landlord_id': landlordId,
      'inviter_name': inviterName,
      'tenant_id': tenantId,
      'agency_id': agencyId,
      'invitee_email': inviteeEmail,
      'monthly_rent': monthlyRent,
      'deposit_amount': depositAmount,
      'currency': currency,
      'deposit_currency': depositCurrency,
      'due_day': dueDay,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'expenses_config': expensesConfig.map((e) => e.toJson()).toList(),
      'tax_type': taxType.name,
      'additional_documents': additionalDocuments.map((e) => e.toJson()).toList(),
      'status': status.name,
      'tenant_feedback': tenantFeedback,
      'token': token,
      'contract_url': contractUrl,
      'proposed_changes': proposedChanges,
      'proposed_by': proposedBy,
      'termination_approved': terminationApproved,
      if (tenantIdNumber != null) 'tenant_id_number': tenantIdNumber,
      if (tenantPhone != null) 'tenant_phone': tenantPhone,
      if (tenantNotes != null) 'tenant_notes': tenantNotes,
      if (tenantIdDocumentUrl != null) 'tenant_id_document_url': tenantIdDocumentUrl,
      'tenant_secondary_contacts': tenantSecondaryContacts.map((c) => c.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Contract copyWith({
    String? id,
    String? propertyId,
    String? landlordId,
    String? inviterName,
    String? tenantId,
    String? agencyId,
    String? inviteeEmail,
    double? monthlyRent,
    double? depositAmount,
    String? currency,
    String? depositCurrency,
    int? dueDay,
    DateTime? startDate,
    DateTime? endDate,
    List<ExpenseItem>? expensesConfig,
    TaxType? taxType,
    List<ContractDocument>? additionalDocuments,
    ContractStatus? status,
    String? tenantFeedback,
    String? token,
    String? contractUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? proposedChanges,
    String? proposedBy,
    bool? terminationApproved,
    String? tenantIdNumber,
    String? tenantPhone,
    String? tenantNotes,
    String? tenantIdDocumentUrl,
    List<TenantSecondaryContact>? tenantSecondaryContacts,
  }) {
    return Contract(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      landlordId: landlordId ?? this.landlordId,
      inviterName: inviterName ?? this.inviterName,
      tenantId: tenantId ?? this.tenantId,
      agencyId: agencyId ?? this.agencyId,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      depositAmount: depositAmount ?? this.depositAmount,
      currency: currency ?? this.currency,
      depositCurrency: depositCurrency ?? this.depositCurrency,
      dueDay: dueDay ?? this.dueDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expensesConfig: expensesConfig ?? this.expensesConfig,
      taxType: taxType ?? this.taxType,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
      status: status ?? this.status,
      tenantFeedback: tenantFeedback ?? this.tenantFeedback,
      token: token ?? this.token,
      contractUrl: contractUrl ?? this.contractUrl,
      proposedChanges: proposedChanges ?? this.proposedChanges,
      proposedBy: proposedBy ?? this.proposedBy,
      terminationApproved: terminationApproved ?? this.terminationApproved,
      tenantIdNumber: tenantIdNumber ?? this.tenantIdNumber,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      tenantNotes: tenantNotes ?? this.tenantNotes,
      tenantIdDocumentUrl: tenantIdDocumentUrl ?? this.tenantIdDocumentUrl,
      tenantSecondaryContacts: tenantSecondaryContacts ?? this.tenantSecondaryContacts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEnded {
    if (endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final comparisonDate = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return comparisonDate.isBefore(today) || comparisonDate.isAtSameMomentAs(today);
  }
}
