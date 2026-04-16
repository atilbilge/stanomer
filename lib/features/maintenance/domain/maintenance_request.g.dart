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
          $enumDecodeNullable(_$MaintenanceCategoryEnumMap, json['category']) ??
          MaintenanceCategory.other,
      description: json['description'] as String?,
      status:
          $enumDecodeNullable(_$MaintenanceStatusEnumMap, json['status']) ??
          MaintenanceStatus.open,
      priority:
          $enumDecodeNullable(_$MaintenancePriorityEnumMap, json['priority']) ??
          MaintenancePriority.normal,
      photosUrls:
          (json['photos_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MaintenanceCategoryEnumMap = {
  MaintenanceCategory.plumbing: 'plumbing',
  MaintenanceCategory.electrical: 'electrical',
  MaintenanceCategory.heating: 'heating',
  MaintenanceCategory.internet: 'internet',
  MaintenanceCategory.other: 'other',
};

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.open: 'open',
  MaintenanceStatus.investigating: 'investigating',
  MaintenanceStatus.resolved: 'resolved',
};

const _$MaintenancePriorityEnumMap = {
  MaintenancePriority.normal: 'normal',
  MaintenancePriority.urgent: 'urgent',
};
