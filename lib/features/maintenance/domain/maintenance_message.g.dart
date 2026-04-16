// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaintenanceMessage _$MaintenanceMessageFromJson(Map<String, dynamic> json) =>
    _MaintenanceMessage(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MaintenanceMessageToJson(_MaintenanceMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'request_id': instance.requestId,
      'user_id': instance.userId,
      'message': instance.message,
      'photo_url': instance.photoUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
