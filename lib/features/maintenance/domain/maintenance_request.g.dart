// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaintenanceRequest _$MaintenanceRequestFromJson(Map<String, dynamic> json) =>
    _MaintenanceRequest(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      contractId: json['contract_id'] as String?,
      reporterId: json['reporter_id'] as String,
      title: json['title'] as String,
      category:
          $enumDecodeNullable(
            _$MaintenanceCategoryEnumMap,
            json['category'],
            unknownValue: MaintenanceCategory.other,
          ) ??
          MaintenanceCategory.other,
      description: json['description'] as String?,
      status:
          $enumDecodeNullable(
            _$MaintenanceStatusEnumMap,
            json['status'],
            unknownValue: MaintenanceStatus.open,
          ) ??
          MaintenanceStatus.open,
      priority:
          $enumDecodeNullable(
            _$MaintenancePriorityEnumMap,
            json['priority'],
            unknownValue: MaintenancePriority.normal,
          ) ??
          MaintenancePriority.normal,
      photosUrls:
          (json['photos_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      costAmount: (json['cost_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      paidBy: json['paid_by'] as String?,
      paymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
      paymentStatus: json['payment_status'] as String? ?? 'pending_review',
      invoicePdfUrl: json['invoice_pdf_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MaintenanceRequestToJson(_MaintenanceRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'contract_id': instance.contractId,
      'reporter_id': instance.reporterId,
      'title': instance.title,
      'category': _$MaintenanceCategoryEnumMap[instance.category]!,
      'description': instance.description,
      'status': _$MaintenanceStatusEnumMap[instance.status]!,
      'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
      'photos_urls': instance.photosUrls,
      'cost_amount': instance.costAmount,
      'currency': instance.currency,
      'paid_by': instance.paidBy,
      'payment_date': instance.paymentDate?.toIso8601String(),
      'payment_status': instance.paymentStatus,
      'invoice_pdf_url': instance.invoicePdfUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MaintenanceCategoryEnumMap = {
  MaintenanceCategory.plumbing: 'plumbing',
  MaintenanceCategory.electrical: 'electrical',
  MaintenanceCategory.heating: 'heating',
  MaintenanceCategory.internet: 'internet',
  MaintenanceCategory.appliance: 'appliance',
  MaintenanceCategory.structural: 'structural',
  MaintenanceCategory.other: 'other',
};

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.open: 'open',
  MaintenanceStatus.investigating: 'investigating',
  MaintenanceStatus.inProgress: 'in_progress',
  MaintenanceStatus.resolved: 'resolved',
  MaintenanceStatus.closed: 'closed',
  MaintenanceStatus.pending: 'pending',
  MaintenanceStatus.cancelled: 'cancelled',
};

const _$MaintenancePriorityEnumMap = {
  MaintenancePriority.normal: 'normal',
  MaintenancePriority.medium: 'medium',
  MaintenancePriority.low: 'low',
  MaintenancePriority.urgent: 'urgent',
  MaintenancePriority.high: 'high',
};
