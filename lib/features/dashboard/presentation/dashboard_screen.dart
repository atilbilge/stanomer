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
  int _selectedTenantPropertyIndex = 0;
  int _landlordCurrentTab = 0; // 0: Ana Panel, 1: Mülklerim, 2: Finans, 3: Bakım
  String _landlordPropertyFilter = 'all'; // 'all', 'rented', 'vacant'

  @override
  void initState() {
    super.initState();
    // Ensure database profile exists if role is already in metadata
    // This fixes users who might be in a "half-created" state due to missing RLS earlier.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = AppLocalizations.of(context)!;
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        final profile = await ref.read(profileFutureProvider.future);
        final dbRole = profile?['role'] as String?;
        final metaRole = user.userMetadata?['role'] as String?;
        final fullName = profile?['full_name'] ?? user.userMetadata?['full_name'] as String?;

        if (dbRole == 'agency' || metaRole == 'agency') {
          if (mounted) context.go('/agency-dashboard');
          return;
        }

        final effectiveRole = dbRole ?? metaRole;
        if (effectiveRole != null) {
          ref.read(authRepositoryProvider)
            .updateProfile(role: effectiveRole, fullName: fullName)
            .catchError((e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(loc.syncError(e.toString())),
                  backgroundColor: StanomerColors.alertPrimary,
                ));
              }
            });
        }
      } catch (_) {}
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
        bottom: screenWidth >= 850
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildDesktopHeaderNav(context, loc, role ?? 'tenant'),
              )
            : null,
      ),
      floatingActionButton: () {
        if (zzplDocumentVersion == null) return null;
        
        if (propertiesAsync.hasValue) {
          final properties = propertiesAsync.value!;
          if (isLandlord) {
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
            
            return FloatingActionButton.extended(
              onPressed: () {
                final hasRequests = requestsAsync.value != null && requestsAsync.value!.isNotEmpty;
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
              icon: const Icon(LucideIcons.wrench, color: Colors.white, size: 20),
              label: Text(
                loc.reportIssue,
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
                              ] else if (isLandlord) ...[
                                if (propertiesAsync.hasValue) ...[
                                  () {
                                    final properties = propertiesAsync.value!;
                                    final totalUnits = properties.length;
                                    final totalTenants = properties.where((p) => p.tenantId != null).length;
                                    final statsAsync = ref.watch(landlordSummaryProvider);

                    // Tab 3: Bakım & Onarım — navigate to maintenance screen
                    if (_landlordCurrentTab == 3) {
                      if (properties.isEmpty) {
                        return _LandlordEmptyState(
                          onAction: () => context.push('/add-property'),
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
                        // ── Pending invitations (if any) ──────────────────────
                        if (pendingInvitesAsync.hasValue && pendingInvitesAsync.value!.isNotEmpty) ...[
                          ...pendingInvitesAsync.value!.map((invite) {
                            final p = invite['properties'] as Map<String, dynamic>?;
                            if (p == null) return const SizedBox.shrink();
                            return _InvitationCard(invite: invite, propertyData: p);
                          }),
                          const SizedBox(height: 12),
                        ],
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
                                onAction: () => context.push('/add-property'),
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
                                  loc.localeName == 'tr'
                                      ? 'Bu filtreye uygun mülk bulunamadı.'
                                      : 'No properties found for this filter.',
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
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  mainAxisExtent: 250,
                                ),
                                itemCount: filteredProperties.length,
                                itemBuilder: (context, index) => _LandlordPropertyCard(property: filteredProperties[index]),
                              );
                            }
                            return Column(
                              children: filteredProperties.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _LandlordPropertyCard(property: p),
                              )).toList(),
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
                    final invites = pendingInvitesAsync.value!;
                    final properties = propertiesAsync.value!;
                    final tenantProperties = properties.where((p) => p.tenantId == user?.id).toList();

                    if (invites.isEmpty && tenantProperties.isEmpty) {
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
                        // ── 0. Pending invitations (if any) ──────────────────
                        ...invites.map((invite) {
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
                                    _TenantPropertyCard(property: property),
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
                                  // ── 1. Hero — Toplam Borç ─────────────────
                                  InkWell(
                                    onTap: () => context.push('/property-detail', extra: property),
                                    borderRadius: BorderRadius.circular(16),
                                    child: _TenantHero(
                                      property: property,
                                      contract: contract,
                                      financialStatus: financialStatus,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // ── 2. Awaiting summary card (only if relevant) ─
                                  if (financialStatus != null && financialStatus.awaitingCount > 0)
                                    _TenantAwaitingCard(
                                      financialStatus: financialStatus,
                                      awaitingPayments: awaitingPayments,
                                      onTap: () => context.push('/property-detail', extra: {
                                        'property': property,
                                        'initialTabIndex': 1,
                                      }),
                                    ),

                                  const SizedBox(height: 20),

                                  // ── 3. My Properties ──────────────────────
                                  _SectionHeader(
                                    title: loc.myProperties,
                                    count: tenantProperties.length,
                                  ),
                                  const SizedBox(height: 12),
                                  ...tenantProperties.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TenantPropertyCard(property: p),
                                  )),

                                  const SizedBox(height: 20),

                                  // ── 4. Payment History ────────────────────
                                  Row(
                                    children: [
                                      Text(
                                        loc.paymentHistory,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF333333),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => context.push('/property-detail', extra: {
                                          'property': property,
                                          'initialTabIndex': 1,
                                        }),
                                        child: Text(
                                          loc.viewAll,
                                          style: const TextStyle(
                                            color: StanomerColors.tenant,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _PropertyHistoryList(propertyId: property.id, limit: 5),
                                  const SizedBox(height: 16),
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
                // Onboarding Card for Initial Role Selection
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.only(top: 60),
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
                        const SizedBox(height: 32),
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
                ),
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

  Widget _buildDesktopHeaderNav(BuildContext context, AppLocalizations loc, String role) {
    final isLandlord = role == 'landlord';
    final primaryColor = StanomerColors.getRoleColor(role);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Row(
            children: [
              _buildDesktopHeaderTabItem(
                icon: LucideIcons.layoutDashboard,
                label: loc.localeName == 'tr' ? 'Ana Panel' : 'Dashboard',
                isSelected: true,
                primaryColor: primaryColor,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              if (isLandlord) ...[
                _buildDesktopHeaderTabItem(
                  icon: LucideIcons.plusCircle,
                  label: loc.addProperty,
                  isSelected: false,
                  primaryColor: primaryColor,
                  onTap: () => context.push('/add-property'),
                ),
                const SizedBox(width: 12),
              ],
              _buildDesktopHeaderTabItem(
                icon: LucideIcons.wrench,
                label: loc.localeName == 'tr' ? 'Bakım ve Onarım' : 'Maintenance',
                isSelected: false,
                primaryColor: primaryColor,
                onTap: () => context.push('/maintenance'),
              ),
              const SizedBox(width: 12),
              _buildDesktopHeaderTabItem(
                icon: LucideIcons.settings,
                label: loc.settingsHeader,
                isSelected: false,
                primaryColor: primaryColor,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeaderTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? primaryColor : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.black87,
                ),
              ),
            ],
          ),
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
      ref.read(agencyBrandingProvider.notifier).clear();
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
                        sublabel: loc.localeName == 'tr' ? 'Toplam Mülk' : 'Properties',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.users,
                        iconColor: const Color(0xFF34D399),
                        label: loc.tenantsLabel,
                        value: '$totalTenants',
                        sublabel: loc.localeName == 'tr' ? 'Kiracı Aktif' : 'Active Tenants',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStatDeckTile(
                        icon: LucideIcons.pieChart,
                        iconColor: const Color(0xFFFBBF24),
                        label: loc.localeName == 'tr' ? 'Doluluk' : 'Occupancy',
                        value: '%$occupancyRate',
                        sublabel: loc.localeName == 'tr' ? 'Portföy Oranı' : 'Portfolio Rate',
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
            sublabel: loc.localeName == 'tr' ? 'Toplanan Kira' : 'Collected Rent',
            accentColor: const Color(0xFF059669), // Emerald
            surfaceColor: const Color(0xFFECFDF5),
          ),
          _KpiCard(
            icon: LucideIcons.clock,
            value: '${stats.awaitingApprovalCount}',
            label: loc.awaitingApproval,
            sublabel: loc.localeName == 'tr' ? 'Dekont Onayı' : 'Awaiting Approval',
            accentColor: const Color(0xFFD97706), // Amber
            surfaceColor: const Color(0xFFFFFBEB),
            isAlert: hasAwaiting,
          ),
          _KpiCard(
            icon: LucideIcons.alertTriangle,
            value: '${stats.delaysCount}',
            label: loc.delays,
            sublabel: loc.localeName == 'tr' ? 'Vadesi Geçmiş' : 'Overdue Payments',
            accentColor: const Color(0xFFE11D48), // Rose
            surfaceColor: const Color(0xFFFFF1F2),
            isAlert: hasDelays,
          ),
          _KpiCard(
            icon: LucideIcons.doorOpen,
            value: '${stats.vacantCount}',
            label: loc.vacant,
            sublabel: loc.localeName == 'tr' ? 'Kiracıya Müsait' : 'Vacant Units',
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
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
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
      padding: const EdgeInsets.all(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DİKKAT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
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
        final hasDelays = stats.delaysCount > 0;

        if (!hasAwaiting && !hasDelays) {
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
                    loc.localeName == 'tr'
                        ? 'Tüm mülkler ve ödemeler güncel durumda. Bekleyen onay bulunmuyor.'
                        : 'All properties and payments are up to date.',
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
                              Text(
                                '${stats.awaitingApprovalCount} ${loc.awaitingApproval}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              if (property != null) ...[
                                const SizedBox(width: 6),
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
                        loc.localeName == 'tr' ? 'İncele' : 'Review',
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
                        '${stats.delaysCount} ${loc.delays.toLowerCase()} bulunuyor. Detayları mülk listesinden kontrol edebilirsiniz.',
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
            label: loc.localeName == 'tr' ? 'Tümü' : 'All',
            count: totalCount,
            isSelected: currentFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: loc.localeName == 'tr' ? 'Kirada' : 'Rented',
            count: rentedCount,
            isSelected: currentFilter == 'rented',
            onTap: () => onFilterChanged('rented'),
            badgeColor: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: loc.vacant,
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

    final viewDetailsLabel = loc.localeName == 'tr'
        ? 'Detaylar'
        : loc.localeName.startsWith('sr')
            ? 'Detalji'
            : loc.localeName == 'ru'
                ? 'Детали'
                : 'Details';

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
                                loc.localeName == 'tr' ? 'Davet Bekleniyor' : 'Invited',
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
                              isVacant ? loc.vacant : (loc.localeName == 'tr' ? 'Kiracı Var' : 'Rented'),
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
                            loc.localeName == 'tr'
                                ? 'Aktif kontrat yok. Kiracı davet etmek için tıklayın.'
                                : 'No active contract. Tap to invite tenant.',
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
                    Row(
                      children: [
                        if (state.rentStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _StatusPill(
                              label: '${loc.rent}: ${state.rentStatus == RentStatus.debt ? loc.debtLabel.toUpperCase() : (state.rentStatus == RentStatus.awaitingApproval ? loc.waiting.toUpperCase() : loc.paidLabel.toUpperCase())}',
                              color: state.rentStatus == RentStatus.debt ? const Color(0xFFFFF1F2) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                              textColor: state.rentStatus == RentStatus.debt ? const Color(0xFFE11D48) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFFD97706) : const Color(0xFF059669)),
                            ),
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
                const Spacer(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFFECFDF5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 6),
                // Maintenance Quick Jump Button
                TextButton.icon(
                  onPressed: () => context.push('/property-detail', extra: {
                    'property': property,
                    'initialTabIndex': 2,
                  }),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFFEEF2FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
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
  final VoidCallback onAction;
  const _LandlordEmptyState({required this.onAction});
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
          Text(loc.addYourFirstProperty, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
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
    final hasPendingBills = financialStatus?.billStatus == BillStatus.waitingForLandlord;
    final isAllPaid = !hasDebt && !hasCredit && !hasAwaiting && (financialStatus?.paidCount ?? 0) > 0;
    final isOverdue = rentStatus == RentStatus.debt ||
        financialStatus?.billStatus == BillStatus.debt;

    final agencyColors = ref.watch(agencyColorSchemeProvider);

    // Hero rengi
    final Color heroColor;
    if (isOverdue || hasDebt) {
      heroColor = const Color(0xFFC0392B); // Kırmızı (Borçlu)
    } else if (hasCredit) {
      heroColor = const Color(0xFF2563EB); // Mavi (Mahsup Alacağı)
    } else if (hasAwaiting) {
      heroColor = const Color(0xFFD97706); // Turuncu (Onay Bekliyor)
    } else if (isAllPaid) {
      heroColor = const Color(0xFF0F6E56); // Yeşil (Tamamı Ödendi)
    } else {
      heroColor = agencyColors.primary;
    }

    // Hangi tutarları göster?
    final String heroLabel;
    if (hasDebt) {
      heroLabel = loc.totalDebt.toUpperCase();
    } else if (hasCredit) {
      heroLabel = (loc.localeName == 'tr' ? 'MAHSUP ALACAĞI' : 'SETTLEMENT CREDIT').toUpperCase();
    } else if (hasAwaiting) {
      heroLabel = loc.awaitingHeader.toUpperCase();
    } else {
      heroLabel = loc.totalDebt.toUpperCase();
    }

    final hasAgency = (property.agencyId != null && property.agencyId!.isNotEmpty) || (contract.agencyId != null && contract.agencyId!.isNotEmpty);

    // Status badge
    Widget? statusBadge;
    if (isOverdue || hasDebt) {
      statusBadge = _HeroStatusBadge(
        icon: LucideIcons.alertTriangle,
        label: loc.debtLabel,
        bgColor: Colors.white.withValues(alpha: 0.2),
        textColor: Colors.white,
      );
    } else if (hasCredit) {
      statusBadge = _HeroStatusBadge(
        icon: LucideIcons.arrowDownLeft,
        label: loc.localeName == 'tr' ? 'Mahsup Alacağı' : 'Credit',
        bgColor: Colors.white.withValues(alpha: 0.2),
        textColor: Colors.white,
      );
    } else if (hasAwaiting) {
      statusBadge = _HeroStatusBadge(
        icon: LucideIcons.clock,
        label: hasAgency ? loc.waitingForAgencyApproval : loc.waitingForOwnerApproval,
        bgColor: Colors.white.withValues(alpha: 0.2),
        textColor: Colors.white,
      );
    } else {
      statusBadge = _HeroStatusBadge(
        icon: LucideIcons.circleCheck,
        label: loc.localeName == 'tr' ? 'Borç Yok' : 'No Debt',
        bgColor: Colors.white.withValues(alpha: 0.2),
        textColor: Colors.white,
      );
    }

    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? (user?.email != null ? user!.email!.split('@').first : '');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: heroColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.07,
              child: const Icon(LucideIcons.home, size: 120, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userName.isNotEmpty) ...[
                  Text(
                    loc.welcomeUser(userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      heroLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (statusBadge != null) statusBadge,
                  ],
                ),
                const SizedBox(height: 6),
                // Multi-currency tutarları satır satır göster
                ...() {
                  final Map<String, double> totals;
                  if (hasDebt || hasCredit) {
                    totals = pendingTotals;
                  } else if (hasAwaiting) {
                    totals = awaitingTotals;
                  } else {
                    final defaultCurrency = contract.currency.isNotEmpty ? contract.currency : 'RSD';
                    totals = pendingTotals.isEmpty ? {defaultCurrency: 0.0} : pendingTotals;
                  }
                  final currencies = totals.keys.toList()..sort();
                  if (currencies.isEmpty) {
                    return [
                      const Text('0,00',
                          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
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
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '+ ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          CurrencyUtils.formatAmount(amount, cur, useSymbol: true),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isFirst ? 30 : 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                }(),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroMetaItem(
                      icon: LucideIcons.home,
                      value: property.name,
                      label: '',
                    ),
                    const SizedBox(height: 6),
                    _HeroMetaItem(
                      icon: LucideIcons.calendar,
                      value: DateFormat('dd MMM', loc.localeName).format(dueDate),
                      label: loc.dueDayOfMonth.toLowerCase(),
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

class _HeroMetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetaItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(
            label.toLowerCase(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _HeroStatusBadge({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantPaymentCard extends ConsumerWidget {
  final Property property;
  final Contract contract;
  final PropertyFinancialState financialStatus;

  const _TenantPaymentCard({
    required this.property,
    required this.contract,
    required this.financialStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final agencyColors = ref.watch(agencyColorSchemeProvider);
    final accentColor = agencyColors.primary;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.nextPayment,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.upcomingLabel,
                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyUtils.formatAmount(contract.monthlyRent, contract.currency, useSymbol: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: StanomerColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            loc.dueOn(DateFormat('MMMM dd, yyyy').format(DateTime.now().add(const Duration(days: 15)))), // Placeholder logic
            style: const TextStyle(color: StanomerColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric(
                label: loc.pendingHeader,
                value: CurrencyUtils.formatCurrencyMap(financialStatus.pendingTotals, useSymbols: true),
                count: financialStatus.pendingCount,
                color: StanomerColors.textTertiary,
                loc: loc,
              ),
              _buildMetric(
                label: loc.awaitingHeader,
                value: CurrencyUtils.formatCurrencyMap(financialStatus.awaitingTotals, useSymbols: true),
                count: financialStatus.awaitingCount,
                color: Colors.orange,
                loc: loc,
              ),
              _buildMetric(
                label: loc.paidHeader,
                value: CurrencyUtils.formatCurrencyMap(financialStatus.paidTotals, useSymbols: true),
                count: financialStatus.paidCount,
                color: accentColor,
                loc: loc,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/property-detail', extra: {
                'property': property,
                'initialTabIndex': 1,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                loc.payNow,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required int count,
    required Color color,
    required AppLocalizations loc,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: StanomerColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '€0' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color == StanomerColors.textTertiary ? StanomerColors.textPrimary : color,
            ),
          ),
          Text(
            '$count ${count == 1 ? loc.item : loc.items}',
            style: const TextStyle(
              fontSize: 10,
              color: StanomerColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
class _TenantAwaitingCard extends StatelessWidget {
  final PropertyFinancialState financialStatus;
  final List<RentPayment> awaitingPayments;
  final VoidCallback onTap;

  const _TenantAwaitingCard({
    required this.financialStatus,
    required this.awaitingPayments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final awaitingVal = CurrencyUtils.formatCurrencyMap(
        financialStatus.awaitingTotals, useSymbols: true, separator: ' + ');

    // Group by title to show types
    final typeGroups = <String, int>{};
    for (final p in awaitingPayments) {
      typeGroups[p.title] = (typeGroups[p.title] ?? 0) + 1;
    }
    final typesSummary = typeGroups.entries
        .map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFAC775)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAC775),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.clock, size: 16, color: Color(0xFF633806)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${financialStatus.awaitingCount} ${loc.awaitingHeader}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF854F0B),
                        ),
                      ),
                      if (typesSummary.isNotEmpty)
                        Text(
                          typesSummary,
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
                Text(
                  awaitingVal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF854F0B),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF854F0B)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFFEEFC3)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(LucideIcons.alertCircle, size: 12, color: Color(0xFFA0621A)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.awaitingExplanation,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: Color(0xFFA0621A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _PropertyCard extends ConsumerWidget {
  final Property property;
  final bool isLandlord;

  const _PropertyCard({
    required this.property,
    this.isLandlord = true,
  });

  Future<void> _deleteProperty(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDeleteTitle),
        content: Text(loc.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.propertyDeletedSuccess)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final financialStatusAsync = ref.watch(propertyFinancialStatusProvider(property.id));

    final brandingState = ref.watch(agencyBrandingProvider);
    final agencyColors = ref.watch(agencyColorSchemeProvider);
    final accentColor = brandingState.hasAgencyBranding
        ? agencyColors.primary
        : (isLandlord ? StanomerColors.landlord : StanomerColors.tenant);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StanomerShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/property-detail', extra: property),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status strip
              financialStatusAsync.when(
                data: (state) {
                  Color color;
                  if (state.generalStatus != null) {
                    color = state.generalStatus == PropertyFinancialStatus.vacant 
                      ? Colors.grey.withValues(alpha: 0.3) 
                      : Colors.orange;
                  } else {
                    final isHealthy = state.rentStatus == RentStatus.paid && state.billStatus == BillStatus.paid;
                    final hasDebt = state.rentStatus == RentStatus.debt || state.billStatus == BillStatus.debt;
                    
                    if (hasDebt) {
                      color = StanomerColors.alertPrimary;
                    } else if (isHealthy) {
                      color = accentColor;
                    } else {
                      color = Colors.orange;
                    }
                  }
                  return Container(width: 6, color: color);
                },
                loading: () => Container(width: 6, color: Colors.grey.withValues(alpha: 0.1)),
                error: (_, __) => Container(width: 6, color: Colors.grey.withValues(alpha: 0.1)),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 10, color: StanomerColors.textTertiary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        property.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: StanomerColors.textTertiary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          activeContractAsync.when(
                            data: (contract) {
                              final rent = contract?.monthlyRent ?? property.defaultMonthlyRent;
                              final currency = contract?.currency ?? property.currency;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyUtils.formatAmount(rent, currency, useSymbol: true),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: accentColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    loc.totalRentShort.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: StanomerColors.textTertiary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      if (!isLandlord) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Landlord Info
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.user, size: 12, color: StanomerColors.textTertiary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      property.landlordName ?? loc.owner,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: StanomerColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Date Info
                            activeContractAsync.when(
                              data: (contract) {
                                if (contract?.startDate == null) return const SizedBox.shrink();
                                final startStr = DateFormat('dd.MM.yyyy').format(contract!.startDate!);
                                final endStr = contract.endDate != null 
                                    ? DateFormat('dd.MM.yyyy').format(contract.endDate!) 
                                    : '∞';
                                return Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: StanomerColors.textTertiary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$startStr - $endStr',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: StanomerColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: financialStatusAsync.when(
                              data: (state) {
                                if (state.generalStatus != null) {
                                  if (state.generalStatus == PropertyFinancialStatus.vacant) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildStatusBadge(label: loc.vacant, color: Colors.grey),
                                        if (isLandlord) ...[
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () => context.push('/invite-tenant', extra: {'property': property}),
                                            icon: const Icon(LucideIcons.userPlus, size: 14),
                                            label: Text(loc.addContractAndTenant, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accentColor,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                  if (state.generalStatus == PropertyFinancialStatus.negotiating) {
                                    return _buildStatusBadge(label: loc.statusNegotiating, color: Colors.orange);
                                  }
                                  if (state.generalStatus == PropertyFinancialStatus.invitationSent) {
                                    return _buildStatusBadge(label: loc.contractSentToTenant, color: Colors.orange);
                                  }
                                  return _buildStatusBadge(label: loc.pendingApproval, color: Colors.orange);
                                }

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    // Termination / Ended Badge
                                    if (activeContractAsync.value != null && (activeContractAsync.value!.isEnded || activeContractAsync.value!.terminationApproved))
                                      _buildStatusBadge(
                                        label: activeContractAsync.value!.isEnded 
                                            ? loc.ended
                                            : loc.plannedEnd(DateFormat('dd/MM').format(activeContractAsync.value!.endDate!)),
                                        color: activeContractAsync.value!.isEnded ? StanomerColors.textTertiary : Colors.orange,
                                      ),
                                    // Rent Badge
                                    if (activeContractAsync.value != null && !activeContractAsync.value!.isEnded)
                                      _buildStatusBadge(
                                        prefix: loc.rent,
                                        label: state.rentStatus == RentStatus.debt ? loc.debtLabel : (state.rentStatus == RentStatus.awaitingApproval ? loc.paymentAwaitingApproval : loc.paidLabel),
                                        color: state.rentStatus == RentStatus.debt ? StanomerColors.alertPrimary : (state.rentStatus == RentStatus.awaitingApproval ? Colors.orange : accentColor),
                                      ),
                                    // Bills Badge
                                    if (activeContractAsync.value != null && !activeContractAsync.value!.isEnded && activeContractAsync.value!.expensesConfig.isNotEmpty)
                                      _buildStatusBadge(
                                        prefix: loc.bills,
                                        label: state.billStatus == BillStatus.debt ? loc.debtLabel : (state.billStatus == BillStatus.awaitingApproval ? loc.paymentAwaitingApproval : (state.billStatus == BillStatus.waitingForLandlord ? loc.waiting : loc.paidLabel)),
                                        color: state.billStatus == BillStatus.debt ? StanomerColors.alertPrimary : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? Colors.orange : accentColor),
                                      ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          if (isLandlord)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 16, color: StanomerColors.textTertiary),
                                  onPressed: () => _deleteProperty(context, ref),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 8),
                                Icon(LucideIcons.chevronRight, size: 16, color: accentColor),
                              ],
                            )
                          else
                            Icon(LucideIcons.chevronRight, size: 16, color: accentColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantPropertyCard extends ConsumerWidget {
  final Property property;

  const _TenantPropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final activeContractAsync = ref.watch(activeContractProvider(property.id));

    return activeContractAsync.when(
      data: (contract) {
        final hasPendingProposal = contract?.status == ContractStatus.revisionRequested;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PropertyCard(property: property, isLandlord: false),
            if (hasPendingProposal)
              GestureDetector(
                onTap: () => context.push('/property-detail', extra: property),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 14, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.landlordProposedChanges,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 14, color: Colors.orange),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => _PropertyCard(property: property, isLandlord: false),
      error: (_, __) => _PropertyCard(property: property, isLandlord: false),
    );
  }
}

Widget _buildStatusBadge({
  required String label,
  required Color color,
  String? prefix,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null)
          Text(
            '$prefix: ',
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
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
