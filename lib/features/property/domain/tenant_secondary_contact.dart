class TenantSecondaryContact {
  final String fullName;
  final String relationship;
  final String? phone;
  final String? email;

  const TenantSecondaryContact({
    required this.fullName,
    required this.relationship,
    this.phone,
    this.email,
  });

  factory TenantSecondaryContact.fromJson(Map<String, dynamic> json) {
    return TenantSecondaryContact(
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'relationship': relationship.trim(),
      'phone': phone?.trim(),
      'email': (email != null && email!.trim().isNotEmpty) ? email!.trim().toLowerCase() : null,
    };
  }

  TenantSecondaryContact copyWith({
    String? fullName,
    String? relationship,
    String? phone,
    String? email,
  }) {
    return TenantSecondaryContact(
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
