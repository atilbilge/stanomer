import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_message.freezed.dart';
part 'maintenance_message.g.dart';

@freezed
abstract class MaintenanceMessage with _$MaintenanceMessage {
  const factory MaintenanceMessage({
    required String id,
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'user_id') required String userId,
    required String message,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MaintenanceMessage;

  factory MaintenanceMessage.fromJson(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);
    sanitized['id'] = (sanitized['id'] ?? '').toString();
    sanitized['request_id'] = (sanitized['request_id'] ?? '').toString();
    sanitized['user_id'] = (sanitized['user_id'] ?? sanitized['sender_id'] ?? '').toString();
    sanitized['message'] = (sanitized['message'] ?? '').toString();
    if (sanitized['photo_url'] != null) {
      sanitized['photo_url'] = sanitized['photo_url'].toString();
    }
    if (sanitized['created_at'] == null) {
      sanitized['created_at'] = DateTime.now().toIso8601String();
    } else if (sanitized['created_at'] is DateTime) {
      sanitized['created_at'] = (sanitized['created_at'] as DateTime).toIso8601String();
    } else {
      final dt = DateTime.tryParse(sanitized['created_at'].toString());
      sanitized['created_at'] = (dt ?? DateTime.now()).toIso8601String();
    }
    return _$MaintenanceMessageFromJson(sanitized);
  }
}
