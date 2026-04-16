import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_log.freezed.dart';
part 'activity_log.g.dart';

@freezed
abstract class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'user_id') String? userId,
    required String type,
    @Default({}) Map<String, dynamic> metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ActivityLog;

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
}
