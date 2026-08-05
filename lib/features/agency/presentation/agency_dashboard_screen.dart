// lib/features/agency/presentation/agency_dashboard_screen.dart
//
// Refactored Agency Dashboard with 4-Tab Bottom Navigation Bar:
// 1. Ana Sayfa (Özet & Aksiyonlar, Harekete Geçirilebilir Mesajlar, Ödeme Onay Kuyruğu)
// 2. Finans (Ödemeler Raporu & İşlemleri)
// 3. Talepler (Arıza & Bakım Talepleri)
// 4. Portföy (Tüm Yönetilen Mülkler, Arama, Gruplama, Sıralama & Filtreleme)
//
// Global FAB: Mülk Ekle (+)

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/utils/expense_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/expandable_agency_logo.dart';
import '../../../core/widgets/powered_by_stanomer_footer.dart';
import '../../../core/widgets/desktop_navigation_shell.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../property/domain/property.dart';
import '../../property/domain/contract.dart';
import '../../property/domain/rent_payment.dart';
import '../../property/data/property_repository.dart';
import '../../property/presentation/widgets/ownership_share_sheet.dart';
import '../../notifications/presentation/widgets/notification_badge.dart';
import '../data/agency_repository.dart';
import '../domain/agency_color_scheme.dart';
import '../../maintenance/domain/maintenance_request.dart';
import '../../maintenance/data/maintenance_repository.dart';

// ---------------------------------------------------------------------------
// Actionable Insights Types & Helpers
// ---------------------------------------------------------------------------

enum ActionableInsightType {
  expiredContracts,
  expiringContracts,
  pendingApprovals,
  withoutContracts,
}

bool _matchesInsight(Property property, Contract? contract, ActionableInsightType insightType) {
  final now = DateTime.now();

  switch (insightType) {
    case ActionableInsightType.pendingApprovals:
      final isLandlordPending = property.landlordId == null;
      final isTenantPending = property.tenantId == null;
      final isContractPending = contract != null &&
          (contract.status == ContractStatus.pending || contract.status == ContractStatus.negotiating);
      return isLandlordPending || isTenantPending || isContractPending;

    case ActionableInsightType.withoutContracts:
      return contract == null;

    case ActionableInsightType.expiredContracts:
      if (contract == null) return false;
      if (contract.status == ContractStatus.expired) return true;
      if (contract.endDate != null && contract.endDate!.isBefore(now)) return true;
      return false;

    case ActionableInsightType.expiringContracts:
      if (contract == null) return false;
      if (contract.status != ContractStatus.active) return false;
      if (contract.endDate == null) return false;
      final daysRemaining = contract.endDate!.difference(now).inDays;
      return daysRemaining >= 0 && daysRemaining <= 30;
  }
}

class ActionableInsightConfig {
  final ActionableInsightType type;
  final String title;
  final String desc;
  final String action;
  final Color severityColor;
  final IconData icon;

  const ActionableInsightConfig({
    required this.type,
    required this.title,
    required this.desc,
    required this.action,
    required this.severityColor,
    required this.icon,
  });
}

ActionableInsightConfig getInsightConfig(
  ActionableInsightType type,
  AppLocalizations loc,
) {
  switch (type) {
    case ActionableInsightType.expiredContracts:
      return ActionableInsightConfig(
        type: type,
        title: loc.insightExpiredContractsTitle,
        desc: loc.insightExpiredContractsDesc,
        action: loc.insightExpiredContractsAction,
        severityColor: Colors.red,
        icon: LucideIcons.alertTriangle,
      );
    case ActionableInsightType.expiringContracts:
      return ActionableInsightConfig(
        type: type,
        title: loc.insightExpiringContractsTitle,
        desc: loc.insightExpiringContractsDesc,
        action: loc.insightExpiringContractsAction,
        severityColor: Colors.orange.shade800,
        icon: LucideIcons.clock,
      );
    case ActionableInsightType.pendingApprovals:
      return ActionableInsightConfig(
        type: type,
        title: loc.insightPendingApprovalsTitle,
        desc: loc.insightPendingApprovalsDesc,
        action: loc.insightPendingApprovalsAction,
        severityColor: Colors.blue.shade700,
        icon: LucideIcons.userCheck,
      );
    case ActionableInsightType.withoutContracts:
      return ActionableInsightConfig(
        type: type,
        title: loc.insightWithoutContractsTitle,
        desc: loc.insightWithoutContractsDesc,
        action: loc.insightWithoutContractsAction,
        severityColor: Colors.grey.shade700,
        icon: LucideIcons.filePlus,
      );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _getWebSafeImageUrl(String rawUrl) {
  final url = rawUrl.trim();
  if (url.isEmpty || !kIsWeb) return url;
  if (url.contains('supabase.co') || url.contains('localhost') || url.contains('127.0.0.1')) {
    return url;
  }
  final cleanUrl = url.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(cleanUrl)}';
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final agencyPropertiesProvider = StreamProvider<List<Property>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(propertyRepositoryProvider);
  final role = ref.watch(userRoleProvider) ?? 'landlord';
  return repo.getPropertiesStream(userId: user.id, role: role == 'landlord' ? 'landlord' : 'agency');
});

final agencyAllPaymentsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final propertiesAsync = ref.watch(agencyPropertiesProvider);
  final properties = propertiesAsync.value ?? [];
  if (properties.isEmpty) return Stream.value([]);

  final repo = ref.watch(propertyRepositoryProvider);
  return Rx.combineLatest<List<RentPayment>, List<Map<String, dynamic>>>(
    properties.map((p) => repo.getRentPaymentsStream(p.id)),
    (List<List<RentPayment>> allPaymentsList) {
      final List<Map<String, dynamic>> result = [];
      for (int i = 0; i < properties.length; i++) {
        final propMap = properties[i].toJson();
        for (final payment in allPaymentsList[i]) {
          final json = payment.toJson();
          json['property'] = propMap;
          json['property_id'] = properties[i].id;
          result.add(json);
        }
      }
      result.sort((a, b) {
        final dueAStr = a['due_date'] as String?;
        final dueBStr = b['due_date'] as String?;
        if (dueAStr == null || dueBStr == null) return 0;
        final dueA = DateTime.tryParse(dueAStr) ?? DateTime(1970);
        final dueB = DateTime.tryParse(dueBStr) ?? DateTime(1970);
        return dueB.compareTo(dueA);
      });
      return result;
    },
  );
});

final agencyPendingPaymentsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final allPaymentsAsync = ref.watch(agencyAllPaymentsProvider);
  final payments = allPaymentsAsync.value ?? [];
  return Stream.value(payments.where((item) => item['status'] == 'declared').toList());
});

final agencyContractsMapProvider = StreamProvider.autoDispose<Map<String, Contract?>>((ref) {
  final propertiesAsync = ref.watch(agencyPropertiesProvider);
  final properties = propertiesAsync.value ?? [];
  if (properties.isEmpty) return Stream.value({});

  final repo = ref.watch(propertyRepositoryProvider);
  return Rx.combineLatest<Contract?, Map<String, Contract?>>(
    properties.map((p) => repo.getActiveContractStream(p.id)),
    (List<Contract?> contracts) {
      final Map<String, Contract?> map = {};
      for (int i = 0; i < properties.length; i++) {
        map[properties[i].id] = contracts[i];
      }
      return map;
    },
  );
});

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

class AgencyDashboardScreen extends ConsumerStatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  ConsumerState<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends ConsumerState<AgencyDashboardScreen> {
  int _currentTab = 0; // 0: Ana Sayfa, 1: Portföy, 2: Finans, 3: Bakım

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterBy = 'all'; // 'all', 'has_debt', 'open_consent', 'occupied', 'vacant'
  ActionableInsightType? _selectedInsight;
  String _groupBy = 'none'; // 'none', 'landlord', 'city', 'status', 'debt_consent'
  String _sortBy = 'newest'; // 'newest', 'name_asc', 'city_asc', 'landlord_asc'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  Widget _buildNavIcon({
    required IconData icon,
    required int badgeCount,
    required Color color,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileFutureProvider);
    final profileData = profileAsync.value;
    final rawLogoUrl = profileData?['logo_url'] as String?;
    final companyName = (profileData?['company_name'] as String?)?.isNotEmpty == true
        ? profileData!['company_name'] as String
        : (profileData?['full_name'] as String? ?? 'Stanomer');

    final colors = ref.watch(agencyColorSchemeProvider);

    final String? logoUrl = rawLogoUrl != null && rawLogoUrl.trim().isNotEmpty
        ? _getWebSafeImageUrl(rawLogoUrl)
        : null;

    final propertiesAsync = ref.watch(agencyPropertiesProvider);
    final contractsMapAsync = ref.watch(agencyContractsMapProvider);
    final contractsMap = contractsMapAsync.value ?? {};

    final pendingPaymentsAsync = ref.watch(agencyPendingPaymentsProvider);
    final pendingPayments = pendingPaymentsAsync.value ?? [];
    final pendingPropertyIds =
        pendingPayments.map((p) => p['property_id'] as String?).whereType<String>().toSet();

    // ── Home Tab Badge: actionable insight card count + pending payments ──
    final allProps = propertiesAsync.value ?? [];
    final insightTypes = [
      ActionableInsightType.expiredContracts,
      ActionableInsightType.expiringContracts,
      ActionableInsightType.pendingApprovals,
      ActionableInsightType.withoutContracts,
    ];
    final activeInsightCount = insightTypes
        .where((type) => allProps.any((p) => _matchesInsight(p, contractsMap[p.id], type)))
        .length;
    final homeTabBadgeCount = activeInsightCount + pendingPayments.length;

    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return DesktopNavigationShell(
      currentTabIndex: _currentTab,
      onTabChanged: (index) => setState(() => _currentTab = index),
      onRoleSwitcherTap: () => context.push('/profile'),
      child: Scaffold(
      backgroundColor: colors.bgWhite == StanomerColors.bgCard ? StanomerColors.bgPage : colors.bgWhite,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: colors.bgWhite,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Row(
                children: [
                  ExpandableAgencyLogo(
                    logoUrl: logoUrl,
                    title: companyName,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        companyName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                const NotificationBadge(),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(LucideIcons.settings, size: 20, color: colors.textPrimary.withValues(alpha: 0.7)),
                  tooltip: loc.settingsHeader,
                  onPressed: () => context.push('/profile'),
                ),
                const SizedBox(width: 8),
              ],
            ),

      // ── Floating Action Button (Global Mülk Ekle +) ────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-property');
          ref.invalidate(agencyPropertiesProvider);
        },
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(
          loc.agencyAddProperty,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),

      // ── Bottom Navigation Bar (Hidden on Desktop Web, Active on Mobile) ──
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentTab.clamp(0, 3),
              onTap: (index) => setState(() => _currentTab = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: colors.bgWhite,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.textPrimary.withValues(alpha: 0.45),
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    icon: LucideIcons.home,
                    badgeCount: homeTabBadgeCount,
                    color: colors.primary,
                  ),
                  label: loc.tabHome,
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    icon: LucideIcons.building2,
                    badgeCount: 0,
                    color: colors.primary,
                  ),
                  label: loc.tabPortfolio,
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    icon: LucideIcons.wallet,
                    badgeCount: pendingPayments.length,
                    color: colors.primary,
                  ),
                  label: loc.tabFinance,
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    icon: LucideIcons.wrench,
                    badgeCount: 0,
                    color: colors.primary,
                  ),
                  label: loc.tabRequests,
                ),
              ],
            ),

      // ── Body (Switches depending on _currentTab & Centered on Desktop) ─
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agencyPropertiesProvider);
          ref.invalidate(agencyPendingPaymentsProvider);
          ref.invalidate(agencyContractsMapProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: IndexedStack(
          index: _currentTab.clamp(0, 3),
          children: [
            // ── Tab 0: Ana Sayfa (Özet, Aksiyonlar & Ödeme Kuyruğu) ───────
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBanner(
                    companyName: companyName,
                    email: ref.watch(currentUserProvider)?.email ?? '',
                    colors: colors,
                  ),
                  const SizedBox(height: 24),

                  // Actionable Insights Cards Section
                  propertiesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (allProps) => _ActionableInsightsSection(
                      properties: allProps,
                      contractsMap: contractsMap,
                      selectedInsight: _selectedInsight,
                      onSelectInsight: (type) {
                        setState(() {
                          _selectedInsight = type;
                          _currentTab = 1; // Switch automatically to Portföy tab
                        });
                      },
                      colors: colors,
                      loc: loc,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pending Payment Approvals Queue
                  _SectionHeader(
                    icon: LucideIcons.clipboardCheck,
                    label: loc.paymentApprovalQueue,
                    color: colors.brandGold,
                  ),
                  const SizedBox(height: 12),
                  pendingPaymentsAsync.when(
                    loading: () => _LoadingCard(colors: colors),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (payments) {
                      if (payments.isEmpty) {
                        return _EmptyCard(
                          icon: LucideIcons.checkCircle2,
                          message: loc.noPendingPaymentApprovals,
                          colors: colors,
                        );
                      }
                      return Column(
                        children: payments
                            .map((p) => _PendingPaymentRow(payment: p, colors: colors))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Padding for FAB & BottomNav
                ],
              ),
            ),

            // ── Tab 1: Portföy (Tüm Yönetilen Mülkler) ────────────────────
            AgencyPortfolioTab(
              colors: colors,
              initialInsightFilter: _selectedInsight,
            ),

            // ── Tab 2: Finans (Ödemeler Raporu & İşlemleri) ───────────────
            AgencyFinanceTab(colors: colors),

            // ── Tab 3: Bakım / Talepler (Arıza & Bakım Talepleri) ─────────
            _AgencyMaintenanceTab(colors: colors),
          ],
        ),
      ),
    ),
  ),
),
);
}

  Widget _buildDesktopNavTab({
    required int index,
    required IconData icon,
    required String label,
    required int badgeCount,
    required AgencyColorScheme colors,
  }) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.primary : colors.textPrimary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? colors.primary : colors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agency Portfolio Tab Widget
// ---------------------------------------------------------------------------

class AgencyPortfolioTab extends ConsumerStatefulWidget {
  final AgencyColorScheme colors;
  final ActionableInsightType? initialInsightFilter;

  const AgencyPortfolioTab({
    super.key,
    required this.colors,
    this.initialInsightFilter,
  });

  @override
  ConsumerState<AgencyPortfolioTab> createState() => _AgencyPortfolioTabState();
}

class _AgencyPortfolioTabState extends ConsumerState<AgencyPortfolioTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ActionableInsightType? _selectedInsight;
  String _filterBy = 'all';
  String _groupBy = 'none';
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _selectedInsight = widget.initialInsightFilter;
  }

  @override
  void didUpdateWidget(covariant AgencyPortfolioTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialInsightFilter != oldWidget.initialInsightFilter) {
      setState(() {
        _selectedInsight = widget.initialInsightFilter;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Property> _filterAndSortProperties(
    List<Property> props,
    Map<String, Contract?> contractsMap,
    Set<String> debtPropertyIds,
  ) {
    var filtered = props.where((p) {
      if (_selectedInsight != null) {
        if (!_matchesInsight(p, contractsMap[p.id], _selectedInsight!)) return false;
      }
      if (_filterBy == 'has_debt' && !debtPropertyIds.contains(p.id)) return false;
      if (_filterBy == 'occupied' && p.tenantId == null) return false;
      if (_filterBy == 'vacant' && (p.tenantId != null || p.landlordId == null)) return false;

      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;

      final name = p.name.toLowerCase();
      final address = p.address.toLowerCase();
      final city = (p.city ?? '').toLowerCase();
      final landlord = (p.landlordName ?? p.landlordEmail ?? '').toLowerCase();
      final tenant = (p.tenantName ?? '').toLowerCase();

      return name.contains(query) ||
          address.contains(query) ||
          city.contains(query) ||
          landlord.contains(query) ||
          tenant.contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'newest':
        default:
          final dateA = a.createdAt ?? DateTime(2000);
          final dateB = b.createdAt ?? DateTime(2000);
          return dateB.compareTo(dateA);
      }
    });

    return filtered;
  }

  Map<String, List<Property>> _groupProperties(
    List<Property> props,
    Set<String> debtPropertyIds,
    AppLocalizations loc,
  ) {
    final Map<String, List<Property>> grouped = {};

    if (_groupBy == 'landlord') {
      for (final p in props) {
        final key = p.landlordName?.trim().isNotEmpty == true
            ? p.landlordName!
            : (p.landlordEmail?.trim().isNotEmpty == true
                ? p.landlordEmail!
                : loc.groupLandlordPendingInvite);
        grouped.putIfAbsent(key, () => []).add(p);
      }
    } else if (_groupBy == 'city') {
      for (final p in props) {
        final key = p.city?.trim().isNotEmpty == true ? p.city! : loc.groupUnspecifiedCity;
        grouped.putIfAbsent(key, () => []).add(p);
      }
    } else if (_groupBy == 'status') {
      for (final p in props) {
        final String key;
        if (p.tenantId != null) {
          key = loc.groupStatusOccupied;
        } else if (p.landlordId != null) {
          key = loc.groupStatusVacant;
        } else {
          key = loc.groupStatusLandlordPending;
        }
        grouped.putIfAbsent(key, () => []).add(p);
      }
    } else if (_groupBy == 'debt_consent') {
      for (final p in props) {
        final String key;
        final hasDebt = debtPropertyIds.contains(p.id);
        final consentPending = p.landlordId == null || p.tenantId == null;

        if (hasDebt) {
          key = loc.groupDebtPending;
        } else if (consentPending) {
          key = loc.groupConsentPending;
        } else {
          key = loc.groupActiveClean;
        }
        grouped.putIfAbsent(key, () => []).add(p);
      }
    } else {
      grouped[loc.allPropertiesGroup] = props;
    }

    return grouped;
  }

  Widget _buildFilterChips(
    AgencyColorScheme colors,
    Set<String> debtPropertyIds,
    List<Property> allProps,
    AppLocalizations loc,
  ) {
    final debtCount = allProps.where((p) => debtPropertyIds.contains(p.id)).length;
    final occupiedCount = allProps.where((p) => p.tenantId != null).length;
    final vacantCount = allProps.where((p) => p.tenantId == null && p.landlordId != null).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChipButton(
            label: loc.filterAllCount(allProps.length),
            isSelected: _filterBy == 'all' && _selectedInsight == null,
            onTap: () => setState(() {
              _filterBy = 'all';
              _selectedInsight = null;
            }),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _FilterChipButton(
            label: loc.filterHasDebtCount(debtCount),
            isSelected: _filterBy == 'has_debt',
            badgeColor: Colors.red,
            onTap: () => setState(() => _filterBy = _filterBy == 'has_debt' ? 'all' : 'has_debt'),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _FilterChipButton(
            label: loc.filterOccupiedCount(occupiedCount),
            isSelected: _filterBy == 'occupied',
            badgeColor: Colors.green,
            onTap: () => setState(() => _filterBy = _filterBy == 'occupied' ? 'all' : 'occupied'),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _FilterChipButton(
            label: loc.filterVacantCount(vacantCount),
            isSelected: _filterBy == 'vacant',
            badgeColor: Colors.amber.shade700,
            onTap: () => setState(() => _filterBy = _filterBy == 'vacant' ? 'all' : 'vacant'),
            colors: colors,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final propertiesAsync = ref.watch(agencyPropertiesProvider);
    final allPaymentsAsync = ref.watch(agencyAllPaymentsProvider);
    final contractsMapAsync = ref.watch(agencyContractsMapProvider);
    final userRole = ref.watch(userRoleProvider);
    final isLandlord = userRole == 'landlord';

    final allPayments = allPaymentsAsync.value ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final debtPropertyIds = allPayments.where((item) {
      final status = item['status'] as String? ?? 'pending';
      if (status == 'paid') return false;
      final amt = (item['amount'] as num?)?.toDouble() ??
          (item['total_amount'] as num?)?.toDouble() ??
          (item['rent_amount'] as num?)?.toDouble() ??
          0.0;
      if (amt <= 0) return false;

      if (status == 'declared' || status == 'overdue') return true;
      final dueDateStr = item['due_date'] as String?;
      final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      if (status == 'pending' && (dueDate == null || dueDate.isBefore(today))) {
        return true;
      }
      return false;
    }).map((item) => item['property_id'] as String?).whereType<String>().toSet();

    final contractsMap = contractsMapAsync.value ?? {};
    final rawPropertiesList = propertiesAsync.value ?? [];
    final showSearchPanel = !isLandlord || rawPropertiesList.length > 1;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Property Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(
                icon: LucideIcons.building2,
                label: isLandlord ? loc.myProperties : loc.managedProperties,
                color: widget.colors.primary,
              ),
              propertiesAsync.whenData((props) => Text(
                    loc.propertiesCount(props.length),
                    style: TextStyle(
                      color: widget.colors.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )).value ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),

          // Search & Grouping & Sorting Control Panel (Distinct Toolbar Panel)
          if (showSearchPanel) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.colors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.colors.primary.withValues(alpha: 0.18)),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toolbar Header Label
                Row(
                  children: [
                    Icon(LucideIcons.slidersHorizontal, size: 14, color: widget.colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      loc.searchAndFilterPanel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: widget.colors.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Bar (Crisp White Background)
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: loc.searchPlaceholder,
                    hintStyle: TextStyle(fontSize: 12, color: widget.colors.textPrimary.withValues(alpha: 0.45)),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: widget.colors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    isDense: true,
                    filled: true,
                    fillColor: widget.colors.bgWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.colors.primary.withValues(alpha: 0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.colors.primary.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.colors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Filter Chips Bar
                propertiesAsync.maybeWhen(
                  data: (allProps) => _buildFilterChips(widget.colors, debtPropertyIds, allProps, loc),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),

                // Active Insight Active Filter Indicator Bar
                if (_selectedInsight != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: getInsightConfig(_selectedInsight!, loc).severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: getInsightConfig(_selectedInsight!, loc).severityColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(getInsightConfig(_selectedInsight!, loc).icon, size: 14, color: getInsightConfig(_selectedInsight!, loc).severityColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.filterAppliedLabel(getInsightConfig(_selectedInsight!, loc).title),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: getInsightConfig(_selectedInsight!, loc).severityColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _selectedInsight = null),
                          child: Icon(LucideIcons.x, size: 14, color: getInsightConfig(_selectedInsight!, loc).severityColor),
                        ),
                      ],
                    ),
                  ),
                ],

                // Group & Sort Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: widget.colors.bgWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _groupBy,
                            isExpanded: true,
                            icon: Icon(LucideIcons.layers, size: 14, color: widget.colors.primary),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.colors.textPrimary),
                            items: [
                              DropdownMenuItem(value: 'none', child: Text(loc.groupNone)),
                              DropdownMenuItem(value: 'landlord', child: Text(loc.groupByLandlord)),
                              DropdownMenuItem(value: 'city', child: Text(loc.groupByCity)),
                              DropdownMenuItem(value: 'status', child: Text(loc.groupByStatus)),
                              DropdownMenuItem(value: 'debt_consent', child: Text(loc.groupByDebtConsent)),
                            ],
                            onChanged: (val) => setState(() => _groupBy = val ?? 'none'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: widget.colors.bgWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            icon: Icon(LucideIcons.arrowUpDown, size: 14, color: widget.colors.primary),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.colors.textPrimary),
                            items: [
                              DropdownMenuItem(value: 'newest', child: Text(loc.sortByNewest)),
                            ],
                            onChanged: (val) => setState(() => _sortBy = val ?? 'newest'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ],

          // Properties List / Grouped View
          propertiesAsync.when(
            loading: () => _LoadingCard(colors: widget.colors),
            error: (e, _) => _ErrorCard(message: e.toString()),
            data: (rawProperties) {
              if (rawProperties.isEmpty) {
                return _EmptyCard(
                  icon: LucideIcons.building2,
                  message: loc.noManagedPropertiesYet,
                  colors: widget.colors,
                );
              }

              final filtered = _filterAndSortProperties(
                rawProperties,
                contractsMap,
                debtPropertyIds,
              );

              if (filtered.isEmpty) {
                return _EmptyCard(
                  icon: LucideIcons.searchX,
                  message: loc.noPropertiesMatchingFilter,
                  colors: widget.colors,
                );
              }

              final groupedMap = _groupProperties(filtered, debtPropertyIds, loc);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedMap.entries.map((entry) {
                  final groupTitle = entry.key;
                  final groupProps = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_groupBy != 'none') ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _groupBy == 'city'
                                      ? LucideIcons.mapPin
                                      : (_groupBy == 'landlord'
                                          ? LucideIcons.user
                                          : (_groupBy == 'debt_consent' ? LucideIcons.alertTriangle : LucideIcons.tag)),
                                  size: 13,
                                  color: widget.colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$groupTitle (${groupProps.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      ...groupProps.map((property) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PropertyCard(
                              property: property,
                              hasPendingDebt: debtPropertyIds.contains(property.id),
                              colors: widget.colors,
                              onTap: () => context.push(
                                '/property-detail',
                                extra: property,
                              ),
                            ),
                          )),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          PoweredByStanomerFooter(textColor: widget.colors.textPrimary),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agency Finance Tab Implementation
// ---------------------------------------------------------------------------

class AgencyFinanceTab extends ConsumerStatefulWidget {
  final AgencyColorScheme colors;

  const AgencyFinanceTab({super.key, required this.colors});

  @override
  ConsumerState<AgencyFinanceTab> createState() => _AgencyFinanceTabState();
}

class _AgencyFinanceTabState extends ConsumerState<AgencyFinanceTab> {
  int _selectedSegment = 0; // 0: Onay Kuyruğu, 1: Borçlular, 2: Tüm Geçmiş
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _groupBy = 'none'; // 'none', 'landlord', 'city', 'status'
  String _sortBy = 'newest'; // 'newest', 'amount_desc', 'name_asc', 'landlord_asc'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final allPaymentsAsync = ref.watch(agencyAllPaymentsProvider);
    final pendingPaymentsAsync = ref.watch(agencyPendingPaymentsProvider);
    final propertiesAsync = ref.watch(agencyPropertiesProvider);

    final allPayments = allPaymentsAsync.value ?? [];
    final pendingPayments = pendingPaymentsAsync.value ?? [];
    final propertiesList = propertiesAsync.value ?? [];
    final propertiesMap = {for (var p in propertiesList) p.id: p};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, double> calcTotals(List<Map<String, dynamic>> items) {
      final Map<String, double> totals = {};
      for (final item in items) {
        final amt = (item['amount'] as num?)?.toDouble() ??
            (item['total_amount'] as num?)?.toDouble() ??
            (item['rent_amount'] as num?)?.toDouble() ??
            0.0;
        if (amt <= 0) continue;
        final curr = (item['currency'] as String?) ??
            (item['deposit_currency'] as String?) ??
            'EUR';
        totals[curr] = (totals[curr] ?? 0) + amt;
      }
      return totals;
    }

    // 1. Onay Bekleyenler (Pending Approvals / declared)
    final pendingCount = pendingPayments.length;
    final pendingTotals = calcTotals(pendingPayments);

    // 2. Gecikmedeki Borçlar (Overdue / pending with due_date < today)
    final overdueList = allPayments.where((item) {
      final status = item['status'] as String? ?? 'pending';
      if (status == 'declared' || status == 'paid') return false;
      final amt = (item['amount'] as num?)?.toDouble() ??
          (item['total_amount'] as num?)?.toDouble() ??
          (item['rent_amount'] as num?)?.toDouble() ??
          0.0;
      if (amt <= 0) return false;

      final dueDateStr = item['due_date'] as String?;
      final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      if (status == 'overdue') return true;
      if (status == 'pending' && dueDate != null && dueDate.isBefore(today)) {
        return true;
      }
      return false;
    }).toList();
    final overdueCount = overdueList.length;
    final overdueTotals = calcTotals(overdueList);

    // 3. Bu Ay Onaylanan (Paid this month)
    final paidThisMonthList = allPayments.where((item) {
      final status = item['status'] as String?;
      if (status != 'paid') return false;
      final dateStr = item['declared_at'] as String? ??
          item['updated_at'] as String? ??
          item['created_at'] as String?;
      if (dateStr == null) return false;
      final dt = DateTime.tryParse(dateStr);
      return dt != null && dt.month == now.month && dt.year == now.year;
    }).toList();
    final paidCount = paidThisMonthList.length;
    final paidTotals = calcTotals(paidThisMonthList);

    // 4. Yaklaşan 7 Gün (Upcoming in 7 days)
    final upcomingList = allPayments.where((item) {
      final status = item['status'] as String? ?? 'pending';
      if (status != 'pending') return false;
      final dueDateStr = item['due_date'] as String?;
      if (dueDateStr == null) return false;
      final dueDate = DateTime.tryParse(dueDateStr);
      if (dueDate == null) return false;
      final diff = dueDate.difference(today).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
    final upcomingCount = upcomingList.length;
    final upcomingTotals = calcTotals(upcomingList);

    // Active Segment Raw List
    List<Map<String, dynamic>> rawList;
    if (_selectedSegment == 0) {
      rawList = pendingPayments;
    } else if (_selectedSegment == 1) {
      rawList = overdueList;
    } else {
      rawList = allPayments.where((p) => p['status'] == 'paid').toList();
    }

    // 1. Search & Filter
    final query = _searchQuery.trim().toLowerCase();
    var filtered = rawList.where((payment) {
      if (query.isEmpty) return true;
      final propertyId = payment['property_id'] as String? ?? '';
      final pObj = propertiesMap[propertyId];

      final propertyMap = payment['property'] as Map<String, dynamic>?;
      final propName = (propertyMap?['name'] as String? ?? pObj?.name ?? '').toLowerCase();
      final propAddress = (propertyMap?['address'] as String? ?? pObj?.address ?? '').toLowerCase();
      final city = (propertyMap?['city'] as String? ?? pObj?.city ?? '').toLowerCase();

      final landlordMap = propertyMap?['landlord'] as Map<String, dynamic>?;
      final landlord = (landlordMap?['full_name'] as String? ?? pObj?.landlordName ?? pObj?.landlordEmail ?? '').toLowerCase();

      final tenantMap = payment['tenant'] as Map<String, dynamic>?;
      final tenant = (tenantMap?['full_name'] as String? ?? pObj?.tenantName ?? '').toLowerCase();

      return propName.contains(query) ||
          propAddress.contains(query) ||
          city.contains(query) ||
          landlord.contains(query) ||
          tenant.contains(query);
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      final pObjA = propertiesMap[a['property_id']];
      final pObjB = propertiesMap[b['property_id']];

      final propMapA = a['property'] as Map<String, dynamic>?;
      final propMapB = b['property'] as Map<String, dynamic>?;

      final nameA = (propMapA?['name'] as String? ?? pObjA?.name ?? '').toLowerCase();
      final nameB = (propMapB?['name'] as String? ?? pObjB?.name ?? '').toLowerCase();

      final amountA = (a['amount'] as num?)?.toDouble() ?? (a['total_amount'] as num?)?.toDouble() ?? 0.0;
      final amountB = (b['amount'] as num?)?.toDouble() ?? (b['total_amount'] as num?)?.toDouble() ?? 0.0;

      final landlordA = ((propMapA?['landlord'] as Map<String, dynamic>?)?['full_name'] as String? ?? pObjA?.landlordName ?? '').toLowerCase();
      final landlordB = ((propMapB?['landlord'] as Map<String, dynamic>?)?['full_name'] as String? ?? pObjB?.landlordName ?? '').toLowerCase();

      switch (_sortBy) {
        case 'amount_desc':
          return amountB.compareTo(amountA);
        case 'name_asc':
          return nameA.compareTo(nameB);
        case 'landlord_asc':
          return landlordA.compareTo(landlordB);
        case 'newest':
        default:
          final dueAStr = a['due_date'] as String? ?? a['created_at'] as String? ?? '';
          final dueBStr = b['due_date'] as String? ?? b['created_at'] as String? ?? '';
          return dueBStr.compareTo(dueAStr);
      }
    });

    // 3. Grouping
    Map<String, List<Map<String, dynamic>>> groupedPayments = {};
    if (_groupBy == 'landlord') {
      for (final item in filtered) {
        final pObj = propertiesMap[item['property_id']];
        final propMap = item['property'] as Map<String, dynamic>?;
        final landlordMap = propMap?['landlord'] as Map<String, dynamic>?;
        final name = landlordMap?['full_name'] as String? ??
            pObj?.landlordName ??
            (landlordMap?['email'] as String? ?? pObj?.landlordEmail ?? loc.groupLandlordPendingInvite);
        groupedPayments.putIfAbsent(name, () => []).add(item);
      }
    } else if (_groupBy == 'city') {
      for (final item in filtered) {
        final pObj = propertiesMap[item['property_id']];
        final propMap = item['property'] as Map<String, dynamic>?;
        final city = propMap?['city'] as String? ?? pObj?.city ?? loc.groupUnspecifiedCity;
        groupedPayments.putIfAbsent(city, () => []).add(item);
      }
    } else if (_groupBy == 'status') {
      for (final item in filtered) {
        final st = item['status'] as String? ?? 'pending';
        final String key;
        if (st == 'paid') {
          key = loc.filterActiveLabel;
        } else if (st == 'declared') {
          key = loc.financePendingApprovals;
        } else if (st == 'overdue') {
          key = loc.financeOverduePayments;
        } else {
          key = loc.groupStatusLandlordPending;
        }
        groupedPayments.putIfAbsent(key, () => []).add(item);
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: LucideIcons.wallet,
            label: loc.financeAndPaymentsHeader,
            color: widget.colors.primary,
          ),
          const SizedBox(height: 16),

          // 4 KPI Summary Cards (4-column on Web/Desktop, 2x2 on Mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;
              final cardsPerRow = isDesktop ? 4 : 2;
              final cardWidth = (constraints.maxWidth - (12 * (cardsPerRow - 1))) / cardsPerRow;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financePendingApprovals,
                    count: pendingCount,
                    totals: pendingTotals,
                    color: widget.colors.brandGold,
                    icon: LucideIcons.clock,
                    isSelected: _selectedSegment == 0,
                    onTap: () => setState(() => _selectedSegment = 0),
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financeOverduePayments,
                    count: overdueCount,
                    totals: overdueTotals,
                    color: Colors.red.shade600,
                    icon: LucideIcons.alertTriangle,
                    isSelected: _selectedSegment == 1,
                    onTap: () => setState(() => _selectedSegment = 1),
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financePaidThisMonth,
                    count: paidCount,
                    totals: paidTotals,
                    color: Colors.green.shade600,
                    icon: LucideIcons.checkCircle2,
                    isSelected: false,
                    onTap: () {},
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financeUpcoming7Days,
                    count: upcomingCount,
                    totals: upcomingTotals,
                    color: Colors.blue.shade600,
                    icon: LucideIcons.calendar,
                    isSelected: false,
                    onTap: () {},
                    colors: widget.colors,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Segment Filter Toolbar (Onay Kuyruğu / Borçlular / Tüm Geçmiş)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FinanceSegmentChip(
                  label: loc.tabPendingQueue,
                  badgeCount: pendingCount,
                  badgeColor: widget.colors.brandGold,
                  isSelected: _selectedSegment == 0,
                  onTap: () => setState(() => _selectedSegment = 0),
                  colors: widget.colors,
                ),
                const SizedBox(width: 8),
                _FinanceSegmentChip(
                  label: loc.tabOverdueList,
                  badgeCount: overdueCount,
                  badgeColor: Colors.red.shade600,
                  isSelected: _selectedSegment == 1,
                  onTap: () => setState(() => _selectedSegment = 1),
                  colors: widget.colors,
                ),
                const SizedBox(width: 8),
                _FinanceSegmentChip(
                  label: loc.tabAllHistory,
                  badgeCount: allPayments.where((p) => p['status'] == 'paid').length,
                  isSelected: _selectedSegment == 2,
                  onTap: () => setState(() => _selectedSegment = 2),
                  colors: widget.colors,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search & Grouping & Sorting Panel
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.colors.primary.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.slidersHorizontal, size: 14, color: widget.colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      loc.searchAndFilterPanel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: widget.colors.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13, color: widget.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: loc.searchPlaceholder,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: widget.colors.textPrimary.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: widget.colors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: widget.colors.bgWhite,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.primary.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.primary.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Grouping & Sorting Dropdowns Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.colors.bgWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _groupBy,
                            isExpanded: true,
                            icon: Icon(LucideIcons.chevronDown, size: 16, color: widget.colors.primary),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.colors.textPrimary,
                            ),
                            items: [
                              DropdownMenuItem(value: 'none', child: Text(loc.groupNone)),
                              DropdownMenuItem(value: 'landlord', child: Text(loc.groupByLandlord)),
                              DropdownMenuItem(value: 'city', child: Text(loc.groupByCity)),
                              DropdownMenuItem(value: 'status', child: Text(loc.groupByStatus)),
                            ],
                            onChanged: (val) => setState(() => _groupBy = val ?? 'none'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.colors.bgWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            icon: Icon(LucideIcons.chevronDown, size: 16, color: widget.colors.primary),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.colors.textPrimary,
                            ),
                            items: [
                              DropdownMenuItem(value: 'newest', child: Text(loc.sortByNewest)),
                              DropdownMenuItem(value: 'amount_desc', child: Text(loc.sortByNameAsc)),
                              DropdownMenuItem(value: 'name_asc', child: Text(loc.sortByNameAsc)),
                              DropdownMenuItem(value: 'landlord_asc', child: Text(loc.sortByLandlordAsc)),
                            ],
                            onChanged: (val) => setState(() => _sortBy = val ?? 'newest'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Render List (Ungrouped vs Grouped)
          if (filtered.isEmpty)
            _EmptyCard(
              icon: LucideIcons.receipt,
              message: loc.noPropertiesMatchingFilter,
              colors: widget.colors,
            )
          else if (_groupBy == 'none')
            ...filtered.map((payment) => _FinancePaymentItemCard(
                  payment: payment,
                  propertiesMap: propertiesMap,
                  colors: widget.colors,
                  loc: loc,
                  segment: _selectedSegment,
                ))
          else
            ...groupedPayments.entries.map((entry) {
              final groupTitle = entry.key;
              final groupItems = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          _groupBy == 'city'
                              ? LucideIcons.mapPin
                              : (_groupBy == 'landlord' ? LucideIcons.userCheck : LucideIcons.tag),
                          size: 15,
                          color: widget.colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          groupTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: widget.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${groupItems.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupItems.map((payment) => _FinancePaymentItemCard(
                        payment: payment,
                        propertiesMap: propertiesMap,
                        colors: widget.colors,
                        loc: loc,
                        segment: _selectedSegment,
                      )),
                ],
              );
            }),

          const SizedBox(height: 24),
          PoweredByStanomerFooter(textColor: widget.colors.textPrimary),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Finance KPI Card
// ---------------------------------------------------------------------------

class _FinanceKpiCard extends StatelessWidget {
  final double width;
  final String title;
  final int count;
  final Map<String, double> totals;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final AgencyColorScheme colors;

  const _FinanceKpiCard({
    required this.width,
    required this.title,
    required this.count,
    required this.totals,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTotal = CurrencyUtils.formatCurrencyMap(
      totals,
      useSymbols: true,
      separator: ' + ',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : colors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTotal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: totals.length > 1 ? 12 : 15,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Finance Segment Chip
// ---------------------------------------------------------------------------

class _FinanceSegmentChip extends StatelessWidget {
  final String label;
  final int badgeCount;
  final Color? badgeColor;
  final bool isSelected;
  final VoidCallback onTap;
  final AgencyColorScheme colors;

  const _FinanceSegmentChip({
    required this.label,
    required this.badgeCount,
    this.badgeColor,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = badgeColor ?? colors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : colors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : colors.textPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Finance Payment Item Card & Actions (With Full Landlord & Tenant Info)
// ---------------------------------------------------------------------------

class _FinancePaymentItemCard extends ConsumerWidget {
  final Map<String, dynamic> payment;
  final Map<String, Property> propertiesMap;
  final AgencyColorScheme colors;
  final AppLocalizations loc;
  final int segment; // 0: Onay Kuyruğu, 1: Borçlular, 2: Tüm Geçmiş

  const _FinancePaymentItemCard({
    required this.payment,
    required this.propertiesMap,
    required this.colors,
    required this.loc,
    required this.segment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = payment['id'] as String;
    final propertyId = payment['property_id'] as String? ?? '';
    final pObj = propertiesMap[propertyId];

    final amount = (payment['amount'] as num?)?.toDouble() ??
        (payment['total_amount'] as num?)?.toDouble() ??
        (payment['rent_amount'] as num?)?.toDouble() ??
        0.0;
    final currency = payment['currency'] as String? ?? pObj?.currency ?? 'EUR';
    
    final rawTitle = payment['title'] as String? ?? 'Kira';
    final localizedTitle = ExpenseUtils.getLocalizedExpenseName(rawTitle, loc);

    final dueDateStr = payment['due_date'] as String?;
    final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;

    final rawMonth = payment['month'] as String?;
    String periodText = '';
    if (rawMonth != null && rawMonth.trim().isNotEmpty && rawMonth != localizedTitle && rawMonth != rawTitle) {
      periodText = rawMonth;
    } else if (dueDate != null) {
      periodText = DateFormat('MMMM yyyy', loc.localeName).format(dueDate);
    }
    final isCash = payment['is_cash'] == true;
    final status = payment['status'] as String? ?? 'pending';
    final receiptUrl = payment['receipt_url'] as String?;

    // Property info extraction
    final propertyData = payment['property'] as Map<String, dynamic>?;
    final propertyName = propertyData?['name'] as String? ?? pObj?.name ?? loc.managedProperties;
    final propertyAddress = propertyData?['address'] as String? ?? pObj?.address ?? '';
    final cityName = propertyData?['city'] as String? ?? pObj?.city ?? '';

    // Landlord & Tenant info extraction
    final landlordData = propertyData?['landlord'] as Map<String, dynamic>?;
    final landlordName = landlordData?['full_name'] as String? ??
        pObj?.landlordName ??
        (landlordData?['email'] as String? ?? pObj?.landlordEmail ?? loc.groupLandlordPendingInvite);

    final tenantData = payment['tenant'] as Map<String, dynamic>?;
    final tenantName = tenantData?['full_name'] as String? ??
        pObj?.tenantName ??
        (tenantData?['email'] as String? ?? loc.tenantLabel);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysOverdue = dueDate != null && dueDate.isBefore(today)
        ? today.difference(dueDate).inDays
        : 0;

    final targetProperty = pObj ?? (propertyData != null && propertyData['id'] != null ? Property.fromJson(propertyData) : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: segment == 1
              ? Colors.red.withValues(alpha: 0.35)
              : segment == 0
                  ? colors.brandGold.withValues(alpha: 0.35)
                  : colors.textPrimary.withValues(alpha: 0.12),
          width: segment == 1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (targetProperty != null) {
              context.push(
                '/property-detail',
                extra: {
                  'property': targetProperty,
                  'initialTabIndex': 1,
                  'initialExpandedPaymentId': id,
                },
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Property Name + City + Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: segment == 1
                            ? Colors.red.withValues(alpha: 0.1)
                            : (segment == 0
                                ? colors.brandGold.withValues(alpha: 0.12)
                                : colors.primary.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        segment == 1
                            ? LucideIcons.alertTriangle
                            : (segment == 0 ? LucideIcons.clock : LucideIcons.building),
                        size: 18,
                        color: segment == 1
                            ? Colors.red
                            : (segment == 0 ? colors.brandGold : colors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  propertyName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cityName.trim().isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.mapPin, size: 10, color: colors.primary),
                                      const SizedBox(width: 3),
                                      Text(
                                        cityName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (propertyAddress.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              propertyAddress,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textPrimary.withValues(alpha: 0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(0)} $currency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          periodText.isNotEmpty ? '$localizedTitle · $periodText' : localizedTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.primary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 10),

                // Inline Landlord & Tenant Clean Display
                Row(
                  children: [
                    // Landlord Info
                    Expanded(
                      child: Row(
                        children: [
                          Icon(LucideIcons.userCheck, size: 13, color: colors.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(fontSize: 11, color: colors.textPrimary),
                                children: [
                                  TextSpan(
                                    text: loc.landlordLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: colors.textPrimary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  TextSpan(
                                    text: landlordName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tenant Info
                    Expanded(
                      child: Row(
                        children: [
                          Icon(LucideIcons.user, size: 13, color: Colors.blue.shade700),
                          const SizedBox(width: 5),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(fontSize: 11, color: colors.textPrimary),
                                children: [
                                  TextSpan(
                                    text: loc.tenantLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: colors.textPrimary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  TextSpan(
                                    text: tenantName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Indicators & Badges Row
                Row(
                  children: [
                    if (periodText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.calendar, size: 11, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              periodText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (daysOverdue > 0 && status != 'paid')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          loc.daysOverdue(daysOverdue),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    if (isCash) ...[
                      if (daysOverdue > 0 && status != 'paid') const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.cashPayment,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(loc.viewReceipt),
                              content: Image.network(
                                receiptUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(loc.cannotOpenDocument),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.fileText, size: 13),
                        label: Text(
                          loc.viewReceipt,
                          style: const TextStyle(fontSize: 11),
                          softWrap: true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary.withValues(alpha: 0.08),
                          foregroundColor: colors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Action Buttons Wrap Section (Multi-line Word-wrapping Layout, Borderless White/Secondary Buttons)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      // Segment 0: Approve / Reject Actions
                      if (segment == 0 || status == 'declared') ...[
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final propRepo = ref.read(propertyRepositoryProvider);
                              final monthName = periodText.isNotEmpty ? periodText : 'Kira';
                              await propRepo.rejectRentPayment(id, propertyId, monthName, dueDate ?? DateTime.now());

                              ref.invalidate(agencyPendingPaymentsProvider);
                              ref.invalidate(agencyAllPaymentsProvider);
                              ref.invalidate(agencyPropertiesProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ödeme reddedildi.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            loc.rejectPayment,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final propRepo = ref.read(propertyRepositoryProvider);
                              final monthName = periodText.isNotEmpty ? periodText : 'Kira';
                              await propRepo.approveRentPayment(id, propertyId, monthName, dueDate ?? DateTime.now());

                              ref.invalidate(agencyPendingPaymentsProvider);
                              ref.invalidate(agencyAllPaymentsProvider);
                              ref.invalidate(agencyPropertiesProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Ödeme başarıyla onaylandı.'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Onay hatası: $e'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.check, size: 14),
                          label: Text(
                            loc.approvePayment,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ]
                // Segment 1: Overdue Actions
                else if (segment == 1 || status == 'overdue' || status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final message = loc.overduePaymentReminderMessage(
                        tenantName,
                        propertyName,
                        amount.toStringAsFixed(0),
                        currency,
                      );
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.reminderMessageCopied),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.messageSquare, size: 13),
                    label: Text(
                      loc.sendReminder,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.08),
                      foregroundColor: colors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final repo = AgencyRepository(ref.read(propertyRepositoryProvider).client);
                      await repo.markPaymentAsCashPaid(id);
                      ref.invalidate(agencyPendingPaymentsProvider);
                      ref.invalidate(agencyAllPaymentsProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      loc.markAsCashPaid,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
                // Segment 2: Status Indicator Badge
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'paid'
                          ? Colors.green.shade50
                          : status == 'declared'
                              ? Colors.amber.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'paid'
                            ? Colors.green.shade800
                            : status == 'declared'
                                ? Colors.amber.shade900
                                : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
);
}
}

class _AgencyMaintenanceTab extends ConsumerStatefulWidget {
  final AgencyColorScheme colors;

  const _AgencyMaintenanceTab({required this.colors});

  @override
  ConsumerState<_AgencyMaintenanceTab> createState() => _AgencyMaintenanceTabState();
}

class _AgencyMaintenanceTabState extends ConsumerState<_AgencyMaintenanceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _groupBy = 'none'; // 'none', 'status', 'priority', 'category', 'property'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'priority_desc', 'title_asc'
  String? _selectedKpiFilter; // null, 'urgent', 'active', 'resolved'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Map<String, String> _getLocalizedTexts(String lang) {
    switch (lang) {
      case 'tr':
        return {
          'kpi_urgent_title': 'Acil & Kritik',
          'kpi_active_title': 'İşlemdeki Talepler',
          'kpi_resolved_title': 'Bu Ay Çözülenler',
          'kpi_sla_title': 'Ort. Çözüm (SLA)',
          'request_unit': 'Talep',
          'hours_unit': 'Saat',
          'days_unit': 'Gün',
          'filter_banner_urgent': 'Filtreleniyor: Acil & Kritik Talepler',
          'filter_banner_active': 'Filtreleniyor: İşlemdeki Talepler',
          'filter_banner_resolved': 'Filtreleniyor: Bu Ay Çözülenler',
          'show_all': 'Tümünü Göster',
          'search_hint': 'Talep başlığı, açıklama veya mülk ara...',
          'group_none': 'Gruplama Yok',
          'group_status': 'Duruma Göre',
          'group_priority': 'Önceliğe Göre',
          'group_category': 'Kategoriye Göre',
          'group_property': 'Mülke Göre',
          'group_landlord': 'Ev Sahibine Göre',
          'sort_newest': 'En Yeni',
          'sort_oldest': 'En Eski',
          'sort_priority': 'Önceliğe Göre',
          'sort_title': 'Başlık (A-Z)',
          'status_open_group': '🟠 Açık Talepler',
          'status_investigating_group': '🔵 İnceleniyor',
          'status_in_progress_group': '🟡 Usta Gönderildi',
          'status_resolved_group': '🟢 Çözülenler',
          'status_closed_group': '⚪ Kapatılanlar',
          'status_pending_group': '🟡 Bekleyenler',
          'status_cancelled_group': '🔴 İptal Edilenler',
          'priority_urgent_group': '🚨 Acil Öncelik',
          'priority_high_group': '⚠️ Yüksek Öncelik',
          'priority_medium_group': 'ℹ️ Orta Öncelik',
          'priority_normal_group': '🔹 Normal Öncelik',
          'priority_low_group': '▫️ Düşük Öncelik',
          'no_search_results': 'Aramanıza uygun arıza/bakım kaydı bulunamadı',
          'urgent_badge': 'ACİL',
          'high_badge': 'YÜKSEK',
          'medium_badge': 'ORTA',
          'normal_badge': 'NORMAL',
          'low_badge': 'DÜŞÜK',
          'status_technician_sent': 'Usta Gönderildi',
          'status_closed': 'Kapatıldı',
          'status_pending': 'Beklemede',
          'status_cancelled': 'İptal Edildi',
          'other_group': 'Diğer',
          'property_detail': 'Mülk Detayı',
          'managed_unit': 'Yönetilen Daire',
        };
      case 'sr':
        return {
          'kpi_urgent_title': 'Hitno & Kritično',
          'kpi_active_title': 'Zahtevi u Toku',
          'kpi_resolved_title': 'Rešeno Ovog Meseca',
          'kpi_sla_title': 'Prosečno Vreme (SLA)',
          'request_unit': 'Zahtev',
          'hours_unit': 'Sati',
          'days_unit': 'Dana',
          'filter_banner_urgent': 'Filtrirano: Hitni & Kritični Zahtevi',
          'filter_banner_active': 'Filtrirano: Zahtevi u Toku',
          'filter_banner_resolved': 'Filtrirano: Rešeni Ovog Meseca',
          'show_all': 'Prikaži Sve',
          'search_hint': 'Pretraži naslov, opis ili nekretninu...',
          'group_none': 'Bez Grupisanja',
          'group_status': 'Po Statusu',
          'group_priority': 'Po Prioritetu',
          'group_category': 'Po Kategoriji',
          'group_property': 'Po Nekretnini',
          'group_landlord': 'Po Stanodavcu',
          'sort_newest': 'Najnovije',
          'sort_oldest': 'Najstarije',
          'sort_priority': 'Po Prioritetu',
          'sort_title': 'Naslov (A-Z)',
          'status_open_group': '🟠 Otvoreni Zahtevi',
          'status_investigating_group': '🔵 U Razmatranju',
          'status_in_progress_group': '🟡 Poslat Majstor',
          'status_resolved_group': '🟢 Rešeno',
          'status_closed_group': '⚪ Zatvoreno',
          'status_pending_group': '🟡 Na Čekanju',
          'status_cancelled_group': '🔴 Otkazano',
          'priority_urgent_group': '🚨 Hitno',
          'priority_high_group': '⚠️ Visok Prioritet',
          'priority_medium_group': 'ℹ️ Srednji Prioritet',
          'priority_normal_group': '🔹 Normalan Prioritet',
          'priority_low_group': '▫️ Nizak Prioritet',
          'no_search_results': 'Nema zahteva koji odgovaraju pretrazi',
          'urgent_badge': 'HITNO',
          'high_badge': 'VISOK',
          'medium_badge': 'SREDNJI',
          'normal_badge': 'NORMALAN',
          'low_badge': 'NIZAK',
          'status_technician_sent': 'Poslat Majstor',
          'status_closed': 'Zatvoreno',
          'status_pending': 'Na Čekanju',
          'status_cancelled': 'Otkazano',
          'other_group': 'Ostalo',
          'property_detail': 'Detalji Nekretnine',
          'managed_unit': 'Upravljani Stan',
        };
      case 'ru':
        return {
          'kpi_urgent_title': 'Срочно & Критично',
          'kpi_active_title': 'Заявки в Работе',
          'kpi_resolved_title': 'Решено в Этом Месяце',
          'kpi_sla_title': 'Ср. Время (SLA)',
          'request_unit': 'Запрос',
          'hours_unit': 'Ч',
          'days_unit': 'Дн',
          'filter_banner_urgent': 'Фильтр: Срочные & Критичные Заявки',
          'filter_banner_active': 'Фильтр: Заявки в Работе',
          'filter_banner_resolved': 'Фильтр: Решено в Этом Месяце',
          'show_all': 'Показать Все',
          'search_hint': 'Поиск по названию, описанию или объекту...',
          'group_none': 'Без Группировки',
          'group_status': 'По Статусу',
          'group_priority': 'По Приоритету',
          'group_category': 'По Категории',
          'group_property': 'По Объекту',
          'group_landlord': 'По Собственнику',
          'sort_newest': 'Сначала Новые',
          'sort_oldest': 'Сначала Старые',
          'sort_priority': 'По Приоритету',
          'sort_title': 'Название (А-Я)',
          'status_open_group': '🟠 Открытые Заявки',
          'status_investigating_group': '🔵 На Рассмотрении',
          'status_in_progress_group': '🟡 Мастер Отправлен',
          'status_resolved_group': '🟢 Решенные',
          'status_closed_group': '⚪ Закрытые',
          'status_pending_group': '🟡 В Ожидании',
          'status_cancelled_group': '🔴 Отмененные',
          'priority_urgent_group': '🚨 Срочно',
          'priority_high_group': '⚠️ Высокий Приоритет',
          'priority_medium_group': 'ℹ️ Средний Приоритет',
          'priority_normal_group': '🔹 Обычный Приоритет',
          'priority_low_group': '▫️ Низкий Приоритет',
          'no_search_results': 'Записи о техническом обслуживании не найдены',
          'urgent_badge': 'СРОЧНО',
          'high_badge': 'ВЫСОКИЙ',
          'medium_badge': 'СРЕДНИЙ',
          'normal_badge': 'ОБЫЧНЫЙ',
          'low_badge': 'НИЗКИЙ',
          'status_technician_sent': 'Мастер Отправлен',
          'status_closed': 'Закрыто',
          'status_pending': 'В Ожидании',
          'status_cancelled': 'Отменено',
          'other_group': 'Другое',
          'property_detail': 'Детали Объекта',
          'managed_unit': 'Управляемый Объект',
        };
      case 'en':
      default:
        return {
          'kpi_urgent_title': 'Urgent & Critical',
          'kpi_active_title': 'In Progress',
          'kpi_resolved_title': 'Resolved This Month',
          'kpi_sla_title': 'Avg. Resolution (SLA)',
          'request_unit': 'Requests',
          'hours_unit': 'Hours',
          'days_unit': 'Days',
          'filter_banner_urgent': 'Filtering: Urgent & Critical Requests',
          'filter_banner_active': 'Filtering: In Progress Requests',
          'filter_banner_resolved': 'Filtering: Resolved This Month',
          'show_all': 'Show All',
          'search_hint': 'Search title, description or property...',
          'group_none': 'No Grouping',
          'group_status': 'By Status',
          'group_priority': 'By Priority',
          'group_category': 'By Category',
          'group_property': 'By Property',
          'group_landlord': 'By Landlord',
          'sort_newest': 'Newest First',
          'sort_oldest': 'Oldest First',
          'sort_priority': 'By Priority',
          'sort_title': 'Title (A-Z)',
          'status_open_group': '🟠 Open Requests',
          'status_investigating_group': '🔵 Investigating',
          'status_in_progress_group': '🟡 Technician Sent',
          'status_resolved_group': '🟢 Resolved',
          'status_closed_group': '⚪ Closed',
          'status_pending_group': '🟡 Pending',
          'status_cancelled_group': '🔴 Cancelled',
          'priority_urgent_group': '🚨 Urgent Priority',
          'priority_high_group': '⚠️ High Priority',
          'priority_medium_group': 'ℹ️ Medium Priority',
          'priority_normal_group': '🔹 Normal Priority',
          'priority_low_group': '▫️ Low Priority',
          'no_search_results': 'No maintenance requests match your search',
          'urgent_badge': 'URGENT',
          'high_badge': 'HIGH',
          'medium_badge': 'MEDIUM',
          'normal_badge': 'NORMAL',
          'low_badge': 'LOW',
          'status_technician_sent': 'Technician Sent',
          'status_closed': 'Closed',
          'status_pending': 'Pending',
          'status_cancelled': 'Cancelled',
          'other_group': 'Other',
          'property_detail': 'Property Details',
          'managed_unit': 'Managed Property',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final txt = _getLocalizedTexts(lang);

    final requestsAsync = ref.watch(agencyMaintenanceRequestsProvider);
    final propertiesAsync = ref.watch(agencyPropertiesProvider);
    final properties = propertiesAsync.asData?.value ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _SectionHeader(
            icon: LucideIcons.wrench,
            label: loc.maintenanceRequestsHeader,
            color: widget.colors.primary,
          ),
          const SizedBox(height: 16),

          requestsAsync.when(
            data: (allRequests) {
              // 1. KPI Calculation
              final urgentCount = allRequests.where((r) => r.priority == MaintenancePriority.urgent || r.priority == MaintenancePriority.high).length;
              final activeCount = allRequests.where((r) => r.status == MaintenanceStatus.open || r.status == MaintenanceStatus.investigating || r.status == MaintenanceStatus.inProgress).length;
              final resolvedThisMonth = allRequests.where((r) => r.status == MaintenanceStatus.resolved).length;
              
              // Calculate average SLA resolution time
              String slaText = '1.2 ${txt['days_unit']}';
              final resolvedRequests = allRequests.where((r) => r.status == MaintenanceStatus.resolved && r.createdAt != null).toList();
              if (resolvedRequests.isNotEmpty) {
                double totalHours = 0;
                for (final req in resolvedRequests) {
                  totalHours += DateTime.now().difference(req.createdAt!).inHours.toDouble();
                }
                final avgHours = totalHours / resolvedRequests.length;
                if (avgHours < 24) {
                  slaText = '${avgHours.round()} ${txt['hours_unit']}';
                } else {
                  slaText = '${(avgHours / 24).toStringAsFixed(1)} ${txt['days_unit']}';
                }
              }

              // 2. Filtering
              var filtered = allRequests.where((req) {
                // Apply KPI Filter
                if (_selectedKpiFilter == 'urgent') {
                  if (req.priority != MaintenancePriority.urgent && req.priority != MaintenancePriority.high) {
                    return false;
                  }
                } else if (_selectedKpiFilter == 'active') {
                  if (req.status != MaintenanceStatus.open && req.status != MaintenanceStatus.investigating && req.status != MaintenanceStatus.inProgress) {
                    return false;
                  }
                } else if (_selectedKpiFilter == 'resolved') {
                  if (req.status != MaintenanceStatus.resolved) {
                    return false;
                  }
                }

                // Apply Search Query Filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final titleMatch = req.title.toLowerCase().contains(q);
                  final descMatch = (req.description ?? '').toLowerCase().contains(q);
                  final prop = properties.firstWhere(
                    (p) => p.id == req.propertyId,
                    orElse: () => Property(id: req.propertyId, landlordId: '', name: '', address: '', defaultMonthlyRent: 0),
                  );
                  final propMatch = prop.name.toLowerCase().contains(q) || prop.address.toLowerCase().contains(q);
                  if (!titleMatch && !descMatch && !propMatch) return false;
                }

                return true;
              }).toList();

              // 3. Sorting
              filtered.sort((a, b) {
                switch (_sortBy) {
                  case 'oldest':
                    return (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
                  case 'priority_desc':
                    return _getPriorityWeight(b.priority).compareTo(_getPriorityWeight(a.priority));
                  case 'title_asc':
                    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
                  case 'newest':
                  default:
                    return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
                }
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INTERACTIVE KPI SUMMARY CARDS (4-column on Web/Desktop, 2x2 on Mobile) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 850;
                      final cardsPerRow = isDesktop ? 4 : 2;
                      final cardWidth = (constraints.maxWidth - (12 * (cardsPerRow - 1))) / cardsPerRow;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // 1. Acil & Kritik Talepler (Filter: 'urgent')
                          _buildKpiCard(
                            width: cardWidth,
                            title: txt['kpi_urgent_title']!,
                            count: urgentCount,
                            mainValue: '$urgentCount ${txt['request_unit']}',
                            color: StanomerColors.alertPrimary,
                            icon: LucideIcons.alertTriangle,
                            isSelected: _selectedKpiFilter == 'urgent',
                            onTap: () {
                              setState(() {
                                _selectedKpiFilter = _selectedKpiFilter == 'urgent' ? null : 'urgent';
                              });
                            },
                          ),
                          // 2. İşlemdeki Talepler (Filter: 'active')
                          _buildKpiCard(
                            width: cardWidth,
                            title: txt['kpi_active_title']!,
                            count: activeCount,
                            mainValue: '$activeCount ${txt['request_unit']}',
                            color: const Color(0xFFD97706),
                            icon: LucideIcons.wrench,
                            isSelected: _selectedKpiFilter == 'active',
                            onTap: () {
                              setState(() {
                                _selectedKpiFilter = _selectedKpiFilter == 'active' ? null : 'active';
                              });
                            },
                          ),
                          // 3. Bu Ay Çözülenler (Filter: 'resolved')
                          _buildKpiCard(
                            width: cardWidth,
                            title: txt['kpi_resolved_title']!,
                            count: resolvedThisMonth,
                            mainValue: '$resolvedThisMonth ${txt['request_unit']}',
                            color: Colors.green.shade600,
                            icon: LucideIcons.checkCircle2,
                            isSelected: _selectedKpiFilter == 'resolved',
                            onTap: () {
                              setState(() {
                                _selectedKpiFilter = _selectedKpiFilter == 'resolved' ? null : 'resolved';
                              });
                            },
                          ),
                          // 4. SLA & Ortalama Süre
                          _buildKpiCard(
                            width: cardWidth,
                            title: txt['kpi_sla_title']!,
                            count: 0,
                            customBadge: 'SLA',
                            mainValue: slaText,
                            color: Colors.blue.shade600,
                            icon: LucideIcons.clock,
                            isSelected: false,
                            onTap: () {
                              setState(() {
                                _selectedKpiFilter = null;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Active Filter Banner (if KPI filter is active)
                  if (_selectedKpiFilter != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.filter, size: 14, color: widget.colors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedKpiFilter == 'urgent'
                                    ? '${txt['filter_banner_urgent']} (${filtered.length})'
                                    : (_selectedKpiFilter == 'active'
                                        ? '${txt['filter_banner_active']} (${filtered.length})'
                                        : '${txt['filter_banner_resolved']} (${filtered.length})'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.colors.primary,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => setState(() => _selectedKpiFilter = null),
                            child: Row(
                              children: [
                                Text(
                                  txt['show_all']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: widget.colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.x, size: 14, color: widget.colors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- SEARCH & GROUP/SORT CONTROLS (MATCHING FINANCE TAB STYLING) ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.colors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: widget.colors.primary.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.slidersHorizontal, size: 14, color: widget.colors.primary),
                            const SizedBox(width: 6),
                            Text(
                              loc.searchAndFilterPanel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: widget.colors.primary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: txt['search_hint'],
                            prefixIcon: Icon(LucideIcons.search, size: 18, color: widget.colors.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Group & Sort Dropdowns
                        Row(
                          children: [
                            // Grouping
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _groupBy,
                                    isExpanded: true,
                                    icon: Icon(LucideIcons.layers, size: 14, color: widget.colors.primary),
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.colors.textPrimary),
                                    items: [
                                      DropdownMenuItem(value: 'none', child: Text(txt['group_none']!)),
                                      DropdownMenuItem(value: 'status', child: Text(txt['group_status']!)),
                                      DropdownMenuItem(value: 'priority', child: Text(txt['group_priority']!)),
                                      DropdownMenuItem(value: 'category', child: Text(txt['group_category']!)),
                                      DropdownMenuItem(value: 'property', child: Text(txt['group_property']!)),
                                      DropdownMenuItem(value: 'landlord', child: Text(txt['group_landlord']!)),
                                    ],
                                    onChanged: (val) => setState(() => _groupBy = val ?? 'none'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Sorting
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: widget.colors.primary.withValues(alpha: 0.15)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _sortBy,
                                    isExpanded: true,
                                    icon: Icon(LucideIcons.arrowUpDown, size: 14, color: widget.colors.primary),
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.colors.textPrimary),
                                    items: [
                                      DropdownMenuItem(value: 'newest', child: Text(txt['sort_newest']!)),
                                      DropdownMenuItem(value: 'oldest', child: Text(txt['sort_oldest']!)),
                                      DropdownMenuItem(value: 'priority_desc', child: Text(txt['sort_priority']!)),
                                      DropdownMenuItem(value: 'title_asc', child: Text(txt['sort_title']!)),
                                    ],
                                    onChanged: (val) => setState(() => _sortBy = val ?? 'newest'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- REQUEST LIST (GROUPED OR UNGROUPED) ---
                  if (filtered.isEmpty)
                    _EmptyCard(
                      icon: LucideIcons.clipboardCheck,
                      message: _searchQuery.isNotEmpty ? txt['no_search_results']! : loc.noOpenRequestsYet,
                      colors: widget.colors,
                    )
                  else
                    ..._buildGroupedList(filtered, properties, loc, txt),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _EmptyCard(
              icon: LucideIcons.alertCircle,
              message: loc.errorWithDetails(e.toString()),
              colors: widget.colors,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  int _getPriorityWeight(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent: return 4;
      case MaintenancePriority.high: return 3;
      case MaintenancePriority.medium: return 2;
      case MaintenancePriority.normal: return 1;
      case MaintenancePriority.low: return 0;
    }
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required int count,
    String? customBadge,
    required String mainValue,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final badgeStr = customBadge ?? '$count';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : widget.colors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.colors.textPrimary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: widget.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(List<MaintenanceRequest> requests, List<Property> properties, AppLocalizations loc, Map<String, String> txt) {
    if (_groupBy == 'none') {
      return requests.map((req) => _buildRequestCard(req, properties, loc, txt)).toList();
    }

    final Map<String, List<MaintenanceRequest>> groups = {};

    for (final req in requests) {
      String groupKey = txt['other_group']!;
      if (_groupBy == 'status') {
        groupKey = _getStatusGroupLabel(req.status, txt);
      } else if (_groupBy == 'priority') {
        groupKey = _getPriorityGroupLabel(req.priority, txt);
      } else if (_groupBy == 'category') {
        groupKey = _getCategoryLabel(req.category, loc);
      } else if (_groupBy == 'property') {
        final prop = properties.firstWhere(
          (p) => p.id == req.propertyId,
          orElse: () => Property(id: req.propertyId, landlordId: '', name: 'Mülk ${req.propertyId.substring(0, 4)}', address: '', defaultMonthlyRent: 0),
        );
        groupKey = prop.name.isNotEmpty ? prop.name : prop.address;
      } else if (_groupBy == 'landlord') {
        final prop = properties.firstWhere(
          (p) => p.id == req.propertyId,
          orElse: () => Property(id: req.propertyId, landlordId: '', name: '', address: '', defaultMonthlyRent: 0),
        );
        if (prop.landlordName != null && prop.landlordName!.isNotEmpty) {
          groupKey = prop.landlordName!;
        } else if (prop.landlordId != null && prop.landlordId!.isNotEmpty) {
          groupKey = 'Ev Sahibi (${prop.landlordId!.substring(0, 4)})';
        } else {
          groupKey = txt['other_group']!;
        }
      }

      groups.putIfAbsent(groupKey, () => []).add(req);
    }

    return groups.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key} (${entry.value.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: widget.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((req) => _buildRequestCard(req, properties, loc, txt)),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  String _getStatusGroupLabel(MaintenanceStatus status, Map<String, String> txt) {
    switch (status) {
      case MaintenanceStatus.open: return txt['status_open_group']!;
      case MaintenanceStatus.investigating: return txt['status_investigating_group']!;
      case MaintenanceStatus.inProgress: return txt['status_in_progress_group']!;
      case MaintenanceStatus.resolved: return txt['status_resolved_group']!;
      case MaintenanceStatus.closed: return txt['status_closed_group']!;
      case MaintenanceStatus.pending: return txt['status_pending_group']!;
      case MaintenanceStatus.cancelled: return txt['status_cancelled_group']!;
    }
  }

  String _getPriorityGroupLabel(MaintenancePriority priority, Map<String, String> txt) {
    switch (priority) {
      case MaintenancePriority.urgent: return txt['priority_urgent_group']!;
      case MaintenancePriority.high: return txt['priority_high_group']!;
      case MaintenancePriority.medium: return txt['priority_medium_group']!;
      case MaintenancePriority.normal: return txt['priority_normal_group']!;
      case MaintenancePriority.low: return txt['priority_low_group']!;
    }
  }

  Widget _buildRequestCard(MaintenanceRequest req, List<Property> properties, AppLocalizations loc, Map<String, String> txt) {
    // Find matching property
    final property = properties.firstWhere(
      (p) => p.id == req.propertyId,
      orElse: () => Property(
        id: req.propertyId,
        landlordId: '',
        agencyId: widget.colors.primary.value.toString(),
        name: txt['property_detail']!,
        address: txt['managed_unit']!,
        defaultMonthlyRent: 0,
      ),
    );

    Color statusColor = Colors.grey;
    String statusText = 'Bilinmiyor';
    switch (req.status) {
      case MaintenanceStatus.open:
        statusColor = Colors.orange;
        statusText = loc.statusActive;
        break;
      case MaintenanceStatus.investigating:
        statusColor = Colors.blue;
        statusText = loc.statusInvestigating;
        break;
      case MaintenanceStatus.inProgress:
        statusColor = const Color(0xFFD97706);
        statusText = txt['status_technician_sent']!;
        break;
      case MaintenanceStatus.resolved:
        statusColor = const Color(0xFF10B981);
        statusText = loc.statusResolved;
        break;
      case MaintenanceStatus.closed:
        statusColor = Colors.grey;
        statusText = txt['status_closed']!;
        break;
      case MaintenanceStatus.pending:
        statusColor = Colors.amber;
        statusText = txt['status_pending']!;
        break;
      case MaintenanceStatus.cancelled:
        statusColor = Colors.red;
        statusText = txt['status_cancelled']!;
        break;
    }

    final isUrgent = req.priority == MaintenancePriority.urgent || req.priority == MaintenancePriority.high;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.colors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? StanomerColors.alertPrimary.withValues(alpha: 0.5) : widget.colors.primary.withValues(alpha: 0.12),
          width: isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              '/maintenance/detail',
              extra: {
                'property': property,
                'request': req,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Property Title & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(LucideIcons.building2, size: 14, color: widget.colors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              property.name.isNotEmpty ? property.name : property.address,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.colors.textPrimary.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Issue Title
                Text(
                  req.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.colors.textPrimary,
                  ),
                ),
                if (req.description != null && req.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    req.description!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: widget.colors.textPrimary.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Bottom Row: Category, Priority, Date & Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCategoryLabel(req.category, loc),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.colors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Priority Badge
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: StanomerColors.alertPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertTriangle, size: 10, color: StanomerColors.alertPrimary),
                                const SizedBox(width: 3),
                                Text(
                                  req.priority == MaintenancePriority.urgent ? txt['urgent_badge']! : txt['high_badge']!,
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: StanomerColors.alertPrimary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          req.createdAt != null ? DateFormat('dd MMM, HH:mm').format(req.createdAt!) : '-',
                          style: TextStyle(fontSize: 11, color: widget.colors.textPrimary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight, size: 16, color: widget.colors.primary.withValues(alpha: 0.6)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return loc.categoryPlumbing;
      case MaintenanceCategory.electrical: return loc.categoryElectrical;
      case MaintenanceCategory.heating: return loc.categoryHeating;
      case MaintenanceCategory.internet: return loc.categoryInternet;
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
      default:
        return loc.categoryOther;
    }
  }
}

// ---------------------------------------------------------------------------
// Actionable Insights Cards Section Component
// ---------------------------------------------------------------------------

class _ActionableInsightsSection extends StatelessWidget {
  final List<Property> properties;
  final Map<String, Contract?> contractsMap;
  final ActionableInsightType? selectedInsight;
  final ValueChanged<ActionableInsightType> onSelectInsight;
  final AgencyColorScheme colors;
  final AppLocalizations loc;

  const _ActionableInsightsSection({
    required this.properties,
    required this.contractsMap,
    required this.selectedInsight,
    required this.onSelectInsight,
    required this.colors,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final typesInOrder = [
      ActionableInsightType.expiredContracts,
      ActionableInsightType.expiringContracts,
      ActionableInsightType.pendingApprovals,
      ActionableInsightType.withoutContracts,
    ];

    final activeCards = <ActionableInsightConfig, int>{};

    for (final type in typesInOrder) {
      final matchingCount = properties.where((p) => _matchesInsight(p, contractsMap[p.id], type)).length;
      if (matchingCount > 0) {
        activeCards[getInsightConfig(type, loc)] = matchingCount;
      }
    }

    if (activeCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              loc.actionableInsightsHeader,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: activeCards.entries.map((entry) {
            final config = entry.key;
            final count = entry.value;
            final isSelected = selectedInsight == config.type;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActionableInsightCard(
                config: config,
                matchingCount: count,
                isSelected: isSelected,
                onTap: () => onSelectInsight(config.type),
                loc: loc,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActionableInsightCard extends StatefulWidget {
  final ActionableInsightConfig config;
  final int matchingCount;
  final bool isSelected;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _ActionableInsightCard({
    required this.config,
    required this.matchingCount,
    required this.isSelected,
    required this.onTap,
    required this.loc,
  });

  @override
  State<_ActionableInsightCard> createState() => _ActionableInsightCardState();
}

class _ActionableInsightCardState extends State<_ActionableInsightCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.config.severityColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected || _isHovered
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? color
                  : (_isHovered ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.25)),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered || widget.isSelected
                    ? color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _isHovered ? 12 : 6,
                offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Title + Counter Badge
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.config.icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.config.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.matchingCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description Text
              Text(
                widget.config.desc,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.black87.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),

              // Action Link Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.config.action,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 12, color: color),
                    ],
                  ),
                  if (widget.isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.loc.filterActiveLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AgencyColorScheme colors;
  final Color? badgeColor;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = badgeColor ?? colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : activeColor.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends ConsumerWidget {
  final String companyName;
  final String email;
  final AgencyColorScheme colors;

  const _WelcomeBanner({
    required this.companyName,
    required this.email,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? (user?.email != null ? user!.email!.split('@').first : '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgWhite,
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.08),
            colors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.building2, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userName.isNotEmpty) ...[
                  Text(
                    loc.welcomeUser(userName),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  companyName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final Property property;
  final bool hasPendingDebt;
  final VoidCallback onTap;
  final AgencyColorScheme colors;

  const _PropertyCard({
    required this.property,
    required this.hasPendingDebt,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final hasActiveTenant = property.tenantId != null;
    final isClaimed = property.landlordId != null;
    final landlordName = property.landlordName ?? property.landlordEmail ?? loc.landlord;

    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final contract = activeContractAsync.value;
    final tenantProfileAsync = property.tenantId != null ? ref.watch(profileProvider(property.tenantId!)) : null;
    final tenantProfileName = tenantProfileAsync?.value?['full_name'] as String?;

    final tenantName = (property.tenantName != null && property.tenantName!.trim().isNotEmpty)
        ? property.tenantName
        : (tenantProfileName != null && tenantProfileName.trim().isNotEmpty)
            ? tenantProfileName
            : (contract?.inviteeEmail != null && contract!.inviteeEmail.trim().isNotEmpty)
                ? contract.inviteeEmail
                : (hasActiveTenant ? loc.roleTenant : loc.vacant);
    final cityName = property.city?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPendingDebt
                ? Colors.red.withValues(alpha: 0.5)
                : (hasActiveTenant ? colors.primary.withValues(alpha: 0.3) : colors.border),
            width: hasPendingDebt ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Property Name + City + Popup Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasPendingDebt
                        ? Colors.red.withValues(alpha: 0.1)
                        : (hasActiveTenant ? colors.primary.withValues(alpha: 0.12) : StanomerColors.bgPage),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasPendingDebt ? LucideIcons.alertTriangle : LucideIcons.building,
                    size: 18,
                    color: hasPendingDebt
                        ? Colors.red
                        : (hasActiveTenant ? colors.primary : colors.textPrimary.withValues(alpha: 0.4)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cityName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.mapPin, size: 10, color: colors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    cityName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        property.address,
                        style: TextStyle(
                          color: colors.textPrimary.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.ellipsisVertical, size: 18, color: colors.textPrimary.withValues(alpha: 0.5)),
                  onSelected: (value) async {
                    if (value == 'invite_tenant') {
                      context.push('/invite-tenant', extra: property);
                    } else if (value == 'share_qr') {
                      final repo = ref.read(propertyRepositoryProvider);
                      final token = await repo.getOrCreateLandlordOwnershipInviteToken(property);
                      if (context.mounted) {
                        OwnershipShareSheet.show(
                          context,
                          propertyName: property.name,
                          landlordName: property.landlordName ?? '',
                          landlordEmail: property.landlordEmail ?? '',
                          token: token,
                        );
                      }
                    } else if (value == 'change_landlord') {
                      _ChangeLandlordDialog.show(context, property);
                    } else if (value == 'property_settings') {
                      context.push('/property-settings', extra: {'property': property, 'initialTab': 'contract'});
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'invite_tenant',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userCheck, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.inviteTenantOrAddContract, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share_qr',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.qrCode, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.ownershipQrOrLink, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'property_settings',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.settings, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.propertySettingsLabel, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'change_landlord',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userPlus, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.changeLandlord, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (hasPendingDebt) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 13, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loc.pendingDebtWarning,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 10),

            // Landlord & Tenant Clean Inline Info
            Row(
              children: [
                // Landlord Info
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isClaimed ? LucideIcons.userCheck : LucideIcons.clock,
                        size: 13,
                        color: isClaimed ? colors.primary : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: colors.textPrimary),
                            children: [
                              TextSpan(
                                text: loc.landlordLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: colors.textPrimary.withValues(alpha: 0.6),
                                ),
                              ),
                              TextSpan(
                                text: isClaimed
                                    ? landlordName
                                    : '$landlordName (${loc.invitePending})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isClaimed ? colors.textPrimary : Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Tenant Info
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        hasActiveTenant ? LucideIcons.user : LucideIcons.userX,
                        size: 13,
                        color: hasActiveTenant ? StanomerColors.tenant : colors.textPrimary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: colors.textPrimary),
                            children: [
                              TextSpan(
                                text: loc.tenantLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: colors.textPrimary.withValues(alpha: 0.6),
                                ),
                              ),
                              TextSpan(
                                text: hasActiveTenant ? tenantName : loc.vacantLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Contract Info Box
            _ContractInfoBadge(contract: contract, colors: colors, loc: loc),
          ],
        ),
      ),
    );
  }
}

class _ContractInfoBadge extends StatelessWidget {
  final Contract? contract;
  final AgencyColorScheme colors;
  final AppLocalizations loc;

  const _ContractInfoBadge({
    required this.contract,
    required this.colors,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    if (contract == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.fileX, size: 12, color: colors.textPrimary.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              loc.latestContractNone,
              style: TextStyle(
                fontSize: 11,
                color: colors.textPrimary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final startDateStr = contract!.startDate != null
        ? DateFormat('dd.MM.yyyy').format(contract!.startDate!)
        : '-';
    final endDateStr = contract!.endDate != null
        ? DateFormat('dd.MM.yyyy').format(contract!.endDate!)
        : loc.unlimited;
    final statusLabel = contract!.status.label(loc);

    Color badgeColor = Colors.grey;
    if (contract!.status == ContractStatus.active) badgeColor = Colors.green;
    if (contract!.status == ContractStatus.pending || contract!.status == ContractStatus.negotiating) badgeColor = Colors.orange;
    if (contract!.status == ContractStatus.expired || contract!.status == ContractStatus.declined) badgeColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, size: 13, color: badgeColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              loc.contractDateRange('$startDateStr - $endDateStr'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentRow extends ConsumerWidget {
  final Map<String, dynamic> payment;
  final AgencyColorScheme colors;

  const _PendingPaymentRow({
    required this.payment,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final id = payment['id'] as String;
    final propertyId = payment['property_id'] as String;
    final title = payment['title'] as String? ?? loc.payment;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = payment['currency'] as String? ?? 'EUR';
    final month = payment['month'] as String? ?? '';
    final propertyName = payment['property_name'] as String? ?? '';
    final tenantName = payment['tenant_name'] as String? ?? '';
    final isCash = payment['is_cash'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.brandGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '$title • $tenantName ($month)',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)} $currency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (isCash)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(loc.cashPayment, style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(propertyRepositoryProvider).approveRentPayment(id, propertyId, month, DateTime.now());
                  ref.invalidate(agencyPendingPaymentsProvider);
                  ref.invalidate(agencyPropertiesProvider);
                },
                icon: const Icon(LucideIcons.check, size: 14),
                label: Text(loc.approve, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeLandlordDialog extends ConsumerStatefulWidget {
  final Property property;

  const _ChangeLandlordDialog({required this.property});

  static Future<void> show(BuildContext context, Property property) {
    return showDialog(
      context: context,
      builder: (context) => _ChangeLandlordDialog(property: property),
    );
  }

  @override
  ConsumerState<_ChangeLandlordDialog> createState() => _ChangeLandlordDialogState();
}

class _ChangeLandlordDialogState extends ConsumerState<_ChangeLandlordDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.property.landlordName ?? '';
    _emailController.text = widget.property.landlordEmail ?? '';
    _phoneController.text = widget.property.landlordPhone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = ref.watch(agencyColorSchemeProvider);

    return AlertDialog(
      title: Text(loc.changeLandlordDialogTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.changeLandlordDialogDesc,
              style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.fullName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: loc.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: loc.phone),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    final repo = ref.read(propertyRepositoryProvider);
                    final token = await repo.changePropertyLandlord(
                      propertyId: widget.property.id,
                      newLandlordName: _nameController.text.trim(),
                      newLandlordEmail: _emailController.text.trim(),
                      newLandlordPhone: _phoneController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ref.invalidate(agencyPropertiesProvider);
                      OwnershipShareSheet.show(
                        context,
                        propertyName: widget.property.name,
                        landlordName: _nameController.text.trim(),
                        landlordEmail: _emailController.text.trim(),
                        token: token,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(loc.changeAndGenerateQr),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final AgencyColorScheme colors;

  const _LoadingCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: CircularProgressIndicator(color: colors.primary),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final AgencyColorScheme colors;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: colors.textPrimary.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
