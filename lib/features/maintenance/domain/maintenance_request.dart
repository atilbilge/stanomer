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
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MaintenanceRequest;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestFromJson(json);
}
