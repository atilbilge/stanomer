import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/providers/agency_branding_provider.dart';

/// Global Riverpod provider for AgencyColorScheme.
/// Consumed by Agency screens, branded Tenant screens, and branded Landlord screens.
final agencyColorSchemeProvider = Provider<AgencyColorScheme>((ref) {
  final userRole = ref.watch(userRoleProvider);

  if (userRole == 'agency') {
    final profileAsync = ref.watch(profileFutureProvider);
    final profileData = profileAsync.value;
    final rawColorScheme = profileData?['color_scheme'];
    final scheme = AgencyColorScheme.fromJson(rawColorScheme);
    if (scheme.primary == StanomerColors.brandPrimary) {
      return const AgencyColorScheme.agencyScheme();
    }
    return scheme;
  }

  // Tenant or Landlord session: check agency branding provider
  final brandingState = ref.watch(agencyBrandingProvider);
  if (brandingState.hasAgencyBranding && brandingState.profile != null) {
    return brandingState.profile!.colorScheme;
  }

  // agencyBrandingProvider == false (or no agency branding)
  if (userRole == 'landlord') {
    return const AgencyColorScheme.landlordScheme();
  } else if (userRole == 'tenant') {
    return const AgencyColorScheme.tenantScheme();
  }

  return const AgencyColorScheme.defaultScheme();
});

/// Custom theme colors for agency white-labeling and role-based themes.
class AgencyColorScheme {
  final Color primary;
  final Color accent;
  final Color brandGold;
  final Color bgWhite;
  final Color textPrimary;
  final Color border;

  const AgencyColorScheme({
    required this.primary,
    required this.accent,
    required this.brandGold,
    required this.bgWhite,
    required this.textPrimary,
    required this.border,
  });

  const AgencyColorScheme.landlordScheme()
      : primary = const Color(0xFF1A5EB8),
        accent = const Color(0xFFE6EEF9),
        brandGold = const Color(0xFFD4AF37),
        bgWhite = const Color(0xFFFFFFFF),
        textPrimary = const Color(0xFF1A1A1A),
        border = const Color(0xFFD9E4F5);

  const AgencyColorScheme.tenantScheme()
      : primary = const Color(0xFF2DB87A),
        accent = const Color(0xFFE6F7F0),
        brandGold = const Color(0xFFD4AF37),
        bgWhite = const Color(0xFFFFFFFF),
        textPrimary = const Color(0xFF1A1A1A),
        border = const Color(0xFFD0F0E3);

  const AgencyColorScheme.agencyScheme()
      : primary = const Color(0xFF4A3AFF),
        accent = const Color(0xFFF0EEFF),
        brandGold = const Color(0xFFE5C158),
        bgWhite = const Color(0xFFFFFFFF),
        textPrimary = const Color(0xFF1A1A1A),
        border = const Color(0xFFE0DAFF);

  const AgencyColorScheme.defaultScheme()
      : primary = const Color(0xFF1A5EB8),
        accent = const Color(0xFFE6EEF9),
        brandGold = const Color(0xFFD4AF37),
        bgWhite = const Color(0xFFFFFFFF),
        textPrimary = const Color(0xFF1A1A1A),
        border = const Color(0xFFD9E4F5);

  /// Factory constructor to parse JSON data from `profiles.color_scheme`.
  /// Supports `primary`, `color-primary`, `--color-primary`, etc.
  factory AgencyColorScheme.fromJson(dynamic rawJson) {
    Map<String, dynamic>? json;
    if (rawJson is Map<String, dynamic>) {
      json = rawJson;
    } else if (rawJson is Map) {
      json = Map<String, dynamic>.from(rawJson);
    } else if (rawJson is String && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map) {
          json = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    if (json == null || json.isEmpty) {
      return const AgencyColorScheme(
        primary: StanomerColors.brandPrimary,
        accent: Color(0xFFDC7A3B),
        brandGold: Color(0xFFC6A665),
        bgWhite: StanomerColors.bgCard,
        textPrimary: StanomerColors.textPrimary,
        border: StanomerColors.borderDefault,
      );
    }

    final primaryHex = _getValue(json, ['primary', 'color-primary', '--color-primary']);
    final accentHex = _getValue(json, ['accent', 'color-accent', '--color-accent']);
    final brandGoldHex = _getValue(json, ['brand_gold', 'brand-gold', 'color-brand-gold', '--color-brand-gold']);
    final bgWhiteHex = _getValue(json, ['bg_white', 'bg-white', 'color-bg-white', '--color-bg-white']);
    final textPrimaryHex = _getValue(json, ['text_primary', 'text-primary', 'color-text-primary', '--color-text-primary']);
    final borderHex = _getValue(json, ['border', 'color-border', '--color-border']);

    return AgencyColorScheme(
      primary: _parseColorHex(primaryHex) ?? StanomerColors.brandPrimary,
      accent: _parseColorHex(accentHex) ?? const Color(0xFFDC7A3B),
      brandGold: _parseColorHex(brandGoldHex) ?? const Color(0xFFC6A665),
      bgWhite: _parseColorHex(bgWhiteHex) ?? StanomerColors.bgCard,
      textPrimary: _parseColorHex(textPrimaryHex) ?? StanomerColors.textPrimary,
      border: _parseColorHex(borderHex) ?? StanomerColors.borderDefault,
    );
  }

  static String? _getValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null && json[key].toString().trim().isNotEmpty) {
        return json[key].toString().trim();
      }
    }
    return null;
  }

  static Color? _parseColorHex(String? hexString) {
    if (hexString == null || hexString.trim().isEmpty) return null;
    String hex = hexString.trim().replaceAll('#', '').replaceAll('0x', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
