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
    @JsonKey(name: 'default_monthly_rent') required double defaultMonthlyRent,
    @JsonKey(name: 'default_deposit_amount') double? defaultDepositAmount,
    @Default('EUR') String currency,
    @Default('EUR') @JsonKey(name: 'default_deposit_currency') String defaultDepositCurrency,
    @JsonKey(name: 'landlord_id') required String landlordId,
    @JsonKey(name: 'tenant_id') String? tenantId,
    @JsonKey(name: 'landlord_name') String? landlordName,
    @JsonKey(name: 'tenant_name') String? tenantName,
    @Default(1) @JsonKey(name: 'default_due_day') int defaultDueDay,
    @Default(TaxType.included) @JsonKey(name: 'tax_type') TaxType taxType,
    @Default([]) @JsonKey(name: 'expenses_template') List<ExpenseItem> expensesTemplate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
}
