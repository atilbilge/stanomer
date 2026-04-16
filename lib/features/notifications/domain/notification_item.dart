import 'package:freezed_annotation/freezed_annotation.dart';

enum NotificationType {
  @JsonValue('rent') rent,
  @JsonValue('maintenance') maintenance,
  @JsonValue('contract') contract,
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.maintenance,
    this.relatedId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: _parseType(json['type'] as String?),
      relatedId: json['related_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'rent':
        return NotificationType.rent;
      case 'contract':
        return NotificationType.contract;
      case 'maintenance':
      default:
        return NotificationType.maintenance;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
