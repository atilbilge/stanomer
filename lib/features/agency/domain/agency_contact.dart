enum AgencyContactRole {
  landlord,
  tenant,
}

class AgencyContact {
  final String name;
  final String? email;
  final String? phone;
  final String? idNumber;
  final AgencyContactRole role;
  final String? propertySummary;
  final String? propertyId;
  final bool isCompany;
  final String? companyName;
  final String? pib;
  final String? representativeName;

  const AgencyContact({
    required this.name,
    this.email,
    this.phone,
    this.idNumber,
    required this.role,
    this.propertySummary,
    this.propertyId,
    this.isCompany = false,
    this.companyName,
    this.pib,
    this.representativeName,
  });

  bool get isLandlord => role == AgencyContactRole.landlord;
  bool get isTenant => role == AgencyContactRole.tenant;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgencyContact &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role;

  @override
  int get hashCode => Object.hash(name, email, phone, role);
}
