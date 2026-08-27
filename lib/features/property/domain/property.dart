import 'package:freezed_annotation/freezed_annotation.dart';
import 'contract.dart';

part 'property.freezed.dart';
part 'property.g.dart';

@freezed
abstract class Property with _$Property {
  const factory Property({
    required String id,
    required String address,
    required String name,
    @JsonKey(name: 'city') String? city,
    @JsonKey(name: 'default_monthly_rent') required double defaultMonthlyRent,
    @JsonKey(name: 'default_deposit_amount') double? defaultDepositAmount,
    @Default('EUR') String currency,
    @Default('EUR') @JsonKey(name: 'default_deposit_currency') String defaultDepositCurrency,
    @JsonKey(name: 'landlord_id') String? landlordId,
    @JsonKey(name: 'tenant_id') String? tenantId,
    /// Agency managing this property (B2B2C: agency_id in profiles)
    @JsonKey(name: 'agency_id') String? agencyId,
    @JsonKey(name: 'landlord_name') String? landlordName,
    @JsonKey(name: 'landlord_phone') String? landlordPhone,
    @JsonKey(name: 'landlord_email') String? landlordEmail,
    @JsonKey(name: 'tenant_name') String? tenantName,
    @Default(1) @JsonKey(name: 'default_due_day') int defaultDueDay,
    @Default(TaxType.included) @JsonKey(name: 'tax_type') TaxType taxType,
    @Default([]) @JsonKey(name: 'expenses_template') List<ExpenseItem> expensesTemplate,
    // Detailed Property Fields
    @Default(false) @JsonKey(name: 'is_detailed') bool isDetailed,
    @JsonKey(name: 'property_type') String? propertyType,
    @JsonKey(name: 'unit_number') String? unitNumber,
    @JsonKey(name: 'room_count') String? roomCount,
    @JsonKey(name: 'area_sqm') double? areaSqm,
    @JsonKey(name: 'floor') String? floor,
    @JsonKey(name: 'total_floors') int? totalFloors,
    @JsonKey(name: 'furnishing') String? furnishing,
    @JsonKey(name: 'heating_type') String? heatingType,
    @Default([]) @JsonKey(name: 'amenities') List<String> amenities,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
}
