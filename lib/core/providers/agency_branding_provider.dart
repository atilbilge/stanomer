// lib/core/providers/agency_branding_provider.dart
//
// Provides white-label branding data for tenants connected to agency-managed properties.
// When a tenant's active property has an agency_id, the app dynamically brands itself
// with the agency's company name, logo, and color.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/agency/domain/agency_profile.dart';
import '../../features/agency/data/agency_repository.dart';
import '../../features/property/domain/property.dart';

// ---------------------------------------------------------------------------
// Repository Provider
// ---------------------------------------------------------------------------
final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return AgencyRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Branding State
// ---------------------------------------------------------------------------
class AgencyBrandingState {
  final AgencyProfile? profile;
  final bool isLoading;

  const AgencyBrandingState({
    this.profile,
    this.isLoading = false,
  });

  /// Display name to show in AppBar and splash screens
  String get appTitle => profile?.displayName ?? 'Stanomer';

  /// Primary brand color (falls back to Stanomer default if null)
  Color? get brandColor {
    final hex = profile?.primaryColor;
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  /// Logo URL for the agency (null → show default Stanomer logo)
  String? get logoUrl => profile?.logoUrl;

  bool get hasAgencyBranding => profile != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class AgencyBrandingNotifier extends StateNotifier<AgencyBrandingState> {
  final AgencyRepository _repository;

  AgencyBrandingNotifier(this._repository) : super(const AgencyBrandingState());

  /// Updates branding based on current user role and list of properties.
  /// - Tenant: Branded if the selected active property (or its active contract) is managed by an agency.
  /// - Landlord: Branded if ALL active properties are managed by an agency.
  Future<void> updateBrandingForSession({
    required String role,
    required List<Property> properties,
    int selectedIndex = 0,
    String? contractAgencyId,
  }) async {
    if (role == 'agency') {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && state.profile?.id != userId) {
        await _loadFromAgencyId(userId);
      }
      return;
    }

    if (properties.isEmpty) {
      if (state.profile != null) clear();
      return;
    }

    if (role == 'tenant') {
      final tenantProps = properties.where((p) => p.tenantId != null).toList();
      final activeProp = tenantProps.isNotEmpty
          ? tenantProps[selectedIndex.clamp(0, tenantProps.length - 1)]
          : properties[selectedIndex.clamp(0, properties.length - 1)];

      final agencyId = (activeProp.agencyId != null && activeProp.agencyId!.trim().isNotEmpty)
          ? activeProp.agencyId
          : (contractAgencyId != null && contractAgencyId.trim().isNotEmpty ? contractAgencyId : null);

      if (agencyId != null && agencyId.trim().isNotEmpty) {
        if (state.profile?.id != agencyId) {
          await _loadFromAgencyId(agencyId);
        }
      } else {
        if (state.profile != null) clear();
      }
    } else if (role == 'landlord') {
      final allManagedByAgency = properties.every((p) => p.agencyId != null && p.agencyId!.trim().isNotEmpty);
      if (allManagedByAgency && properties.isNotEmpty) {
        final activeProp = properties[selectedIndex.clamp(0, properties.length - 1)];
        final agencyId = activeProp.agencyId ?? properties.first.agencyId;
        if (agencyId != null && state.profile?.id != agencyId) {
          await _loadFromAgencyId(agencyId);
        }
      } else {
        if (state.profile != null) clear();
      }
    } else {
      if (state.profile != null) clear();
    }
  }

  /// Legacy helper method: Load agency branding from property.
  Future<void> loadFromProperty(Property? property) async {
    final agencyId = property?.agencyId;
    if (agencyId == null || agencyId.trim().isEmpty) {
      clear();
      return;
    }
    await _loadFromAgencyId(agencyId);
  }

  Future<void> _loadFromAgencyId(String agencyId) async {
    if (state.profile?.id == agencyId && !state.isLoading) return;
    state = AgencyBrandingState(profile: state.profile, isLoading: true);
    final profile = await _repository.getAgencyProfile(agencyId);
    print('DEBUG [AgencyBranding]: Loaded profile for agencyId=$agencyId -> company=${profile?.companyName}, primary=${profile?.primaryColor}, logo=${profile?.logoUrl}');
    state = AgencyBrandingState(profile: profile, isLoading: false);
  }

  /// Manually clear branding (e.g., on sign-out or role switch)
  void clear() {
    state = const AgencyBrandingState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final agencyBrandingProvider =
    StateNotifierProvider<AgencyBrandingNotifier, AgencyBrandingState>((ref) {
  final repo = ref.watch(agencyRepositoryProvider);
  return AgencyBrandingNotifier(repo);
});

// ---------------------------------------------------------------------------
// Convenience Selector Providers
// ---------------------------------------------------------------------------

/// The app title string to display in AppBar / splash
final appTitleProvider = Provider<String>((ref) {
  return ref.watch(agencyBrandingProvider).appTitle;
});

/// Whether the current session is agency-branded
final hasAgencyBrandingProvider = Provider<bool>((ref) {
  return ref.watch(agencyBrandingProvider).hasAgencyBranding;
});
