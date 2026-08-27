// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Property {

 String get id; String get address; String get name;@JsonKey(name: 'city') String? get city;@JsonKey(name: 'default_monthly_rent') double get defaultMonthlyRent;@JsonKey(name: 'default_deposit_amount') double? get defaultDepositAmount; String get currency;@JsonKey(name: 'default_deposit_currency') String get defaultDepositCurrency;@JsonKey(name: 'landlord_id') String? get landlordId;@JsonKey(name: 'tenant_id') String? get tenantId;/// Agency managing this property (B2B2C: agency_id in profiles)
@JsonKey(name: 'agency_id') String? get agencyId;@JsonKey(name: 'landlord_name') String? get landlordName;@JsonKey(name: 'landlord_phone') String? get landlordPhone;@JsonKey(name: 'landlord_email') String? get landlordEmail;@JsonKey(name: 'tenant_name') String? get tenantName;@JsonKey(name: 'default_due_day') int get defaultDueDay;@JsonKey(name: 'tax_type') TaxType get taxType;@JsonKey(name: 'expenses_template') List<ExpenseItem> get expensesTemplate;// Detailed Property Fields
@JsonKey(name: 'is_detailed') bool get isDetailed;@JsonKey(name: 'property_type') String? get propertyType;@JsonKey(name: 'unit_number') String? get unitNumber;@JsonKey(name: 'room_count') String? get roomCount;@JsonKey(name: 'area_sqm') double? get areaSqm;@JsonKey(name: 'floor') String? get floor;@JsonKey(name: 'total_floors') int? get totalFloors;@JsonKey(name: 'furnishing') String? get furnishing;@JsonKey(name: 'heating_type') String? get heatingType;@JsonKey(name: 'amenities') List<String> get amenities;@JsonKey(name: 'description') String? get description;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyCopyWith<Property> get copyWith => _$PropertyCopyWithImpl<Property>(this as Property, _$identity);

  /// Serializes this Property to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Property&&(identical(other.id, id) || other.id == id)&&(identical(other.address, address) || other.address == address)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.defaultMonthlyRent, defaultMonthlyRent) || other.defaultMonthlyRent == defaultMonthlyRent)&&(identical(other.defaultDepositAmount, defaultDepositAmount) || other.defaultDepositAmount == defaultDepositAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.defaultDepositCurrency, defaultDepositCurrency) || other.defaultDepositCurrency == defaultDepositCurrency)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.agencyId, agencyId) || other.agencyId == agencyId)&&(identical(other.landlordName, landlordName) || other.landlordName == landlordName)&&(identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone)&&(identical(other.landlordEmail, landlordEmail) || other.landlordEmail == landlordEmail)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.defaultDueDay, defaultDueDay) || other.defaultDueDay == defaultDueDay)&&(identical(other.taxType, taxType) || other.taxType == taxType)&&const DeepCollectionEquality().equals(other.expensesTemplate, expensesTemplate)&&(identical(other.isDetailed, isDetailed) || other.isDetailed == isDetailed)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.roomCount, roomCount) || other.roomCount == roomCount)&&(identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.furnishing, furnishing) || other.furnishing == furnishing)&&(identical(other.heatingType, heatingType) || other.heatingType == heatingType)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,address,name,city,defaultMonthlyRent,defaultDepositAmount,currency,defaultDepositCurrency,landlordId,tenantId,agencyId,landlordName,landlordPhone,landlordEmail,tenantName,defaultDueDay,taxType,const DeepCollectionEquality().hash(expensesTemplate),isDetailed,propertyType,unitNumber,roomCount,areaSqm,floor,totalFloors,furnishing,heatingType,const DeepCollectionEquality().hash(amenities),description,createdAt]);

@override
String toString() {
  return 'Property(id: $id, address: $address, name: $name, city: $city, defaultMonthlyRent: $defaultMonthlyRent, defaultDepositAmount: $defaultDepositAmount, currency: $currency, defaultDepositCurrency: $defaultDepositCurrency, landlordId: $landlordId, tenantId: $tenantId, agencyId: $agencyId, landlordName: $landlordName, landlordPhone: $landlordPhone, landlordEmail: $landlordEmail, tenantName: $tenantName, defaultDueDay: $defaultDueDay, taxType: $taxType, expensesTemplate: $expensesTemplate, isDetailed: $isDetailed, propertyType: $propertyType, unitNumber: $unitNumber, roomCount: $roomCount, areaSqm: $areaSqm, floor: $floor, totalFloors: $totalFloors, furnishing: $furnishing, heatingType: $heatingType, amenities: $amenities, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PropertyCopyWith<$Res>  {
  factory $PropertyCopyWith(Property value, $Res Function(Property) _then) = _$PropertyCopyWithImpl;
@useResult
$Res call({
 String id, String address, String name,@JsonKey(name: 'city') String? city,@JsonKey(name: 'default_monthly_rent') double defaultMonthlyRent,@JsonKey(name: 'default_deposit_amount') double? defaultDepositAmount, String currency,@JsonKey(name: 'default_deposit_currency') String defaultDepositCurrency,@JsonKey(name: 'landlord_id') String? landlordId,@JsonKey(name: 'tenant_id') String? tenantId,@JsonKey(name: 'agency_id') String? agencyId,@JsonKey(name: 'landlord_name') String? landlordName,@JsonKey(name: 'landlord_phone') String? landlordPhone,@JsonKey(name: 'landlord_email') String? landlordEmail,@JsonKey(name: 'tenant_name') String? tenantName,@JsonKey(name: 'default_due_day') int defaultDueDay,@JsonKey(name: 'tax_type') TaxType taxType,@JsonKey(name: 'expenses_template') List<ExpenseItem> expensesTemplate,@JsonKey(name: 'is_detailed') bool isDetailed,@JsonKey(name: 'property_type') String? propertyType,@JsonKey(name: 'unit_number') String? unitNumber,@JsonKey(name: 'room_count') String? roomCount,@JsonKey(name: 'area_sqm') double? areaSqm,@JsonKey(name: 'floor') String? floor,@JsonKey(name: 'total_floors') int? totalFloors,@JsonKey(name: 'furnishing') String? furnishing,@JsonKey(name: 'heating_type') String? heatingType,@JsonKey(name: 'amenities') List<String> amenities,@JsonKey(name: 'description') String? description,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$PropertyCopyWithImpl<$Res>
    implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._self, this._then);

  final Property _self;
  final $Res Function(Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? address = null,Object? name = null,Object? city = freezed,Object? defaultMonthlyRent = null,Object? defaultDepositAmount = freezed,Object? currency = null,Object? defaultDepositCurrency = null,Object? landlordId = freezed,Object? tenantId = freezed,Object? agencyId = freezed,Object? landlordName = freezed,Object? landlordPhone = freezed,Object? landlordEmail = freezed,Object? tenantName = freezed,Object? defaultDueDay = null,Object? taxType = null,Object? expensesTemplate = null,Object? isDetailed = null,Object? propertyType = freezed,Object? unitNumber = freezed,Object? roomCount = freezed,Object? areaSqm = freezed,Object? floor = freezed,Object? totalFloors = freezed,Object? furnishing = freezed,Object? heatingType = freezed,Object? amenities = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,defaultMonthlyRent: null == defaultMonthlyRent ? _self.defaultMonthlyRent : defaultMonthlyRent // ignore: cast_nullable_to_non_nullable
as double,defaultDepositAmount: freezed == defaultDepositAmount ? _self.defaultDepositAmount : defaultDepositAmount // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,defaultDepositCurrency: null == defaultDepositCurrency ? _self.defaultDepositCurrency : defaultDepositCurrency // ignore: cast_nullable_to_non_nullable
as String,landlordId: freezed == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,agencyId: freezed == agencyId ? _self.agencyId : agencyId // ignore: cast_nullable_to_non_nullable
as String?,landlordName: freezed == landlordName ? _self.landlordName : landlordName // ignore: cast_nullable_to_non_nullable
as String?,landlordPhone: freezed == landlordPhone ? _self.landlordPhone : landlordPhone // ignore: cast_nullable_to_non_nullable
as String?,landlordEmail: freezed == landlordEmail ? _self.landlordEmail : landlordEmail // ignore: cast_nullable_to_non_nullable
as String?,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,defaultDueDay: null == defaultDueDay ? _self.defaultDueDay : defaultDueDay // ignore: cast_nullable_to_non_nullable
as int,taxType: null == taxType ? _self.taxType : taxType // ignore: cast_nullable_to_non_nullable
as TaxType,expensesTemplate: null == expensesTemplate ? _self.expensesTemplate : expensesTemplate // ignore: cast_nullable_to_non_nullable
as List<ExpenseItem>,isDetailed: null == isDetailed ? _self.isDetailed : isDetailed // ignore: cast_nullable_to_non_nullable
as bool,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: freezed == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String?,roomCount: freezed == roomCount ? _self.roomCount : roomCount // ignore: cast_nullable_to_non_nullable
as String?,areaSqm: freezed == areaSqm ? _self.areaSqm : areaSqm // ignore: cast_nullable_to_non_nullable
as double?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,totalFloors: freezed == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int?,furnishing: freezed == furnishing ? _self.furnishing : furnishing // ignore: cast_nullable_to_non_nullable
as String?,heatingType: freezed == heatingType ? _self.heatingType : heatingType // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Property].
extension PropertyPatterns on Property {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Property value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Property value)  $default,){
final _that = this;
switch (_that) {
case _Property():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Property value)?  $default,){
final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String address,  String name, @JsonKey(name: 'city')  String? city, @JsonKey(name: 'default_monthly_rent')  double defaultMonthlyRent, @JsonKey(name: 'default_deposit_amount')  double? defaultDepositAmount,  String currency, @JsonKey(name: 'default_deposit_currency')  String defaultDepositCurrency, @JsonKey(name: 'landlord_id')  String? landlordId, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'agency_id')  String? agencyId, @JsonKey(name: 'landlord_name')  String? landlordName, @JsonKey(name: 'landlord_phone')  String? landlordPhone, @JsonKey(name: 'landlord_email')  String? landlordEmail, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'default_due_day')  int defaultDueDay, @JsonKey(name: 'tax_type')  TaxType taxType, @JsonKey(name: 'expenses_template')  List<ExpenseItem> expensesTemplate, @JsonKey(name: 'is_detailed')  bool isDetailed, @JsonKey(name: 'property_type')  String? propertyType, @JsonKey(name: 'unit_number')  String? unitNumber, @JsonKey(name: 'room_count')  String? roomCount, @JsonKey(name: 'area_sqm')  double? areaSqm, @JsonKey(name: 'floor')  String? floor, @JsonKey(name: 'total_floors')  int? totalFloors, @JsonKey(name: 'furnishing')  String? furnishing, @JsonKey(name: 'heating_type')  String? heatingType, @JsonKey(name: 'amenities')  List<String> amenities, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.address,_that.name,_that.city,_that.defaultMonthlyRent,_that.defaultDepositAmount,_that.currency,_that.defaultDepositCurrency,_that.landlordId,_that.tenantId,_that.agencyId,_that.landlordName,_that.landlordPhone,_that.landlordEmail,_that.tenantName,_that.defaultDueDay,_that.taxType,_that.expensesTemplate,_that.isDetailed,_that.propertyType,_that.unitNumber,_that.roomCount,_that.areaSqm,_that.floor,_that.totalFloors,_that.furnishing,_that.heatingType,_that.amenities,_that.description,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String address,  String name, @JsonKey(name: 'city')  String? city, @JsonKey(name: 'default_monthly_rent')  double defaultMonthlyRent, @JsonKey(name: 'default_deposit_amount')  double? defaultDepositAmount,  String currency, @JsonKey(name: 'default_deposit_currency')  String defaultDepositCurrency, @JsonKey(name: 'landlord_id')  String? landlordId, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'agency_id')  String? agencyId, @JsonKey(name: 'landlord_name')  String? landlordName, @JsonKey(name: 'landlord_phone')  String? landlordPhone, @JsonKey(name: 'landlord_email')  String? landlordEmail, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'default_due_day')  int defaultDueDay, @JsonKey(name: 'tax_type')  TaxType taxType, @JsonKey(name: 'expenses_template')  List<ExpenseItem> expensesTemplate, @JsonKey(name: 'is_detailed')  bool isDetailed, @JsonKey(name: 'property_type')  String? propertyType, @JsonKey(name: 'unit_number')  String? unitNumber, @JsonKey(name: 'room_count')  String? roomCount, @JsonKey(name: 'area_sqm')  double? areaSqm, @JsonKey(name: 'floor')  String? floor, @JsonKey(name: 'total_floors')  int? totalFloors, @JsonKey(name: 'furnishing')  String? furnishing, @JsonKey(name: 'heating_type')  String? heatingType, @JsonKey(name: 'amenities')  List<String> amenities, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Property():
return $default(_that.id,_that.address,_that.name,_that.city,_that.defaultMonthlyRent,_that.defaultDepositAmount,_that.currency,_that.defaultDepositCurrency,_that.landlordId,_that.tenantId,_that.agencyId,_that.landlordName,_that.landlordPhone,_that.landlordEmail,_that.tenantName,_that.defaultDueDay,_that.taxType,_that.expensesTemplate,_that.isDetailed,_that.propertyType,_that.unitNumber,_that.roomCount,_that.areaSqm,_that.floor,_that.totalFloors,_that.furnishing,_that.heatingType,_that.amenities,_that.description,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String address,  String name, @JsonKey(name: 'city')  String? city, @JsonKey(name: 'default_monthly_rent')  double defaultMonthlyRent, @JsonKey(name: 'default_deposit_amount')  double? defaultDepositAmount,  String currency, @JsonKey(name: 'default_deposit_currency')  String defaultDepositCurrency, @JsonKey(name: 'landlord_id')  String? landlordId, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'agency_id')  String? agencyId, @JsonKey(name: 'landlord_name')  String? landlordName, @JsonKey(name: 'landlord_phone')  String? landlordPhone, @JsonKey(name: 'landlord_email')  String? landlordEmail, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'default_due_day')  int defaultDueDay, @JsonKey(name: 'tax_type')  TaxType taxType, @JsonKey(name: 'expenses_template')  List<ExpenseItem> expensesTemplate, @JsonKey(name: 'is_detailed')  bool isDetailed, @JsonKey(name: 'property_type')  String? propertyType, @JsonKey(name: 'unit_number')  String? unitNumber, @JsonKey(name: 'room_count')  String? roomCount, @JsonKey(name: 'area_sqm')  double? areaSqm, @JsonKey(name: 'floor')  String? floor, @JsonKey(name: 'total_floors')  int? totalFloors, @JsonKey(name: 'furnishing')  String? furnishing, @JsonKey(name: 'heating_type')  String? heatingType, @JsonKey(name: 'amenities')  List<String> amenities, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.address,_that.name,_that.city,_that.defaultMonthlyRent,_that.defaultDepositAmount,_that.currency,_that.defaultDepositCurrency,_that.landlordId,_that.tenantId,_that.agencyId,_that.landlordName,_that.landlordPhone,_that.landlordEmail,_that.tenantName,_that.defaultDueDay,_that.taxType,_that.expensesTemplate,_that.isDetailed,_that.propertyType,_that.unitNumber,_that.roomCount,_that.areaSqm,_that.floor,_that.totalFloors,_that.furnishing,_that.heatingType,_that.amenities,_that.description,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Property implements Property {
  const _Property({required this.id, required this.address, required this.name, @JsonKey(name: 'city') this.city, @JsonKey(name: 'default_monthly_rent') required this.defaultMonthlyRent, @JsonKey(name: 'default_deposit_amount') this.defaultDepositAmount, this.currency = 'EUR', @JsonKey(name: 'default_deposit_currency') this.defaultDepositCurrency = 'EUR', @JsonKey(name: 'landlord_id') this.landlordId, @JsonKey(name: 'tenant_id') this.tenantId, @JsonKey(name: 'agency_id') this.agencyId, @JsonKey(name: 'landlord_name') this.landlordName, @JsonKey(name: 'landlord_phone') this.landlordPhone, @JsonKey(name: 'landlord_email') this.landlordEmail, @JsonKey(name: 'tenant_name') this.tenantName, @JsonKey(name: 'default_due_day') this.defaultDueDay = 1, @JsonKey(name: 'tax_type') this.taxType = TaxType.included, @JsonKey(name: 'expenses_template') final  List<ExpenseItem> expensesTemplate = const [], @JsonKey(name: 'is_detailed') this.isDetailed = false, @JsonKey(name: 'property_type') this.propertyType, @JsonKey(name: 'unit_number') this.unitNumber, @JsonKey(name: 'room_count') this.roomCount, @JsonKey(name: 'area_sqm') this.areaSqm, @JsonKey(name: 'floor') this.floor, @JsonKey(name: 'total_floors') this.totalFloors, @JsonKey(name: 'furnishing') this.furnishing, @JsonKey(name: 'heating_type') this.heatingType, @JsonKey(name: 'amenities') final  List<String> amenities = const [], @JsonKey(name: 'description') this.description, @JsonKey(name: 'created_at') this.createdAt}): _expensesTemplate = expensesTemplate,_amenities = amenities;
  factory _Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);

@override final  String id;
@override final  String address;
@override final  String name;
@override@JsonKey(name: 'city') final  String? city;
@override@JsonKey(name: 'default_monthly_rent') final  double defaultMonthlyRent;
@override@JsonKey(name: 'default_deposit_amount') final  double? defaultDepositAmount;
@override@JsonKey() final  String currency;
@override@JsonKey(name: 'default_deposit_currency') final  String defaultDepositCurrency;
@override@JsonKey(name: 'landlord_id') final  String? landlordId;
@override@JsonKey(name: 'tenant_id') final  String? tenantId;
/// Agency managing this property (B2B2C: agency_id in profiles)
@override@JsonKey(name: 'agency_id') final  String? agencyId;
@override@JsonKey(name: 'landlord_name') final  String? landlordName;
@override@JsonKey(name: 'landlord_phone') final  String? landlordPhone;
@override@JsonKey(name: 'landlord_email') final  String? landlordEmail;
@override@JsonKey(name: 'tenant_name') final  String? tenantName;
@override@JsonKey(name: 'default_due_day') final  int defaultDueDay;
@override@JsonKey(name: 'tax_type') final  TaxType taxType;
 final  List<ExpenseItem> _expensesTemplate;
@override@JsonKey(name: 'expenses_template') List<ExpenseItem> get expensesTemplate {
  if (_expensesTemplate is EqualUnmodifiableListView) return _expensesTemplate;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expensesTemplate);
}

// Detailed Property Fields
@override@JsonKey(name: 'is_detailed') final  bool isDetailed;
@override@JsonKey(name: 'property_type') final  String? propertyType;
@override@JsonKey(name: 'unit_number') final  String? unitNumber;
@override@JsonKey(name: 'room_count') final  String? roomCount;
@override@JsonKey(name: 'area_sqm') final  double? areaSqm;
@override@JsonKey(name: 'floor') final  String? floor;
@override@JsonKey(name: 'total_floors') final  int? totalFloors;
@override@JsonKey(name: 'furnishing') final  String? furnishing;
@override@JsonKey(name: 'heating_type') final  String? heatingType;
 final  List<String> _amenities;
@override@JsonKey(name: 'amenities') List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override@JsonKey(name: 'description') final  String? description;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyCopyWith<_Property> get copyWith => __$PropertyCopyWithImpl<_Property>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Property&&(identical(other.id, id) || other.id == id)&&(identical(other.address, address) || other.address == address)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.defaultMonthlyRent, defaultMonthlyRent) || other.defaultMonthlyRent == defaultMonthlyRent)&&(identical(other.defaultDepositAmount, defaultDepositAmount) || other.defaultDepositAmount == defaultDepositAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.defaultDepositCurrency, defaultDepositCurrency) || other.defaultDepositCurrency == defaultDepositCurrency)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.agencyId, agencyId) || other.agencyId == agencyId)&&(identical(other.landlordName, landlordName) || other.landlordName == landlordName)&&(identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone)&&(identical(other.landlordEmail, landlordEmail) || other.landlordEmail == landlordEmail)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.defaultDueDay, defaultDueDay) || other.defaultDueDay == defaultDueDay)&&(identical(other.taxType, taxType) || other.taxType == taxType)&&const DeepCollectionEquality().equals(other._expensesTemplate, _expensesTemplate)&&(identical(other.isDetailed, isDetailed) || other.isDetailed == isDetailed)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.roomCount, roomCount) || other.roomCount == roomCount)&&(identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.furnishing, furnishing) || other.furnishing == furnishing)&&(identical(other.heatingType, heatingType) || other.heatingType == heatingType)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,address,name,city,defaultMonthlyRent,defaultDepositAmount,currency,defaultDepositCurrency,landlordId,tenantId,agencyId,landlordName,landlordPhone,landlordEmail,tenantName,defaultDueDay,taxType,const DeepCollectionEquality().hash(_expensesTemplate),isDetailed,propertyType,unitNumber,roomCount,areaSqm,floor,totalFloors,furnishing,heatingType,const DeepCollectionEquality().hash(_amenities),description,createdAt]);

@override
String toString() {
  return 'Property(id: $id, address: $address, name: $name, city: $city, defaultMonthlyRent: $defaultMonthlyRent, defaultDepositAmount: $defaultDepositAmount, currency: $currency, defaultDepositCurrency: $defaultDepositCurrency, landlordId: $landlordId, tenantId: $tenantId, agencyId: $agencyId, landlordName: $landlordName, landlordPhone: $landlordPhone, landlordEmail: $landlordEmail, tenantName: $tenantName, defaultDueDay: $defaultDueDay, taxType: $taxType, expensesTemplate: $expensesTemplate, isDetailed: $isDetailed, propertyType: $propertyType, unitNumber: $unitNumber, roomCount: $roomCount, areaSqm: $areaSqm, floor: $floor, totalFloors: $totalFloors, furnishing: $furnishing, heatingType: $heatingType, amenities: $amenities, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PropertyCopyWith<$Res> implements $PropertyCopyWith<$Res> {
  factory _$PropertyCopyWith(_Property value, $Res Function(_Property) _then) = __$PropertyCopyWithImpl;
@override @useResult
$Res call({
 String id, String address, String name,@JsonKey(name: 'city') String? city,@JsonKey(name: 'default_monthly_rent') double defaultMonthlyRent,@JsonKey(name: 'default_deposit_amount') double? defaultDepositAmount, String currency,@JsonKey(name: 'default_deposit_currency') String defaultDepositCurrency,@JsonKey(name: 'landlord_id') String? landlordId,@JsonKey(name: 'tenant_id') String? tenantId,@JsonKey(name: 'agency_id') String? agencyId,@JsonKey(name: 'landlord_name') String? landlordName,@JsonKey(name: 'landlord_phone') String? landlordPhone,@JsonKey(name: 'landlord_email') String? landlordEmail,@JsonKey(name: 'tenant_name') String? tenantName,@JsonKey(name: 'default_due_day') int defaultDueDay,@JsonKey(name: 'tax_type') TaxType taxType,@JsonKey(name: 'expenses_template') List<ExpenseItem> expensesTemplate,@JsonKey(name: 'is_detailed') bool isDetailed,@JsonKey(name: 'property_type') String? propertyType,@JsonKey(name: 'unit_number') String? unitNumber,@JsonKey(name: 'room_count') String? roomCount,@JsonKey(name: 'area_sqm') double? areaSqm,@JsonKey(name: 'floor') String? floor,@JsonKey(name: 'total_floors') int? totalFloors,@JsonKey(name: 'furnishing') String? furnishing,@JsonKey(name: 'heating_type') String? heatingType,@JsonKey(name: 'amenities') List<String> amenities,@JsonKey(name: 'description') String? description,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$PropertyCopyWithImpl<$Res>
    implements _$PropertyCopyWith<$Res> {
  __$PropertyCopyWithImpl(this._self, this._then);

  final _Property _self;
  final $Res Function(_Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? address = null,Object? name = null,Object? city = freezed,Object? defaultMonthlyRent = null,Object? defaultDepositAmount = freezed,Object? currency = null,Object? defaultDepositCurrency = null,Object? landlordId = freezed,Object? tenantId = freezed,Object? agencyId = freezed,Object? landlordName = freezed,Object? landlordPhone = freezed,Object? landlordEmail = freezed,Object? tenantName = freezed,Object? defaultDueDay = null,Object? taxType = null,Object? expensesTemplate = null,Object? isDetailed = null,Object? propertyType = freezed,Object? unitNumber = freezed,Object? roomCount = freezed,Object? areaSqm = freezed,Object? floor = freezed,Object? totalFloors = freezed,Object? furnishing = freezed,Object? heatingType = freezed,Object? amenities = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_Property(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,defaultMonthlyRent: null == defaultMonthlyRent ? _self.defaultMonthlyRent : defaultMonthlyRent // ignore: cast_nullable_to_non_nullable
as double,defaultDepositAmount: freezed == defaultDepositAmount ? _self.defaultDepositAmount : defaultDepositAmount // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,defaultDepositCurrency: null == defaultDepositCurrency ? _self.defaultDepositCurrency : defaultDepositCurrency // ignore: cast_nullable_to_non_nullable
as String,landlordId: freezed == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,agencyId: freezed == agencyId ? _self.agencyId : agencyId // ignore: cast_nullable_to_non_nullable
as String?,landlordName: freezed == landlordName ? _self.landlordName : landlordName // ignore: cast_nullable_to_non_nullable
as String?,landlordPhone: freezed == landlordPhone ? _self.landlordPhone : landlordPhone // ignore: cast_nullable_to_non_nullable
as String?,landlordEmail: freezed == landlordEmail ? _self.landlordEmail : landlordEmail // ignore: cast_nullable_to_non_nullable
as String?,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,defaultDueDay: null == defaultDueDay ? _self.defaultDueDay : defaultDueDay // ignore: cast_nullable_to_non_nullable
as int,taxType: null == taxType ? _self.taxType : taxType // ignore: cast_nullable_to_non_nullable
as TaxType,expensesTemplate: null == expensesTemplate ? _self._expensesTemplate : expensesTemplate // ignore: cast_nullable_to_non_nullable
as List<ExpenseItem>,isDetailed: null == isDetailed ? _self.isDetailed : isDetailed // ignore: cast_nullable_to_non_nullable
as bool,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: freezed == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String?,roomCount: freezed == roomCount ? _self.roomCount : roomCount // ignore: cast_nullable_to_non_nullable
as String?,areaSqm: freezed == areaSqm ? _self.areaSqm : areaSqm // ignore: cast_nullable_to_non_nullable
as double?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,totalFloors: freezed == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int?,furnishing: freezed == furnishing ? _self.furnishing : furnishing // ignore: cast_nullable_to_non_nullable
as String?,heatingType: freezed == heatingType ? _self.heatingType : heatingType // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
