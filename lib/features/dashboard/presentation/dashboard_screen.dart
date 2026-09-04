import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/widgets/role_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../../property/data/property_repository.dart';
import '../../property/domain/property.dart';
import '../../property/domain/contract.dart';
import '../../property/domain/rent_payment.dart';
import '../../property/domain/landlord_stats.dart';
import '../../../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/expandable_agency_logo.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/desktop_navigation_shell.dart';
import '../../../core/utils/expense_utils.dart';
import '../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../core/providers/agency_branding_provider.dart';
import '../../agency/domain/agency_color_scheme.dart';

import '../../agency/presentation/agency_dashboard_screen.dart';
import '../../property/presentation/join_property_sheet.dart';
import '../../notifications/presentation/widgets/notification_badge.dart';
import 'widgets/profile_pill.dart';
import 'widgets/role_switcher_sheet.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/connection_status_indicator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _roleSelectionLoading = false;
  bool _isCheckingInitialRole = false;
  bool _needsRoleSelection = false;
  bool _hasBothInvites = false;
  int _selectedTenantPropertyIndex = 0;
  int _landlordCurrentTab = 0; // 0: Ana Panel, 1: Mülklerim, 2: Finans, 3: Bakım
  String _landlordPropertyFilter = 'all'; // 'all', 'rented', 'vacant'

  @override
  void initState() {
    super.initState();
    final initialUser = ref.read(currentUserProvider);
    if (initialUser != null &&
        initialUser.userMetadata?['initial_role_set'] != true &&
        initialUser.userMetadata?['role'] == null) {
      _isCheckingInitialRole = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted && _isCheckingInitialRole) setState(() => _isCheckingInitialRole = false);
        return;
      }

      try {
        final profile = await ref.read(profileFutureProvider.future);
        final dbRole = profile?['role'] as String?;
        final metaRole = user.userMetadata?['role'] as String?;
        final fullName = profile?['full_name'] ?? user.userMetadata?['full_name'] as String?;
        final initialRoleSet = user.userMetadata?['initial_role_set'] == true;

        if (dbRole == 'agency' || metaRole == 'agency') {
          if (mounted) context.go('/agency-dashboard');
          return;
        }

        // If user already confirmed an initial role or has explicit role in metadata, no check needed
        if (initialRoleSet || metaRole != null) {
          if (mounted && _isCheckingInitialRole) setState(() => _isCheckingInitialRole = false);
          return;
        }

        final supabase = Supabase.instance.client;

        // Check if existing user has active landlord properties
        final existingLandlordProps = await supabase
            .from('properties')
            .select('id')
            .eq('landlord_id', user.id)
            .limit(1);
        if (existingLandlordProps.isNotEmpty) {
          await ref.read(authRepositoryProvider).updateProfile(role: 'landlord', fullName: fullName);
          if (mounted) setState(() => _isCheckingInitialRole = false);
          return;
        }

        // Check if existing user has active tenant contracts/properties
        final existingTenantContracts = await supabase
            .from('contracts')
            .select('id')
            .eq('tenant_id', user.id)
            .limit(1);
        final existingTenantProps = await supabase
            .from('properties')
            .select('id')
            .eq('tenant_id', user.id)
            .limit(1);
        if (existingTenantContracts.isNotEmpty || existingTenantProps.isNotEmpty) {
          await ref.read(authRepositoryProvider).updateProfile(role: 'tenant', fullName: fullName);
          if (mounted) setState(() => _isCheckingInitialRole = false);
          return;
        }

        // New user logging in for the first time: Check invitations by email
        final userEmail = user.email?.trim().toLowerCase();
        if (userEmail != null && userEmail.isNotEmpty) {
          final allPendingInvites = await supabase
              .from('invitations')
              .select('id, target_role, token')
              .eq('invitee_email', userEmail)
              .eq('status', 'pending');

          final landlordProperties = await supabase
              .from('properties')
              .select('id')
              .eq('landlord_email', userEmail);

          final tenantContracts = await supabase
              .from('contracts')
              .select('id')
              .eq('invitee_email', userEmail)
              .inFilter('status', ['pending', 'negotiating', 'revision_requested']);

          final hasLandlordInvite = landlordProperties.isNotEmpty ||
              allPendingInvites.any((inv) {
                final targetRole = inv['target_role'] as String?;
                final token = inv['token'] as String? ?? '';
                return targetRole == 'landlord' || token.startsWith('landlord_');
              });

          final hasTenantInvite = tenantContracts.isNotEmpty ||
              allPendingInvites.any((inv) {
                final targetRole = inv['target_role'] as String?;
                final token = inv['token'] as String? ?? '';
                return targetRole != 'landlord' && !token.startsWith('landlord_');
              });

          if (hasTenantInvite && !hasLandlordInvite) {
            // User was invited ONLY as a tenant -> default role is tenant
            await ref.read(authRepositoryProvider).updateProfile(role: 'tenant', fullName: fullName);
            ref.invalidate(userRoleProvider);
            ref.invalidate(profileFutureProvider);
            ref.invalidate(pendingInvitesForUserProvider);
            if (mounted) {
              setState(() {
                _isCheckingInitialRole = false;
                _needsRoleSelection = false;
                _hasBothInvites = false;
              });
            }
          } else if (hasLandlordInvite && !hasTenantInvite) {
            // User was invited ONLY as a landlord -> default role is landlord
            await ref.read(authRepositoryProvider).updateProfile(role: 'landlord', fullName: fullName);
            ref.invalidate(userRoleProvider);
            ref.invalidate(profileFutureProvider);
            ref.invalidate(pendingInvitesForUserProvider);
            if (mounted) {
              setState(() {
                _isCheckingInitialRole = false;
                _needsRoleSelection = false;
                _hasBothInvites = false;
              });
            }
          } else {
            // Both invitations exist OR neither exists -> User selects role
            if (mounted) {
              setState(() {
                _isCheckingInitialRole = false;
                _needsRoleSelection = true;
                _hasBothInvites = hasTenantInvite && hasLandlordInvite;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isCheckingInitialRole = false;
              _needsRoleSelection = true;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingInitialRole = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider) ?? user?.userMetadata?['role'] as String?;
    if (role == 'agency') {
      return const AgencyDashboardScreen();
    }
    final zzplDocumentVersion = user?.userMetadata?['zzpl_document_version'] as String?;
    final isLandlord = role == 'landlord';

    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitesForUserProvider);

    final isTenant = role == 'tenant';

    // --- Agency White-Label Branding ---
    // - Tenant: branded if active selected property (or active contract) has agency_id
    // - Landlord: branded if ALL properties are managed by an agency
    if (propertiesAsync.hasValue) {
      final properties = propertiesAsync.value!;
      Contract? activeTenantContract;
      if (isTenant && properties.isNotEmpty) {
        final tenantProperties = properties.where((p) => p.tenantId != null).toList();
        if (tenantProperties.isNotEmpty) {
          final activeProp = tenantProperties[_selectedTenantPropertyIndex.clamp(0, tenantProperties.length - 1)];
          activeTenantContract = ref.watch(activeContractProvider(activeProp.id)).value;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(agencyBrandingProvider.notifier).updateBrandingForSession(
              role: role ?? '',
              properties: properties,
              selectedIndex: _selectedTenantPropertyIndex,
              contractAgencyId: activeTenantContract?.agencyId,
            );
      });
    }
    final brandingState = ref.watch(agencyBrandingProvider);
    final agencyColors = ref.watch(agencyColorSchemeProvider);
    final appBarTitle = brandingState.appTitle;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return DesktopNavigationShell(
      currentTabIndex: isLandlord ? _landlordCurrentTab : 0,
      onTabChanged: isLandlord
          ? (index) => setState(() => _landlordCurrentTab = index)
          : null,
      onRoleSwitcherTap: () => _showRoleSwitcher(context, role),
      child: Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: Row(
          children: [
            // Show agency logo if available, else default Stanomer logo
            if (brandingState.logoUrl != null && brandingState.logoUrl!.trim().isNotEmpty)
              ExpandableAgencyLogo(
                logoUrl: brandingState.logoUrl,
                title: appBarTitle,
                height: 28,
                fallbackWidget: _buildAgencyLogoBadge(brandingState, agencyColors),
              )
            else if (brandingState.hasAgencyBranding)
              ExpandableAgencyLogo(
                logoUrl: null,
                title: appBarTitle,
                height: 28,
                fallbackWidget: _buildAgencyLogoBadge(brandingState, agencyColors),
              )
            else
              const AppLogo(height: 28),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  appBarTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 8),
          ProfilePill(
            role: role,
            email: user?.email,
            onTap: () => _showRoleSwitcher(context, role),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: () {
        if (zzplDocumentVersion == null || _needsRoleSelection || _isCheckingInitialRole) return null;
        if (propertiesAsync.hasValue) {
          final properties = propertiesAsync.value!;
          if (isLandlord) {
            final hasAgencyManagedProperty = properties.any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);
            final isAgencyClient = hasAgencyManagedProperty || brandingState.hasAgencyBranding;
            if (isAgencyClient) return null;

            return FloatingActionButton.extended(
              onPressed: () => context.push('/add-property'),
              backgroundColor: brandingState.hasAgencyBranding ? agencyColors.primary : StanomerColors.getRoleColor(role),
              elevation: 4,
              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
              label: Text(
                loc.addProperty,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          } else if (isTenant) {
            final tenantProperties = properties.where((p) => p.tenantId != null).toList();
            if (tenantProperties.isEmpty) return null;
            
            final property = tenantProperties.first;
            final requestsAsync = ref.watch(maintenanceRequestsProvider(property.id));
            final hasRequests = requestsAsync.value != null && requestsAsync.value!.isNotEmpty;
            
            return FloatingActionButton.extended(
              onPressed: () {
                if (hasRequests) {
                  context.push('/maintenance', extra: property);
                } else {
                  context.push('/maintenance/new', extra: property);
                }
              },
              backgroundColor: brandingState.hasAgencyBranding ? agencyColors.primary : StanomerColors.tenant,
              elevation: 8,
              highlightElevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
              icon: Icon(
                hasRequests ? LucideIcons.wrench : LucideIcons.plus,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                hasRequests ? loc.maintenance : loc.reportIssue,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }
        }
        return null;
      }(),
      bottomNavigationBar: (isDesktop || !isLandlord)
          ? null
          : BottomNavigationBar(
              currentIndex: _landlordCurrentTab.clamp(0, 3),
              onTap: (index) => setState(() => _landlordCurrentTab = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: StanomerColors.landlord,
              unselectedItemColor: StanomerColors.textTertiary,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(LucideIcons.home),
                  label: loc.tabHome,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(LucideIcons.building2),
                  label: loc.myProperties,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(LucideIcons.wallet),
                  label: loc.tabFinance,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(LucideIcons.wrench),
                  label: loc.tabRequests,
                ),
              ],
            ),
      body: Column(
        children: [
          ConnectionStatusIndicator(
            hasError: propertiesAsync.hasError || pendingInvitesAsync.hasError,
            onRetry: () {
              ref.invalidate(propertiesStreamProvider);
              ref.invalidate(pendingInvitesForUserProvider);
            },
          ),
          Expanded(
            child: (isLandlord && (_landlordCurrentTab == 1 || _landlordCurrentTab == 2 || _landlordCurrentTab == 3))
                ? RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(propertiesStreamProvider);
                      ref.invalidate(pendingInvitesForUserProvider);
                      ref.invalidate(agencyAllPaymentsProvider);
                      ref.invalidate(agencyPendingPaymentsProvider);
                      ref.invalidate(agencyPropertiesProvider);
                      ref.invalidate(agencyMaintenanceRequestsProvider);
                    },
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1360),
                        child: _landlordCurrentTab == 1
                            ? AgencyPortfolioTab(colors: agencyColors)
                            : (_landlordCurrentTab == 2
                                ? AgencyFinanceTab(colors: agencyColors)
                                : AgencyMaintenanceTab(colors: agencyColors)),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(propertiesStreamProvider);
                      ref.invalidate(pendingInvitesForUserProvider);
                      try {
                        await ref.read(pendingInvitesForUserProvider.future);
                      } catch (_) {}
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1360),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (zzplDocumentVersion == null) ...[
                                _ZzplConsentCard(
                                  onConsent: () async {
                                    setState(() => _roleSelectionLoading = true);
                                    try {
                                      final client = Supabase.instance.client;
                                      await client.auth.updateUser(UserAttributes(
                                        data: {'zzpl_document_version': 'v1.0'},
                                      ));
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor: StanomerColors.alertPrimary,
                                        ));
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _roleSelectionLoading = false);
                                      }
                                    }
                                  },
                                  isLoading: _roleSelectionLoading,
                                ),
                              ] else if (_isCheckingInitialRole) ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ] else if (_needsRoleSelection) ...[
                                _buildRoleSelectionCard(loc),
                              ] else if (isLandlord) ...[
                                if (propertiesAsync.hasValue) ...[
                                  () {
                                    final properties = propertiesAsync.value!;
                                    final hasAgencyManagedProperty = properties.any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);
                                    final isAgencyClient = hasAgencyManagedProperty || brandingState.hasAgencyBranding;
                                    final totalUnits = properties.length;
                                    final totalTenants = properties.where((p) => p.tenantId != null).length;
                                    final statsAsync = ref.watch(landlordSummaryProvider);

                    // Tab 3: Bakım & Onarım — navigate to maintenance screen
                    if (_landlordCurrentTab == 3) {
                      if (properties.isEmpty) {
                        return _LandlordEmptyState(
                          onAction: isAgencyClient ? null : () => context.push('/add-property'),
                          isAgencyClient: isAgencyClient,
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            title: loc.localeName == 'tr' ? 'Bakım & Onarım' : 'Maintenance',
                            count: properties.length,
                          ),
                          const SizedBox(height: 12),
                          ...properties.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LandlordMaintenanceEntryCard(property: p),
                          )),
                        ],
                      );
                    }

                    final vacantUnits = properties.where((p) => p.tenantId == null).length;
                    final filteredProperties = properties.where((p) {
                      if (_landlordPropertyFilter == 'rented') return p.tenantId != null;
                      if (_landlordPropertyFilter == 'vacant') return p.tenantId == null;
                      return true;
                    }).toList();

                    // Tab 0 (default): Ana Panel
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Pending Landlord Ownership invitations (if any) ──────────────────────
                        () {
                          final landlordInvites = (pendingInvitesAsync.value ?? [])
                              .where((invite) => invite['target_role'] == 'landlord')
                              .toList();
                          if (landlordInvites.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...landlordInvites.map((invite) {
                                final p = invite['properties'] as Map<String, dynamic>?;
                                if (p == null) return const SizedBox.shrink();
                                return _InvitationCard(invite: invite, propertyData: p);
                              }),
                              const SizedBox(height: 12),
                            ],
                          );
                        }(),
                        _LandlordHero(
                          statsAsync: statsAsync,
                          totalUnits: totalUnits,
                          totalTenants: totalTenants,
                        ),
                        const SizedBox(height: 16),
                        _KpiGrid(statsAsync: statsAsync),
                        const SizedBox(height: 16),
                        _LandlordActionCenter(
                          statsAsync: statsAsync,
                          properties: properties,
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: loc.myProperties,
                          count: properties.length,
                        ),
                        if (properties.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _LandlordPropertyFilterBar(
                            currentFilter: _landlordPropertyFilter,
                            totalCount: properties.length,
                            rentedCount: totalTenants,
                            vacantCount: vacantUnits,
                            onFilterChanged: (filter) => setState(() => _landlordPropertyFilter = filter),
                          ),
                        ],
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (properties.isEmpty) {
                              return _LandlordEmptyState(
                                onAction: isAgencyClient ? null : () => context.push('/add-property'),
                                isAgencyClient: isAgencyClient,
                              );
                            }
                            if (filteredProperties.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  loc.noPropertiesForFilter,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            final isDesktop = constraints.maxWidth >= 850;
                            if (isDesktop && filteredProperties.length > 1) {
                              final leftCol = <Property>[];
                              final rightCol = <Property>[];
                              for (int i = 0; i < filteredProperties.length; i++) {
                                if (i.isEven) {
                                  leftCol.add(filteredProperties[i]);
                                } else {
                                  rightCol.add(filteredProperties[i]);
                                }
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: leftCol.map((p) => _LandlordPropertyCard(property: p)).toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: rightCol.map((p) => _LandlordPropertyCard(property: p)).toList(),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: filteredProperties.map((p) => _LandlordPropertyCard(property: p)).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  }(),
                ] 
else if (propertiesAsync.hasError) ...[
                  AppErrorView(
                    error: propertiesAsync.error!,
                    onRetry: () => ref.invalidate(propertiesStreamProvider),
                  ),
                ] else ...[
                  const Center(child: CircularProgressIndicator()),
                ],
              ] else if (role == 'tenant') ...[
                // ─── Tenant Dashboard: Landlord-mirrored layout ───────────────
                () {
                  if (pendingInvitesAsync.hasValue && propertiesAsync.hasValue) {
                    final allInvites = pendingInvitesAsync.value!;
                    final tenantInvites = allInvites.where((invite) => invite['target_role'] != 'landlord').toList();
                    final properties = propertiesAsync.value!;
                    final tenantProperties = properties.where((p) => p.tenantId == user?.id).toList();

                    if (tenantInvites.isEmpty && tenantProperties.isEmpty) {
                      return _TenantEmptyState(
                        onRefresh: () async {
                          await Future.wait([
                            ref.refresh(propertiesFutureProvider.future),
                            ref.refresh(pendingInvitesForUserProvider.future),
                          ]);
                        },
                      );
                    }

                    // Safely constrain index
                    if (_selectedTenantPropertyIndex >= tenantProperties.length) {
                      _selectedTenantPropertyIndex = 0;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 0. Pending tenant invitations (if any) ──────────────────
                        ...tenantInvites.map((invite) {
                          final p = invite['properties'] as Map<String, dynamic>?;
                          if (p == null) return const SizedBox.shrink();
                          return _InvitationCard(invite: invite, propertyData: p);
                        }),

                        if (tenantProperties.isNotEmpty) ...[
                          // ── Property tab switcher (only when > 1 property) ──
                          if (tenantProperties.length > 1) ...[
                            _buildPropertyTabs(tenantProperties),
                            const SizedBox(height: 16),
                          ],

                          Consumer(
                            builder: (context, ref, _) {
                              final property = tenantProperties[_selectedTenantPropertyIndex];
                              final contractAsync = ref.watch(activeContractProvider(property.id));
                              final financialStatusAsync = ref.watch(propertyFinancialStatusProvider(property.id));
                              final paymentsAsync = ref.watch(rentPaymentsProvider(property.id));

                              if (contractAsync.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (contractAsync.hasError) {
                                return AppErrorView(
                                  error: contractAsync.error!,
                                  onRetry: () => ref.invalidate(activeContractProvider(property.id)),
                                );
                              }

                              final contract = contractAsync.value;
                              if (contract != null && contract.agencyId != null && contract.agencyId!.trim().isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  ref.read(agencyBrandingProvider.notifier).updateBrandingForSession(
                                        role: 'tenant',
                                        properties: tenantProperties,
                                        selectedIndex: _selectedTenantPropertyIndex,
                                        contractAgencyId: contract.agencyId,
                                      );
                                });
                              }

                              if (contract == null) {
                                // Has property but no active contract yet
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    _SectionHeader(
                                      title: loc.myProperties,
                                      count: tenantProperties.length,
                                    ),
                                    const SizedBox(height: 12),
                                    _TenantPropertyOverviewCard(property: property),
                                  ],
                                );
                              }

                              final financialStatus = financialStatusAsync.value;
                              // Awaiting payments with their titles for the secondary card
                              final awaitingPayments = (paymentsAsync.value ?? [])
                                  .where((p) => p.status == 'declared')
                                  .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── 1. Hero — Finansal Durum & Bakiyeler ─────────────────
                                  InkWell(
                                    onTap: () => context.push('/property-detail', extra: property),
                                    borderRadius: BorderRadius.circular(22),
                                    child: _TenantHero(
                                      property: property,
                                      contract: contract,
                                      financialStatus: financialStatus,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ── 2. Proaktif Aksiyon & Bildirim Merkezi ───────────────
                                  _TenantActionCenter(
                                    property: property,
                                    contract: contract,
                                    financialStatus: financialStatus,
                                    awaitingPayments: awaitingPayments,
                                  ),
                                  const SizedBox(height: 20),

                                  // ── 3. Kiralık Mülk & Yönetim Bilgileri ─────────────────
                                  _SectionHeader(
                                    title: loc.myProperties,
                                    count: tenantProperties.length,
                                  ),
                                  const SizedBox(height: 12),
                                  ...tenantProperties.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TenantPropertyOverviewCard(property: p),
                                  )),

                                  const SizedBox(height: 20),

                                  // ── 5. Son Ödemeler & Finans Geçmişi ─────────────────────
                                  Row(
                                    children: [
                                      Text(
                                        loc.paymentHistory,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => context.push('/property-detail', extra: {
                                          'property': property,
                                          'initialTabIndex': 1,
                                        }),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              loc.viewAll,
                                              style: const TextStyle(
                                                color: Color(0xFF0F766E),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF0F766E)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _PropertyHistoryList(propertyId: property.id, limit: 5),
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  } else if (pendingInvitesAsync.hasError || propertiesAsync.hasError) {
                    return AppErrorView(
                      error: propertiesAsync.error ?? pendingInvitesAsync.error!,
                      onRetry: () {
                        ref.invalidate(propertiesStreamProvider);
                        ref.invalidate(pendingInvitesForUserProvider);
                      },
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }(),
              ] else ...[
                _buildRoleSelectionCard(loc),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
),
],
),
),
);
}

  void _showRoleSwitcher(BuildContext context, String? currentRole) {
    final user = ref.read(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?;
    final userEmail = user?.email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ResilientBottomSheetWrapper(
        child: RoleSwitcherBottomSheet(
          userName: userName,
          userEmail: userEmail,
          activeRole: currentRole,
          onRoleSelected: (newRole) {
            Navigator.pop(context);
            if (newRole != currentRole) {
              _updateRole(newRole);
            }
          },
          onProfileTap: () {
            Navigator.pop(context);
            context.push('/profile');
          },
          onSignOutTap: () async {
            Navigator.pop(context);
            final loc = AppLocalizations.of(context)!;
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(loc.logout),
                content: Text(loc.confirmSignOutMessage),
                actions: [
                  TextButton(
                    child: Text(loc.cancel),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: Text(loc.logout),
                    style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAgencyLogoBadge(AgencyBrandingState brandingState, AgencyColorScheme colors) {
    final title = brandingState.appTitle;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'A';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }

  Future<void> _updateRole(String role) async {
    setState(() => _roleSelectionLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(role: role);
      ref.invalidate(profileFutureProvider);
      ref.invalidate(userRoleProvider);
      ref.invalidate(pendingInvitesForUserProvider);
      ref.read(agencyBrandingProvider.notifier).clear();
      if (mounted) {
        setState(() {
          _needsRoleSelection = false;
          _hasBothInvites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } finally {
      if (mounted) setState(() => _roleSelectionLoading = false);
    }
  }

  Widget _buildRoleSelectionCard(AppLocalizations loc) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.only(top: 40, bottom: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: StanomerColors.bgCard,
          borderRadius: const BorderRadius.all(StanomerRadius.xl),
          boxShadow: StanomerShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.userCircle, size: 64, color: StanomerColors.brandPrimary),
            const SizedBox(height: 24),
            Text(
              loc.whatAreYou,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              loc.selectRoleToContinue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: StanomerColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_hasBothInvites) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.localeName == 'tr'
                            ? 'Hem ev sahibi hem kiracı davetiniz bulunmaktadır. Lütfen devam etmek istediğiniz rolü seçin.'
                            : (loc.localeName.startsWith('sr')
                                ? 'Imate poziv i kao stanar i kao vlasnik. Izaberite ulogu za nastavak.'
                                : (loc.localeName == 'ru'
                                    ? 'У вас есть приглашения как арендатора, так и владельца. Выберите роль для продолжения.'
                                    : 'You have invitations both as a tenant and a landlord. Please select a role to continue.')),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: RoleCard(
                    title: loc.tenant,
                    icon: LucideIcons.user,
                    isSelected: false,
                    onTap: _roleSelectionLoading ? null : () => _updateRole('tenant'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: RoleCard(
                    title: loc.landlord,
                    icon: LucideIcons.building,
                    isSelected: false,
                    onTap: _roleSelectionLoading ? null : () => _updateRole('landlord'),
                  ),
                ),
              ],
            ),
            if (_roleSelectionLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTabs(List<Property> properties) {
    final agencyColors = ref.watch(agencyColorSchemeProvider);
    final activeColor = agencyColors.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(properties.length, (index) {
          final isSelected = index == _selectedTenantPropertyIndex;
          final property = properties[index];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTenantPropertyIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : StanomerColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor : StanomerColors.borderDefault,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Text(
                  property.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : StanomerColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LandlordHero extends ConsumerWidget {
  final AsyncValue<LandlordDashboardStats> statsAsync;
  final int totalUnits;
  final int totalTenants;

  const _LandlordHero({
    required this.statsAsync,
    required this.totalUnits,
    required this.totalTenants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? (user?.email != null ? user!.email!.split('@').first : '');
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', loc.localeName).format(now);
    final occupancyRate = totalUnits > 0 ? ((totalTenants / totalUnits) * 100).round() : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
            Color(0xFF1A5FA8), // Stanomer Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative ambient circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: User Greeting & Month Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.crown, size: 12, color: Color(0xFFFBBF24)),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.landlord.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userName.isNotEmpty ? loc.welcomeUser(userName) : loc.tabHome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Month Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF93C5FD)),
                          const SizedBox(width: 6),
                          Text(
                            monthName,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Middle: Collected Revenue
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.monthlyCollected.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                statsAsync.when(
                  data: (stats) => Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: _buildAmountSpans(stats.collectedByCurrency),
                  ),
                  loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  error: (_, __) => const Text('0,00 €', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                ),

                const SizedBox(height: 22),

                // Bottom Stats Deck: 3 Glassmorphic Tiles
                Row(
                  children: [
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.building2,
                        iconColor: const Color(0xFF60A5FA),
                        label: loc.units,
                        value: '$totalUnits',
                        sublabel: loc.totalPropertiesCount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.users,
                        iconColor: const Color(0xFF34D399),
                        label: loc.tenantsLabel,
                        value: '$totalTenants',
                        sublabel: loc.activeTenantsCount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.pieChart,
                        iconColor: const Color(0xFFFBBF24),
                        label: loc.occupancyRate,
                        value: '%$occupancyRate',
                        sublabel: loc.portfolioRateSubtitle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAmountSpans(Map<String, double> collected) {
    if (collected.isEmpty) {
      return [
        const Text(
          '0,00 €',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        )
      ];
    }

    final sortedCurrencies = collected.keys.toList()..sort();
    final List<Widget> spans = [];

    for (int i = 0; i < sortedCurrencies.length; i++) {
      final cur = sortedCurrencies[i];
      final amount = collected[cur]!;
      final isFirst = i == 0;

      if (!isFirst) {
        spans.add(Text(
          '+',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      spans.add(Container(
        padding: isFirst
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: isFirst
            ? null
            : BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
        child: Text(
          CurrencyUtils.formatAmount(amount, cur, useSymbol: true),
          style: TextStyle(
            color: Colors.white,
            fontSize: isFirst ? 32 : 22,
            fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: isFirst ? -0.5 : 0,
          ),
        ),
      ));
    }

    return spans;
  }
}

class _HeroStatDeckTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sublabel;

  const _HeroStatDeckTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AsyncValue<LandlordDashboardStats> statsAsync;

  const _KpiGrid({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return statsAsync.when(
      data: (stats) {
        final hasDelays = stats.delaysCount > 0;
        final hasAwaiting = stats.awaitingApprovalCount > 0;

        final rentCollectedFormatted = CurrencyUtils.formatCurrencyMap(
          stats.collectedByType['Kira'] ?? {},
          useSymbols: true,
        );

        final items = [
          _KpiCard(
            icon: LucideIcons.banknote,
            value: rentCollectedFormatted.isEmpty ? '0 €' : rentCollectedFormatted,
            label: loc.rent,
            sublabel: loc.collectedRentSubtitle,
            accentColor: const Color(0xFF059669), // Emerald
            surfaceColor: const Color(0xFFECFDF5),
          ),
          _KpiCard(
            icon: LucideIcons.clock,
            value: '${stats.awaitingApprovalCount}',
            label: loc.awaitingApproval,
            sublabel: loc.awaitingApprovalSubtitle,
            accentColor: const Color(0xFFD97706), // Amber
            surfaceColor: const Color(0xFFFFFBEB),
            isAlert: hasAwaiting,
          ),
          _KpiCard(
            icon: LucideIcons.alertTriangle,
            value: '${stats.delaysCount}',
            label: loc.delays,
            sublabel: loc.overduePaymentsSubtitle,
            accentColor: const Color(0xFFE11D48), // Rose
            surfaceColor: const Color(0xFFFFF1F2),
            isAlert: hasDelays,
          ),
          _KpiCard(
            icon: LucideIcons.doorOpen,
            value: '${stats.vacantCount}',
            label: loc.vacant,
            sublabel: loc.vacantUnitsSubtitle,
            accentColor: const Color(0xFF4F46E5), // Indigo
            surfaceColor: const Color(0xFFEEF2FF),
            isAlert: false,
          ),
        ];

        if (isDesktop) {
          return Row(
            children: items.map((item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: item,
              ),
            )).toList(),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.30,
          children: items,
        );
      },
      loading: () => const SizedBox(height: 90),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color accentColor;
  final Color surfaceColor;
  final bool isAlert;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.accentColor,
    required this.surfaceColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? accentColor.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAlert
                ? accentColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.attentionTag,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isAlert ? accentColor : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandlordActionCenter extends StatelessWidget {
  final AsyncValue<LandlordDashboardStats> statsAsync;
  final List<Property> properties;

  const _LandlordActionCenter({
    required this.statsAsync,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return statsAsync.when(
      data: (stats) {
        final hasAwaiting = stats.awaitingApprovalCount > 0;
        final hasUnentered = stats.unenteredBillsCount > 0;
        final hasDelays = stats.delaysCount > 0;

        if (!hasAwaiting && !hasUnentered && !hasDelays) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.checkCheck, size: 16, color: Color(0xFF15803D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.allPropertiesUpToDate,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final property = properties.where((p) => p.id == stats.latestAwaitingPropertyId).firstOrNull;
        final unenteredProperty = properties.where((p) => p.id == stats.latestUnenteredPropertyId).firstOrNull;

        return Column(
          children: [
            if (hasAwaiting)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.clock, size: 18, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${stats.awaitingApprovalCount} ${loc.awaitingApproval}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (property != null) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '(${property.name})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB45309),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (stats.latestAwaitingTitle != null)
                            Text(
                              stats.latestAwaitingTitle!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFB45309),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (property != null) {
                          context.push('/property-detail', extra: {
                            'property': property,
                            'initialTabIndex': 1,
                          });
                        }
                      },
                      icon: const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                      label: Text(
                        loc.reviewAction,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasUnentered)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.receipt, size: 18, color: Color(0xFF1D4ED8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  loc.localeName == 'tr'
                                      ? '${stats.unenteredBillsCount} faturanın tutarı girilmedi'
                                      : loc.localeName == 'ru'
                                          ? '${stats.unenteredBillsCount} счет(а) ждут ввода суммы'
                                          : loc.localeName.startsWith('sr')
                                              ? '${stats.unenteredBillsCount} računa čeka unos iznosa'
                                              : '${stats.unenteredBillsCount} bill(s) need amount entered',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unenteredProperty != null) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '(${unenteredProperty.name})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2563EB),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (stats.latestUnenteredTitle != null)
                            Text(
                              stats.latestUnenteredTitle!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF2563EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (unenteredProperty != null) {
                          context.push('/property-detail', extra: {
                            'property': unenteredProperty,
                            'initialTabIndex': 1,
                          });
                        }
                      },
                      icon: const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                      label: Text(
                        loc.localeName == 'tr'
                            ? 'Tutar Gir'
                            : loc.localeName == 'ru'
                                ? 'Ввести'
                                : loc.localeName.startsWith('sr')
                                    ? 'Unesi'
                                    : 'Enter',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasDelays)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFBE123C)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.localeName == 'tr'
                            ? '${stats.delaysCount} mülkte kiracı ödemesi gecikiyor.'
                            : loc.localeName == 'ru'
                                ? 'В ${stats.delaysCount} объекте(ах) просрочен платёж арендатора.'
                                : loc.localeName.startsWith('sr')
                                    ? 'U ${stats.delaysCount} nekretnini zakupac kasni s plaćanjem.'
                                    : '${stats.delaysCount} property/properties have delayed tenant payment(s).',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9F1239),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LandlordPropertyFilterBar extends StatelessWidget {
  final String currentFilter;
  final int totalCount;
  final int rentedCount;
  final int vacantCount;
  final ValueChanged<String> onFilterChanged;

  const _LandlordPropertyFilterBar({
    required this.currentFilter,
    required this.totalCount,
    required this.rentedCount,
    required this.vacantCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChipItem(
            label: loc.filterAll,
            count: totalCount,
            isSelected: currentFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: loc.filterRented,
            count: rentedCount,
            isSelected: currentFilter == 'rented',
            onTap: () => onFilterChanged('rented'),
            badgeColor: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: loc.filterVacant,
            count: vacantCount,
            isSelected: currentFilter == 'vacant',
            onTap: () => onFilterChanged('vacant'),
            badgeColor: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? badgeColor;

  const _FilterChipItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A5FA8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A5FA8) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1A5FA8).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, required this.count, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              loc.viewAll,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1A5FA8)),
            ),
          ),
      ],
    );
  }
}

class _LandlordPropertyCard extends ConsumerWidget {
  final Property property;

  const _LandlordPropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final financialStatusAsync = ref.watch(propertyFinancialStatusProvider(property.id));
    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final agencyColors = ref.watch(agencyColorSchemeProvider);

    final viewDetailsLabel = loc.detailsAction;

    String formatDate(DateTime? date) {
      if (date == null) return '-';
      return DateFormat('dd.MM.yyyy', loc.localeName).format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Property Header
          InkWell(
            onTap: () => context.push('/property-detail', extra: property),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Property Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A5FA8).withValues(alpha: 0.12),
                          const Color(0xFF1A5FA8).withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A5FA8).withValues(alpha: 0.15)),
                    ),
                    child: const Icon(LucideIcons.building2, color: Color(0xFF1A5FA8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Occupancy Status Pill
                  activeContractAsync.when(
                    data: (contract) {
                      final isVacant = contract == null || property.tenantId == null;
                      final isInvited = contract != null && property.tenantId == null;

                      if (isInvited) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                loc.invitedStatusTag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isVacant ? const Color(0xFFF1F5F9) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isVacant ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isVacant ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isVacant ? loc.vacant : loc.rentedStatusTag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isVacant ? const Color(0xFF475569) : const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // 2. Contract & Tenant Snapshot Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: activeContractAsync.when(
              data: (contract) {
                if (contract == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.info, color: Color(0xFF94A3B8), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.noActiveContractTapToInvite,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final displayTenant = property.tenantName ?? contract.inviteeEmail;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Tenant and Rent Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(LucideIcons.user, size: 13, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayTenant,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Rent Amount Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              CurrencyUtils.formatAmount(contract.monthlyRent, contract.currency, useSymbol: true),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Contract Dates and Due Day
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${formatDate(contract.startDate)} - ${formatDate(contract.endDate)} · ${loc.dueDayOfMonth}: ${contract.dueDay}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // 3. Financial Progress Bar & Badges
          financialStatusAsync.when(
            data: (state) {
              if (state.generalStatus == PropertyFinancialStatus.vacant) {
                return const SizedBox(height: 12);
              }

              final total = (state.paidCount + state.pendingCount + state.awaitingCount);
              final progress = total > 0 ? (state.paidCount / total) : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Bar Header
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress < 1.0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${state.paidCount} / $total ${loc.paidLabel.toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status Pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (state.rentStatus != null)
                          _StatusPill(
                            label: '${loc.rent}: ${state.rentStatus == RentStatus.debt ? loc.debtLabel.toUpperCase() : (state.rentStatus == RentStatus.awaitingApproval ? loc.waiting.toUpperCase() : loc.paidLabel.toUpperCase())}',
                            color: state.rentStatus == RentStatus.debt ? const Color(0xFFFFF1F2) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                            textColor: state.rentStatus == RentStatus.debt ? const Color(0xFFE11D48) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFFD97706) : const Color(0xFF059669)),
                          ),
                        if (state.billStatus != null)
                          _StatusPill(
                            label: '${loc.bills}: ${state.billStatus == BillStatus.debt ? loc.debtLabel.toUpperCase() : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? loc.waiting.toUpperCase() : loc.paidLabel.toUpperCase())}',
                            color: state.billStatus == BillStatus.debt ? const Color(0xFFFFF1F2) : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                            textColor: state.billStatus == BillStatus.debt ? const Color(0xFFE11D48) : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? const Color(0xFFD97706) : const Color(0xFF059669)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 4. Quick Action Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Delete button
                IconButton(
                  tooltip: loc.delete,
                  onPressed: () => _deleteProperty(context, ref, property),
                  icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 17),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 4),
                const Spacer(),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Finance Quick Jump Button
                      TextButton.icon(
                        onPressed: () => context.push('/property-detail', extra: {
                          'property': property,
                          'initialTabIndex': 1,
                        }),
                        icon: const Icon(LucideIcons.wallet, size: 14, color: Color(0xFF059669)),
                        label: Text(
                          loc.tabFinance,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          backgroundColor: const Color(0xFFECFDF5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Maintenance Quick Jump Button
                      TextButton.icon(
                        onPressed: () => context.push('/maintenance', extra: property),
                        icon: const Icon(LucideIcons.wrench, size: 14, color: Color(0xFF4F46E5)),
                        label: Text(
                          loc.tabRequests,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          backgroundColor: const Color(0xFFEEF2FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Details Button
                      ElevatedButton.icon(
                        onPressed: () => context.push('/property-detail', extra: property),
                        icon: const Icon(LucideIcons.chevronRight, size: 15, color: Colors.white),
                        label: Text(
                          viewDetailsLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: agencyColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(BuildContext context, WidgetRef ref, Property property) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDeleteTitle),
        content: Text(loc.confirmDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(propertyRepositoryProvider).deleteProperty(property.id);
        ref.invalidate(propertiesStreamProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.propertyDeletedSuccess)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary));
        }
      }
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusPill({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.4),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF999999)),
      ),
    );
  }
}

class _PropertyHistoryList extends ConsumerWidget {
  final String propertyId;
  final int limit;

  const _PropertyHistoryList({required this.propertyId, this.limit = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(rentPaymentsProvider(propertyId));

    return paymentsAsync.when(
      data: (payments) {
        final paidPayments = payments.where((p) => p.status == 'paid').toList()
          ..sort((a, b) => (b.paidAt ?? b.dueDate).compareTo(a.paidAt ?? a.dueDate));

        final displayPayments = paidPayments.take(limit).toList();

        if (displayPayments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
            child: Center(child: Text(loc.noFinancialRecords, style: const TextStyle(color: Color(0xFF999999), fontSize: 13))),
          );
        }

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
            child: Column(
              children: List.generate(displayPayments.length, (index) {
                final payment = displayPayments[index];
                return Column(
                  children: [
                     ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF2DB87A).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, size: 16, color: Color(0xFF2DB87A)),
                      ),
                      title: Text(ExpenseUtils.getLocalizedExpenseName(payment.title, loc), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text(DateFormat('MMM dd, yyyy', loc.localeName).format(payment.paidAt ?? payment.dueDate), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      trailing: Text(CurrencyUtils.formatAmount(payment.amount, payment.currency, useSymbol: true), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2DB87A))),
                    ),
                    if (index < displayPayments.length - 1) const Divider(height: 1, indent: 64, color: Color(0xFFEEEEEE)),
                  ],
                );
              }),
            ),
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Card shown in landlord Maintenance tab for each property — tapping navigates to MaintenanceScreen.
class _LandlordMaintenanceEntryCard extends ConsumerWidget {
  final Property property;
  const _LandlordMaintenanceEntryCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceAsync = ref.watch(maintenanceRequestsProvider(property.id));
    final openCount = maintenanceAsync.valueOrNull
            ?.where((r) => r.status != 'completed' && r.status != 'rejected')
            .length ??
        0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/maintenance', extra: property),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StanomerColors.landlord.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.wrench, size: 22, color: StanomerColors.landlord),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      property.address,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (openCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$openCount açık',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF856404)),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandlordEmptyState extends StatelessWidget {
  final VoidCallback? onAction;
  final bool isAgencyClient;
  const _LandlordEmptyState({this.onAction, this.isAgencyClient = false});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(LucideIcons.home, size: 48, color: Color(0xFF1A5FA8)),
          const SizedBox(height: 20),
          Text(loc.noProperties, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            isAgencyClient ? loc.managedByAgencyDesc : loc.addYourFirstProperty,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          if (!isAgencyClient && onAction != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(loc.addProperty, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5FA8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => JoinPropertySheet.show(context),
              icon: const Icon(LucideIcons.qrCode, size: 18),
              label: Text(loc.agencyPropertyTakeoverQr, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A5FA8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF1A5FA8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final Map<String, dynamic> propertyData;

  const _InvitationCard({required this.invite, required this.propertyData});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StanomerColors.brandPrimarySurface.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.all(StanomerRadius.lg),
        border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => context.push('/invite?token=${invite['token']}'),
        borderRadius: const BorderRadius.all(StanomerRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(StanomerRadius.md),
                ),
                child: const Icon(LucideIcons.mailOpen, color: StanomerColors.brandPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: invite['status'] == 'negotiating' ? Colors.orange : StanomerColors.brandPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Builder(
                        builder: (context) {
                          final rawStatus = invite['status'] as String;
                          final statusEnum = rawStatus == 'revision_requested'
                              ? ContractStatus.revisionRequested
                              : ContractStatus.values.firstWhere((e) => e.name == rawStatus, orElse: () => ContractStatus.pending);
                          return Text(
                            statusEnum.label(loc).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      propertyData['name'] ?? 'Property',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (invite['inviter_name'] != null)
                      Text(
                        loc.invitedBy(invite['inviter_name']),
                        style: const TextStyle(color: StanomerColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    Text(
                      propertyData['address'] ?? '',
                      style: const TextStyle(color: StanomerColors.textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: StanomerColors.brandPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantEmptyState extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _TenantEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final agencyColors = ref.watch(agencyColorSchemeProvider);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(StanomerRadius.xl),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.home, size: 48, color: agencyColors.primary),
          const SizedBox(height: 16),
          Text(
            loc.tenantEmptyStateTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            loc.tenantEmptyStateMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(loc.refresh),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => JoinPropertySheet.show(context),
              icon: const Icon(LucideIcons.qrCode, size: 20),
              label: Text(
                loc.joinWithQrCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: agencyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantHero extends ConsumerWidget {
  final Property property;
  final Contract contract;
  final PropertyFinancialState? financialStatus;

  const _TenantHero({
    required this.property,
    required this.contract,
    this.financialStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final nextDue = DateTime(now.year, now.month, contract.dueDay);
    final dueDate = nextDue.isBefore(now)
        ? DateTime(now.year, now.month + 1, contract.dueDay)
        : nextDue;
    final daysLeft = dueDate.difference(now).inDays;

    final rentStatus = financialStatus?.rentStatus;
    final pendingTotals = financialStatus?.pendingTotals ?? {};
    final awaitingTotals = financialStatus?.awaitingTotals ?? {};

    final hasDebt = pendingTotals.values.any((v) => v > 0);
    final hasCredit = !hasDebt && pendingTotals.values.any((v) => v < 0);
    final hasAwaiting = awaitingTotals.values.any((v) => v > 0) || (financialStatus?.awaitingCount ?? 0) > 0;
    final isOverdue = rentStatus == RentStatus.debt || financialStatus?.billStatus == BillStatus.debt;

    // Gradient colors based on financial health
    final List<Color> gradientColors;
    final Color glowColor;
    if (isOverdue || hasDebt) {
      gradientColors = const [Color(0xFF881337), Color(0xFF9F1239), Color(0xFFBE123C)];
      glowColor = const Color(0xFFE11D48);
    } else if (hasCredit) {
      gradientColors = const [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)];
      glowColor = const Color(0xFF3B82F6);
    } else if (hasAwaiting) {
      gradientColors = const [Color(0xFF78350F), Color(0xFF92400E), Color(0xFFD97706)];
      glowColor = const Color(0xFFF59E0B);
    } else {
      gradientColors = const [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF115E59)];
      glowColor = const Color(0xFF10B981);
    }

    final String heroLabel;
    if (hasDebt) {
      heroLabel = loc.totalDebt.toUpperCase();
    } else if (hasCredit) {
      heroLabel = loc.settlementCredit.toUpperCase();
    } else if (hasAwaiting) {
      heroLabel = loc.awaitingHeader.toUpperCase();
    } else {
      heroLabel = loc.noDebtLabel.toUpperCase();
    }

    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? (user?.email != null ? user!.email!.split('@').first : '');

    final currentMonthFormatted = DateFormat('MMMM yyyy', loc.localeName).format(now);

    // Status pill
    final String statusPillText;
    final IconData statusPillIcon;
    if (isOverdue || hasDebt) {
      statusPillText = loc.debtLabel;
      statusPillIcon = LucideIcons.alertTriangle;
    } else if (hasCredit) {
      statusPillText = loc.settlementCredit;
      statusPillIcon = LucideIcons.arrowDownLeft;
    } else if (hasAwaiting) {
      statusPillText = loc.awaitingApproval;
      statusPillIcon = LucideIcons.clock;
    } else {
      statusPillText = loc.noDebtLabel;
      statusPillIcon = LucideIcons.checkCircle2;
    }

    // Due date badge text
    final String dueBadgeText;
    if (daysLeft < 0) {
      dueBadgeText = loc.overdueBadge;
    } else if (daysLeft == 0) {
      dueBadgeText = loc.dueTodayBadge;
    } else {
      dueBadgeText = loc.daysLeftBadge(daysLeft);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient decoration
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row: Role Pill + Current Month Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.user, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            loc.tenant.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentMonthFormatted,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Welcome Greeting
                if (userName.isNotEmpty)
                  Text(
                    loc.welcomeUser(userName),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),

                // Hero Label & Status Pill Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      heroLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusPillIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            statusPillText.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Multi-currency Amounts Display
                ...() {
                  final Map<String, double> totals;
                  if (hasDebt || hasCredit) {
                    totals = pendingTotals;
                  } else if (hasAwaiting) {
                    totals = awaitingTotals;
                  } else {
                    final defaultCurrency = contract.currency.isNotEmpty ? contract.currency : 'EUR';
                    totals = pendingTotals.isEmpty ? {defaultCurrency: 0.0} : pendingTotals;
                  }
                  final currencies = totals.keys.toList()..sort();
                  if (currencies.isEmpty) {
                    return [
                      const Text(
                        '0,00 €',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                    ];
                  }
                  return currencies.map((cur) {
                    final amount = totals[cur]!;
                    final isFirst = cur == currencies.first;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (!isFirst)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          CurrencyUtils.formatAmount(amount, cur, useSymbol: true),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isFirst ? 32 : 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                }(),
                const SizedBox(height: 18),

                // 3-Tile Quick Info Deck
                Row(
                  children: [
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.building2,
                        iconColor: const Color(0xFF60A5FA),
                        label: loc.myProperties,
                        value: property.name,
                        sublabel: property.address,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.calendar,
                        iconColor: const Color(0xFFFBBF24),
                        label: loc.dueDayOfMonth,
                        value: DateFormat('dd MMM', loc.localeName).format(dueDate),
                        sublabel: dueBadgeText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.banknote,
                        iconColor: const Color(0xFF34D399),
                        label: loc.monthlyBaseRent,
                        value: CurrencyUtils.formatAmount(contract.monthlyRent, contract.currency, useSymbol: true),
                        sublabel: contract.currency,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantActionCenter extends StatelessWidget {
  final Property property;
  final Contract contract;
  final PropertyFinancialState? financialStatus;
  final List<RentPayment> awaitingPayments;

  const _TenantActionCenter({
    required this.property,
    required this.contract,
    this.financialStatus,
    required this.awaitingPayments,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasPendingProposal = contract.status == ContractStatus.revisionRequested;
    final awaitingCount = awaitingPayments.length;
    final hasAwaiting = awaitingCount > 0;
    final pendingCount = financialStatus?.pendingCount ?? 0;
    final totalPendingNet = financialStatus?.pendingTotals.values.fold<double>(0.0, (sum, val) => sum + val) ?? 0.0;
    final hasDebt = (totalPendingNet > 0.01 && pendingCount > 0) || (financialStatus?.pendingTotals.values.any((v) => v > 0.01) ?? false);
    final hasCredit = totalPendingNet < -0.01 && !hasDebt;
    final isOverdue = financialStatus?.rentStatus == RentStatus.debt || financialStatus?.billStatus == BillStatus.debt;

    final now = DateTime.now();
    final nextDue = DateTime(now.year, now.month, contract.dueDay);
    final dueDate = nextDue.isBefore(now)
        ? DateTime(now.year, now.month + 1, contract.dueDay)
        : nextDue;

    if (!hasPendingProposal && !hasAwaiting && !hasDebt && !isOverdue) {
      if (hasCredit) {
        final creditAmount = totalPendingNet.abs();
        final cur = contract.currency.isNotEmpty ? contract.currency : (financialStatus?.pendingTotals.keys.firstOrNull ?? 'EUR');
        final formattedCredit = CurrencyUtils.formatAmount(creditAmount, cur, useSymbol: true);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.wallet, size: 16, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.localeName == 'tr'
                          ? 'Masraf mahsubundan $formattedCredit alacağınız bulunmaktadır.'
                          : (loc.localeName == 'ru'
                              ? 'У вас есть остаток зачета по расходам: $formattedCredit.'
                              : (loc.localeName.startsWith('sr')
                                  ? 'Imate preostalo potraživanje od prebijanja troškova: $formattedCredit.'
                                  : 'You have a maintenance credit balance of $formattedCredit.')),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.localeName == 'tr'
                          ? 'Sonraki kira veya aidat ödemelerinizden mahsup edilebilir.'
                          : (loc.localeName == 'ru'
                              ? 'Может быть зачтено в счет будущих платежей по аренде или счетам.'
                              : (loc.localeName.startsWith('sr')
                                  ? 'Može se prebiti sa predstojećim zakupom ili računima.'
                                  : 'Can be deducted from upcoming rent or utility payments.')),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Clean, peaceful state
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.checkCheck, size: 16, color: Color(0xFF15803D)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.allTenantPaymentsUpToDate(DateFormat('dd MMMM', loc.localeName).format(dueDate)),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 1. Contract revision proposal by landlord
        if (hasPendingProposal)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileText, size: 18, color: Color(0xFFB45309)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.landlordProposedChanges,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.push('/property-detail', extra: property),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.reviewAction,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // 2. Receipts waiting for approval
        if (hasAwaiting)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFAC775)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.clock, size: 18, color: Color(0xFF854F0B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tenantAwaitingReceiptApprovalMsg(awaitingCount),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF854F0B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        property.agencyId != null && property.agencyId!.isNotEmpty
                            ? (loc.localeName == 'tr'
                                ? 'Ödemelerin ödendi olarak işaretlenmesi için acentenin onaylaması gerekiyor.'
                                : (loc.localeName == 'ru'
                                    ? 'Требуется подтверждение агентства, чтобы отметить как оплачено.'
                                    : (loc.localeName.startsWith('sr')
                                        ? 'Potrebno je odobrenje agencije da bi se označilo kao plaćeno.'
                                        : 'Agency approval is required to mark payments as paid.')))
                            : loc.awaitingExplanation,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA0621A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.push('/property-detail', extra: {
                    'property': property,
                    'initialTabIndex': 1,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.reviewAction,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // 3. Outstanding or overdue payments
        if (hasDebt || isOverdue)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFBE123C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.tenantOutstandingDebtMsg(pendingCount > 0 ? pendingCount : 1),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9F1239),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.push('/property-detail', extra: {
                    'property': property,
                    'initialTabIndex': 1,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.payNowAction,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TenantPropertyOverviewCard extends ConsumerWidget {
  final Property property;

  const _TenantPropertyOverviewCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final activeContractAsync = ref.watch(activeContractProvider(property.id));

    String formatDate(DateTime? date) {
      if (date == null) return '-';
      return DateFormat('dd.MM.yyyy', loc.localeName).format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push('/property-detail', extra: property),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F766E).withValues(alpha: 0.12),
                          const Color(0xFF0F766E).withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.15)),
                    ),
                    child: const Icon(LucideIcons.home, color: Color(0xFF0F766E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          loc.rentedStatusTag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contract info banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: activeContractAsync.when(
              data: (contract) {
                if (contract == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${formatDate(contract.startDate)} - ${formatDate(contract.endDate)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${loc.dueDayOfMonth}: ${contract.dueDay}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (contract.depositAmount != null && contract.depositAmount! > 0) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.depositSecuredLabel,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                            Text(
                              CurrencyUtils.formatAmount(contract.depositAmount!, contract.currency, useSymbol: true),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Action button row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/property-detail', extra: {
                      'property': property,
                      'initialTabIndex': 1,
                    }),
                    icon: const Icon(LucideIcons.creditCard, size: 14, color: Color(0xFF0F766E)),
                    label: Text(
                      loc.quickActionFinance,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCCFBF1)),
                      backgroundColor: const Color(0xFFF0FDFA),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/maintenance', extra: property),
                    icon: const Icon(LucideIcons.wrench, size: 14, color: Color(0xFF2563EB)),
                    label: Text(
                      loc.quickActionMaintenance,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => context.push('/property-detail', extra: property),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.detailsAction,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF334155)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZzplConsentCard extends ConsumerWidget {
  final VoidCallback onConsent;
  final bool isLoading;

  const _ZzplConsentCard({
    required this.onConsent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: StanomerColors.bgCard,
          borderRadius: const BorderRadius.all(StanomerRadius.xl),
          boxShadow: StanomerShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.shieldCheck, size: 64, color: StanomerColors.brandPrimary),
            const SizedBox(height: 24),
            Text(
              loc.zzplConsentTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StanomerColors.bgPage,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StanomerColors.borderDefault),
              ),
              child: Text(
                loc.consentTextFullBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: StanomerColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: isLoading ? null : onConsent,
              icon: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.check),
              label: Text(
                loc.zzplAgreeAndContinue,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: StanomerColors.brandPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: isLoading ? null : () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(loc.logout),
              style: TextButton.styleFrom(
                foregroundColor: StanomerColors.alertPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
