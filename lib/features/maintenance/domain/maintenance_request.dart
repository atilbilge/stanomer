import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_request.freezed.dart';
part 'maintenance_request.g.dart';

enum MaintenanceStatus {
  @JsonValue('open') open,
  @JsonValue('investigating') investigating,
  @JsonValue('in_progress') inProgress,
  @JsonValue('resolved') resolved,
  @JsonValue('closed') closed,
  @JsonValue('pending') pending,
  @JsonValue('cancelled') cancelled,
}

extension MaintenanceStatusX on MaintenanceStatus {
  String get value {
    switch (this) {
      case MaintenanceStatus.open: return 'open';
      case MaintenanceStatus.investigating: return 'investigating';
      case MaintenanceStatus.inProgress: return 'in_progress';
      case MaintenanceStatus.resolved: return 'resolved';
      case MaintenanceStatus.closed: return 'closed';
      case MaintenanceStatus.pending: return 'pending';
      case MaintenanceStatus.cancelled: return 'cancelled';
    }
  }
}

enum MaintenancePaymentStatus {
  @JsonValue('pending_review') pendingReview,
  @JsonValue('pending_payment') pendingPayment,
  @JsonValue('paid') paid,
  @JsonValue('rejected') rejected,
}

extension MaintenancePaymentStatusX on MaintenancePaymentStatus {
  String get value {
    switch (this) {
      case MaintenancePaymentStatus.pendingReview: return 'pending_review';
      case MaintenancePaymentStatus.pendingPayment: return 'pending_payment';
      case MaintenancePaymentStatus.paid: return 'paid';
      case MaintenancePaymentStatus.rejected: return 'rejected';
    }
  }

  static MaintenancePaymentStatus fromString(String? val) {
    switch (val) {
      case 'pending_payment': return MaintenancePaymentStatus.pendingPayment;
      case 'paid': return MaintenancePaymentStatus.paid;
      case 'rejected': return MaintenancePaymentStatus.rejected;
      case 'pending_review':
      case 'pending':
      default:
        return MaintenancePaymentStatus.pendingReview;
    }
  }
}

enum MaintenanceCategory {
  @JsonValue('plumbing') plumbing,
  @JsonValue('electrical') electrical,
  @JsonValue('heating') heating,
  @JsonValue('internet') internet,
  @JsonValue('appliance') appliance,
  @JsonValue('structural') structural,
  @JsonValue('other') other,
}

enum MaintenancePriority {
  @JsonValue('normal') normal,
  @JsonValue('medium') medium,
  @JsonValue('low') low,
  @JsonValue('urgent') urgent,
  @JsonValue('high') high,
}

@freezed
abstract class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'contract_id') String? contractId,
    @JsonKey(name: 'reporter_id') required String reporterId,
    required String title,
    @JsonKey(unknownEnumValue: MaintenanceCategory.other)
    @Default(MaintenanceCategory.other) MaintenanceCategory category,
    String? description,
    @JsonKey(unknownEnumValue: MaintenanceStatus.open)
    @Default(MaintenanceStatus.open) MaintenanceStatus status,
    @JsonKey(unknownEnumValue: MaintenancePriority.normal)
    @Default(MaintenancePriority.normal) MaintenancePriority priority,
    @Default([]) @JsonKey(name: 'photos_urls') List<String> photosUrls,
    @JsonKey(name: 'cost_amount') double? costAmount,
    @JsonKey(name: 'settled_amount') @Default(0.0) double settledAmount,
    String? currency,
    @JsonKey(name: 'paid_by') String? paidBy,
    @JsonKey(name: 'payment_date') DateTime? paymentDate,
    @JsonKey(name: 'payment_status') @Default('pending_review') String paymentStatus,
    @JsonKey(name: 'invoice_pdf_url') String? invoicePdfUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MaintenanceRequest;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestFromJson(json);

  factory MaintenanceRequest.fromMap(Map<String, dynamic> map) =>
      MaintenanceRequest.fromJson(map);
}

extension MaintenanceRequestMapX on MaintenanceRequest {
  Map<String, dynamic> toMap() => toJson();
  
  MaintenancePaymentStatus get financialStatus =>
      MaintenancePaymentStatusX.fromString(paymentStatus);

  double get remainingAmount => (costAmount != null ? (costAmount! - settledAmount).clamp(0.0, double.infinity) : 0.0);
  bool get hasPartialSettlement => settledAmount > 0 && remainingAmount > 0;
}

