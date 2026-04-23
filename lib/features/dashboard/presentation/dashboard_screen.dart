import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/widgets/role_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../../property/data/property_repository.dart';
import '../../property/domain/property.dart';
import '../../property/domain/contract.dart';
import '../../property/domain/landlord_stats.dart';
import '../../../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/expense_utils.dart';

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

  @override
  void initState() {
    super.initState();
    // Ensure database profile exists if role is already in metadata
    // This fixes users who might be in a "half-created" state due to missing RLS earlier.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;
      final user = ref.read(currentUserProvider);
      final role = user?.userMetadata?['role'] as String?;
      final fullName = user?.userMetadata?['full_name'] as String?;
      
      if (role != null) {
        // Update to ensure DB row exists and is consistent
        ref.read(authRepositoryProvider)
          .updateProfile(role: role, fullName: fullName)
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(loc.syncError(e.toString())),
                backgroundColor: StanomerColors.alertPrimary,
              ));
            }
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final isLandlord = role == 'landlord';

    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitesForUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_no_bg.png',
              height: 28,
            ),
            const SizedBox(width: 10),
            Text(
              loc.appTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
        if (propertiesAsync.hasValue) {
          final properties = propertiesAsync.value!;
          if (isLandlord) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/add-property'),
              backgroundColor: StanomerColors.getRoleColor(role),
              elevation: 4,
              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
              label: Text(
                loc.addProperty.split(' ')[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            );
          } else if (role == 'tenant') {
            final tenantProperties = properties.where((p) => p.tenantId == user?.id).toList();
            if (tenantProperties.length != 1) return null;
            
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
              backgroundColor: StanomerColors.tenant,
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
            child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(propertiesStreamProvider);
          ref.invalidate(pendingInvitesForUserProvider);
          // Wait for the invites future to complete
          try {
            await ref.read(pendingInvitesForUserProvider.future);
          } catch (_) {}
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLandlord) ...[
                if (propertiesAsync.hasValue) ...[
                  () {
                    final properties = propertiesAsync.value!;
                    final totalUnits = properties.length;
                    final totalTenants = properties.where((p) => p.tenantId != null).length;
                    final statsAsync = ref.watch(landlordSummaryProvider);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LandlordHero(
                          statsAsync: statsAsync,
                          totalUnits: totalUnits,
                          totalTenants: totalTenants,
                        ),
                        const SizedBox(height: 12),
                        _KpiGrid(statsAsync: statsAsync),
                        const SizedBox(height: 12),
                        statsAsync.when(
                          data: (stats) {
                            final propertyId = stats.latestAwaitingPropertyId;
                            final property = properties.where((p) => p.id == propertyId).firstOrNull;
                            return _ActionBanner(
                              count: stats.awaitingApprovalCount,
                              latestTitle: stats.latestAwaitingTitle,
                              property: property,
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }(),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: loc.myProperties,
                    count: propertiesAsync.value!.length,
                  ),
                  const SizedBox(height: 12),
                  () {
                    final properties = propertiesAsync.value!;
                    if (properties.isEmpty) {
                      return _LandlordEmptyState(
                        onAction: () => context.push('/add-property'),
                      );
                    }
                    return Column(
                      children: properties.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LandlordPropertyCard(property: p),
                      )).toList(),
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
                Text(
                  loc.myProperties,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Combined view of Invites + Accepted Properties
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

                    // Safely constrain index before returning UI
                    if (_selectedTenantPropertyIndex >= tenantProperties.length) {
                      _selectedTenantPropertyIndex = 0;
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Show Invites first
                        ...invites.map((invite) {
                          final p = invite['properties'] as Map<String, dynamic>?;
                          if (p == null) return const SizedBox.shrink();
                          return _InvitationCard(invite: invite, propertyData: p);
                        }),
                        
                        if (tenantProperties.isNotEmpty) ...[
                          if (tenantProperties.length > 1) ...[
                            _buildPropertyTabs(tenantProperties),
                            const SizedBox(height: 16),
                          ],

                          Consumer(
                            builder: (context, ref, _) {
                              final property = tenantProperties[_selectedTenantPropertyIndex];
                              final contractAsync = ref.watch(activeContractProvider(property.id));
                              final financialStatusAsync = ref.watch(propertyFinancialStatusProvider(property.id));
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (contractAsync.hasValue) ...[
                                    () {
                                      final contract = contractAsync.value;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          if (contract != null) ...[
                                            InkWell(
                                              onTap: () => context.push('/property-detail', extra: property),
                                              borderRadius: BorderRadius.circular(24),
                                              child: _TenantHero(property: property, contract: contract),
                                            ),
                                            const SizedBox(height: 24),
                                            if (financialStatusAsync.hasValue) 
                                              _TenantPaymentCard(
                                                property: property,
                                                contract: contract,
                                                financialStatus: financialStatusAsync.value!,
                                              ),
                                            const SizedBox(height: 32),
                                            // Payment History Section
                                            Row(
                                              children: [
                                                Text(
                                                  loc.paymentHistory,
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 22,
                                                    letterSpacing: -0.5,
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
                                                    style: const TextStyle(color: StanomerColors.tenant, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            // Quick list of last 3 payments (mock or derived)
                                            _PropertyHistoryList(propertyId: property.id, limit: 5),
                                          ] else ...[
                                            // User has property but contract is not active yet
                                            _TenantPropertyCard(property: property),
                                          ],
                                        ],
                                      );
                                    }(),
                                  ] else if (contractAsync.hasError) ...[
                                    AppErrorView(
                                      error: contractAsync.error!,
                                      onRetry: () => ref.invalidate(activeContractProvider(property.id)),
                                    ),
                                  ] else ...[
                                    const Center(child: CircularProgressIndicator()),
                                  ],
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
  ],
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
      backgroundColor: Colors.transparent,
      builder: (context) => RoleSwitcherBottomSheet(
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
    );
  }

  Future<void> _updateRole(String role) async {
    setState(() => _roleSelectionLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(role: role);
      // Success snackbar is not strictly needed as UI will update via currentUserProvider
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
                  color: isSelected ? StanomerColors.tenant : StanomerColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? StanomerColors.tenant : StanomerColors.borderDefault,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: StanomerColors.tenant.withValues(alpha: 0.2),
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

class _LandlordHero extends StatelessWidget {
  final AsyncValue<LandlordDashboardStats> statsAsync;
  final int totalUnits;
  final int totalTenants;

  const _LandlordHero({
    required this.statsAsync,
    required this.totalUnits,
    required this.totalTenants,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', loc.localeName).format(now);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A5FA8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5FA8).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative Background Icon
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(LucideIcons.home, size: 110, color: Colors.white),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc.monthlyCollected} ($monthName)'.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                statsAsync.when(
                  data: (stats) => Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: _buildAmountSpans(stats.collectedByCurrency),
                  ),
                  loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 30)),
                  error: (_, __) => const Text('0,00 €', style: TextStyle(color: Colors.white, fontSize: 30)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroMetaItem(
                      icon: LucideIcons.home,
                      value: totalUnits.toString(),
                      label: loc.units,
                    ),
                    const SizedBox(width: 16),
                    _HeroMetaItem(
                      icon: LucideIcons.users,
                      value: totalTenants.toString(),
                      label: loc.tenantsLabel,
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
      return [const Text('0,00 €', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500))];
    }
    
    final sortedCurrencies = collected.keys.toList()..sort(); // EUR first usually
    final List<Widget> spans = [];
    
    for (int i = 0; i < sortedCurrencies.length; i++) {
      final cur = sortedCurrencies[i];
      final amount = collected[cur]!;
      final isFirst = i == 0;
      
      if (!isFirst) {
        spans.add(Text('+', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)));
      }
      
      spans.add(Text(
        CurrencyUtils.formatAmount(amount, cur, useSymbol: true),
        style: TextStyle(
          color: isFirst ? Colors.white : Colors.white.withOpacity(0.85),
          fontSize: isFirst ? 30 : 22,
          fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
        ),
      ));
    }
    
    return spans;
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
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 3),
        Text(
          label.toLowerCase(),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AsyncValue<LandlordDashboardStats> statsAsync;

  const _KpiGrid({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: [
          _KpiCard(
            icon: LucideIcons.wallet,
            value: CurrencyUtils.formatCurrencyMap(stats.collectedByType['Kira'] ?? {}, useSymbols: true),
            label: loc.rent,
            valueColor: const Color(0xFF0F6E56),
          ),
          _KpiCard(
            icon: LucideIcons.clock,
            value: stats.delaysCount.toString(),
            label: loc.delays,
            valueColor: stats.delaysCount > 0 ? const Color(0xFFA32D2D) : null,
            iconColor: stats.delaysCount > 0 ? const Color(0xFFE24B4A) : null,
          ),
          _KpiCard(
            icon: LucideIcons.layout,
            value: stats.vacantCount.toString(),
            label: loc.vacant,
          ),
        ],
      ),
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;
  final Color? iconColor;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: iconColor ?? const Color(0xFF999999)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF333333),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF999999),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final int count;
  final String? latestTitle;
  final Property? property;

  const _ActionBanner({required this.count, this.latestTitle, this.property});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFAC775)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFAC775),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.clock, size: 16, color: Color(0xFF633806)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.awaitingApproval,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF633806)),
                ),
                if (latestTitle != null)
                  Text(
                    latestTitle!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF854F0B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              if (property != null) {
                context.push('/property-detail', extra: {
                  'property': property!,
                  'initialTabIndex': 1,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5FA8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(loc.localeName == 'tr' ? 'İncele' : 'View Detail', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              loc.viewAll,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1A5FA8)),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/property-detail', extra: property),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vertical Accent
              financialStatusAsync.when(
                data: (state) {
                  final isDebt = state.rentStatus == RentStatus.debt || state.billStatus == BillStatus.debt;
                  return Container(
                    width: 4,
                    color: isDebt ? const Color(0xFFE24B4A) : const Color(0xFF2DB87A),
                  );
                },
                loading: () => Container(width: 4, color: Colors.grey[200]),
                error: (_, __) => Container(width: 4, color: Colors.grey[200]),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF999999)),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        property.address,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
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
                          activeContractAsync.when(
                            data: (contract) => Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyUtils.formatAmount(contract?.monthlyRent ?? property.defaultMonthlyRent, contract?.currency ?? property.currency, useSymbol: true),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A5FA8)),
                                ),
                                Text(
                                  loc.totalRentShort.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF999999), letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      
                      financialStatusAsync.when(
                        data: (state) {
                          if (state.generalStatus == PropertyFinancialStatus.vacant) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  _StatusPill(label: loc.vacant, color: Colors.grey[400]!, textColor: Colors.white),
                                ],
                              ),
                            );
                          }

                          final total = (state.paidCount + state.pendingCount + state.awaitingCount);
                          final progress = total > 0 ? (state.paidCount / total) : 0.0;
                          
                          return Column(
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: progress < 1.0 ? const Color(0xFFEF9F27) : const Color(0xFF2DB87A),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.paidCount} / $total ${loc.paidLabel.toLowerCase()}',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (state.rentStatus != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: _StatusPill(
                                        label: '${loc.rent}: ${state.rentStatus == RentStatus.debt ? loc.debtLabel.toUpperCase() : (state.rentStatus == RentStatus.awaitingApproval ? loc.waiting.toUpperCase() : loc.paidLabel.toUpperCase())}',
                                        color: state.rentStatus == RentStatus.debt ? const Color(0xFFFCEBEB) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFFFAEEDA) : const Color(0xFFEAF3DE)),
                                        textColor: state.rentStatus == RentStatus.debt ? const Color(0xFFA32D2D) : (state.rentStatus == RentStatus.awaitingApproval ? const Color(0xFF854F0B) : const Color(0xFF3B6D11)),
                                      ),
                                    ),
                                  if (state.billStatus != null)
                                    _StatusPill(
                                      label: '${loc.bills}: ${state.billStatus == BillStatus.debt ? loc.debtLabel.toUpperCase() : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? loc.waiting.toUpperCase() : loc.paidLabel.toUpperCase())}',
                                      color: state.billStatus == BillStatus.debt ? const Color(0xFFFCEBEB) : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? const Color(0xFFFAEEDA) : const Color(0xFFEAF3DE)),
                                      textColor: state.billStatus == BillStatus.debt ? const Color(0xFFA32D2D) : (state.billStatus == BillStatus.awaitingApproval || state.billStatus == BillStatus.waitingForLandlord ? const Color(0xFF854F0B) : const Color(0xFF3B6D11)),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons Column
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SmallIconButton(
                      icon: LucideIcons.chevronRight,
                      onTap: () => context.push('/property-detail', extra: property),
                    ),
                    const SizedBox(height: 6),
                    _SmallIconButton(
                      icon: LucideIcons.trash2,
                      onTap: () => _deleteProperty(context, ref, property),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

        return Container(
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
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(LucideIcons.home, size: 48, color: Color(0xFF1A5FA8)),
          const SizedBox(height: 24),
          Text(loc.noProperties, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(loc.addYourFirstProperty, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onAction, child: Text(loc.addProperty)),
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

class _TenantEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _TenantEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(StanomerRadius.xl),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.mail, size: 48, color: StanomerColors.textTertiary),
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
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(loc.refresh),
          ),
        ],
      ),
    );
  }
}

class _TenantHero extends StatelessWidget {
  final Property property;
  final Contract contract;

  const _TenantHero({required this.property, required this.contract});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StanomerColors.tenant,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StanomerColors.tenant,
            const Color(0xFF1D8A5A), // Darker green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: StanomerColors.tenant.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(LucideIcons.home, size: 150, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.yourApartment.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        property.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(
                            '${loc.contract}: ${DateFormat('dd MMM yyyy', loc.localeName).format(contract.startDate!)}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.5), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantPaymentCard extends StatelessWidget {
  final Property property;
  final Contract contract;
  final PropertyFinancialState financialStatus;

  const _TenantPaymentCard({
    required this.property,
    required this.contract,
    required this.financialStatus,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StanomerColors.tenant.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: StanomerColors.tenant.withValues(alpha: 0.05),
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
                  color: StanomerColors.tenant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.upcomingLabel,
                  style: const TextStyle(color: StanomerColors.tenant, fontSize: 10, fontWeight: FontWeight.bold),
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
                color: StanomerColors.tenant,
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
                backgroundColor: StanomerColors.tenant,
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

    final accentColor = isLandlord ? StanomerColors.landlord : StanomerColors.tenant;

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

