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

  factory MaintenanceMessage.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceMessageFromJson(json);
}
