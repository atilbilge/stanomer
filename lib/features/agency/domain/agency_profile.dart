import 'dart:convert';
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
    final rawScheme = json['color_scheme'];
    Map<String, dynamic>? rawSchemeMap;
    if (rawScheme is Map<String, dynamic>) {
      rawSchemeMap = rawScheme;
    } else if (rawScheme is Map) {
      rawSchemeMap = Map<String, dynamic>.from(rawScheme);
    } else if (rawScheme is String && rawScheme.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawScheme);
        if (decoded is Map) rawSchemeMap = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final primaryFromProfile = json['primary_color'] as String? ?? rawSchemeMap?['primary'] as String?;
    final mergedSchemeMap = {
      if (primaryFromProfile != null) 'primary': primaryFromProfile,
      ...?rawSchemeMap,
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
