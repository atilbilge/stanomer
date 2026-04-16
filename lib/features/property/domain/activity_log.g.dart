// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) => _ActivityLog(
  id: json['id'] as String,
  propertyId: json['property_id'] as String,
  userId: json['user_id'] as String?,
  type: json['type'] as String,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ActivityLogToJson(_ActivityLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'user_id': instance.userId,
      'type': instance.type,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
    };
