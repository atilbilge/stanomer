import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_request.freezed.dart';
part 'maintenance_request.g.dart';

enum MaintenanceStatus {
  @JsonValue('open') open,
  @JsonValue('investigating') investigating,
  @JsonValue('resolved') resolved,
}

enum MaintenanceCategory {
  @JsonValue('plumbing') plumbing,
  @JsonValue('electrical') electrical,
  @JsonValue('heating') heating,
  @JsonValue('internet') internet,
  @JsonValue('other') other,
}

enum MaintenancePriority {
  @JsonValue('normal') normal,
  @JsonValue('urgent') urgent,
}

@freezed
abstract class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'contract_id') String? contractId,
    @JsonKey(name: 'reporter_id') required String reporterId,
    required String title,
    @Default(MaintenanceCategory.other) MaintenanceCategory category,
    String? description,
    @Default(MaintenanceStatus.open) MaintenanceStatus status,
    @Default(MaintenancePriority.normal) MaintenancePriority priority,
    @Default([]) @JsonKey(name: 'photos_urls') List<String> photosUrls,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MaintenanceRequest;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestFromJson(json);
}
