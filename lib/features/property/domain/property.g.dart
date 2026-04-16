// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Property _$PropertyFromJson(Map<String, dynamic> json) => _Property(
  id: json['id'] as String,
  address: json['address'] as String,
  name: json['name'] as String,
  defaultMonthlyRent: (json['default_monthly_rent'] as num).toDouble(),
  defaultDepositAmount: (json['default_deposit_amount'] as num?)?.toDouble(),
  currency: json['currency'] as String? ?? 'EUR',
  defaultDepositCurrency: json['default_deposit_currency'] as String? ?? 'EUR',
  landlordId: json['landlord_id'] as String,
  tenantId: json['tenant_id'] as String?,
  landlordName: json['landlord_name'] as String?,
  tenantName: json['tenant_name'] as String?,
  defaultDueDay: (json['default_due_day'] as num?)?.toInt() ?? 1,
  taxType:
      $enumDecodeNullable(_$TaxTypeEnumMap, json['tax_type']) ??
      TaxType.included,
  expensesTemplate:
      (json['expenses_template'] as List<dynamic>?)
          ?.map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PropertyToJson(_Property instance) => <String, dynamic>{
  'id': instance.id,
  'address': instance.address,
  'name': instance.name,
  'default_monthly_rent': instance.defaultMonthlyRent,
  'default_deposit_amount': instance.defaultDepositAmount,
  'currency': instance.currency,
  'default_deposit_currency': instance.defaultDepositCurrency,
  'landlord_id': instance.landlordId,
  'tenant_id': instance.tenantId,
  'landlord_name': instance.landlordName,
  'tenant_name': instance.tenantName,
  'default_due_day': instance.defaultDueDay,
  'tax_type': _$TaxTypeEnumMap[instance.taxType]!,
  'expenses_template': instance.expensesTemplate,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$TaxTypeEnumMap = {TaxType.included: 'included', TaxType.added: 'added'};
