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
    final rawColorScheme = profileData?['color_scheme'] as Map<String, dynamic>?;
    return AgencyColorScheme.fromJson(rawColorScheme);
  }

  // Tenant or Landlord session: check agency branding provider
  final brandingState = ref.watch(agencyBrandingProvider);
  if (brandingState.hasAgencyBranding && brandingState.profile != null) {
    return brandingState.profile!.colorScheme;
  }

  return const AgencyColorScheme.defaultScheme();
});

/// Custom theme colors for agency white-labeling.
/// If any color is null or empty, Stanomer default theme colors are used.
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

  const AgencyColorScheme.defaultScheme()
      : primary = StanomerColors.brandPrimary,
        accent = const Color(0xFFDC7A3B),
        brandGold = const Color(0xFFC6A665),
        bgWhite = StanomerColors.bgCard,
        textPrimary = StanomerColors.textPrimary,
        border = StanomerColors.borderDefault;

  /// Factory constructor to parse JSON data from `profiles.color_scheme`.
  /// Supports `primary`, `color-primary`, `--color-primary`, etc.
  factory AgencyColorScheme.fromJson(Map<String, dynamic>? json) {
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
