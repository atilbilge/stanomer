import 'agency_color_scheme.dart';

class AgencyProfile {
  final String id;
  final String? companyName;
  final String? primaryColor;
  final String? logoUrl;
  final String? email;
  final AgencyColorScheme colorScheme;

  const AgencyProfile({
    required this.id,
    this.companyName,
    this.primaryColor,
    this.logoUrl,
    this.email,
    required this.colorScheme,
  });

  factory AgencyProfile.fromJson(Map<String, dynamic> json) {
    final rawScheme = json['color_scheme'] as Map<String, dynamic>?;
    final primaryFromProfile = json['primary_color'] as String? ?? rawScheme?['primary'] as String?;
    final mergedSchemeMap = {
      if (primaryFromProfile != null) 'primary': primaryFromProfile,
      ...?rawScheme,
    };

    return AgencyProfile(
      id: json['id'] as String,
      companyName: (json['company_name'] as String?)?.isNotEmpty == true
          ? json['company_name'] as String
          : json['full_name'] as String?,
      primaryColor: primaryFromProfile,
      logoUrl: json['logo_url'] as String?,
      email: json['email'] as String?,
      colorScheme: AgencyColorScheme.fromJson(mergedSchemeMap),
    );
  }

  /// Display name shown in branded UI (falls back to email domain or 'Stanomer')
  String get displayName {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!;
    }
    if (email != null && email!.contains('@')) {
      final name = email!.split('@').first;
      if (name.isNotEmpty) return name.toUpperCase();
    }
    return 'Stanomer';
  }
}
