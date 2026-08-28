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
import 'package:url_launcher/url_launcher.dart';

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
      final isContractPending = contract != null &&
          (contract.status == ContractStatus.pending || contract.status == ContractStatus.negotiating);
      return isContractPending;

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
  if (url.contains('supabase.co') ||
      url.contains('localhost') ||
      url.contains('127.0.0.1') ||
      url.contains('gstatic.com') ||
      url.contains('googleusercontent.com') ||
      url.contains('google.com') ||
      url.contains('googleapis.com') ||
      url.contains('unsplash.com') ||
      url.contains('cloudinary.com') ||
      url.contains('weserv.nl')) {
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
  final maintenanceAsync = ref.watch(agencyMaintenanceRequestsProvider);
  final maintenanceList = maintenanceAsync.value ?? [];

  if (properties.isEmpty) return Stream.value([]);

  final repo = ref.watch(propertyRepositoryProvider);
  return Rx.combineLatest<List<RentPayment>, List<Map<String, dynamic>>>(
    properties.map((p) => repo.getRentPaymentsStream(p.id)),
    (List<List<RentPayment>> allPaymentsList) {
      final List<Map<String, dynamic>> result = [];
      final propertiesMap = {for (var p in properties) p.id: p};

      for (int i = 0; i < properties.length; i++) {
        final propMap = properties[i].toJson();
        for (final payment in allPaymentsList[i]) {
          final json = payment.toJson();
          json['property'] = propMap;
          json['property_id'] = properties[i].id;
          result.add(json);
        }
      }

      // Add maintenance financial settlements awaiting agency approval (pending_review with cost > 0)
      for (final m in maintenanceList) {
        final cost = (m.costAmount ?? 0.0);
        final hasValidCost = cost > 0;

        if (hasValidCost && m.paymentStatus == 'pending_review') {
          final propObj = propertiesMap[m.propertyId];
          if (propObj == null) continue;
          final propMap = propObj.toJson();

          final mJson = {
            'id': m.id,
            'property_id': m.propertyId,
            'property': propMap,
            'title': '🛠️ ${m.title}',
            'amount': cost,
            'cost_amount': cost,
            'settled_amount': m.settledAmount,
            'currency': m.currency ?? (propObj.currency.isNotEmpty ? propObj.currency : 'EUR'),
            'due_date': (m.paymentDate ?? m.createdAt ?? DateTime.now()).toIso8601String(),
            'status': 'declared',
            'receiver_type': m.paidBy == 'tenant' ? 'landlord' : 'tenant',
            'receipt_url': m.invoicePdfUrl,
            'is_maintenance': true,
            'maintenance_request': m,
            'payer_role': m.paidBy == 'tenant' ? 'tenant' : 'landlord',
            'created_at': m.createdAt?.toIso8601String(),
          };
          result.add(mJson);
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
  int? _selectedFinanceSegment;
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

    final allPaymentsAsync = ref.watch(agencyAllPaymentsProvider);
    final allPayments = allPaymentsAsync.value ?? [];

    final pendingPaymentsAsync = ref.watch(agencyPendingPaymentsProvider);
    final pendingPayments = pendingPaymentsAsync.value ?? [];

    final maintenanceRequestsAsync = ref.watch(agencyMaintenanceRequestsProvider);
    final maintenanceRequests = maintenanceRequestsAsync.value ?? [];

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
      backgroundColor: const Color(0xFFF8FAFC),
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
      floatingActionButton: _currentTab == 3
          ? null
          : FloatingActionButton.extended(
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
            // ── Tab 0: Ana Sayfa (Ajans Kokpiti) ─────────────────────────
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

                  // ── Apple Stili Bento Kokpit Kartları ─────────────────
                  _AgencyCockpitSection(
                    properties: propertiesAsync.value ?? [],
                    contractsMap: contractsMap,
                    allPayments: allPayments,
                    pendingPayments: pendingPayments,
                    maintenanceRequests: maintenanceRequests,
                    colors: colors,
                    loc: loc,
                    lang: Localizations.localeOf(context).languageCode.toLowerCase(),
                    onSelectInsight: (type) {
                      setState(() {
                        _selectedInsight = type;
                        _currentTab = 1; // Portföy tab
                      });
                    },
                    onSelectFinanceSegment: (segment) {
                      setState(() {
                        _selectedFinanceSegment = segment;
                        _currentTab = 2; // Finans tab
                      });
                    },
                    onOpenMaintenance: () {
                      setState(() {
                        _currentTab = 3; // Bakım tab
                      });
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
            AgencyFinanceTab(
              colors: colors,
              initialSegment: _selectedFinanceSegment,
            ),

            // ── Tab 3: Bakım / Talepler (Arıza & Bakım Talepleri) ─────────
            AgencyMaintenanceTab(colors: colors),
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
  String? _viewMode; // null = auto (mobile: grid, desktop: table)
  bool _isFilterExpanded = false;

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
      if (_filterBy == 'vacant' && p.tenantId != null) return false;

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
        case 'oldest':
          final dateA = a.createdAt ?? DateTime(2000);
          final dateB = b.createdAt ?? DateTime(2000);
          return dateA.compareTo(dateB);
        case 'debt':
          final hasDebtA = debtPropertyIds.contains(a.id) ? 1 : 0;
          final hasDebtB = debtPropertyIds.contains(b.id) ? 1 : 0;
          final debtComp = hasDebtB.compareTo(hasDebtA);
          if (debtComp != 0) return debtComp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'rent_desc':
          final rentA = contractsMap[a.id]?.monthlyRent ?? a.defaultMonthlyRent;
          final rentB = contractsMap[b.id]?.monthlyRent ?? b.defaultMonthlyRent;
          final rentComp = rentB.compareTo(rentA);
          if (rentComp != 0) return rentComp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'rent_asc':
          final rentA = contractsMap[a.id]?.monthlyRent ?? a.defaultMonthlyRent;
          final rentB = contractsMap[b.id]?.monthlyRent ?? b.defaultMonthlyRent;
          final rentComp = rentA.compareTo(rentB);
          if (rentComp != 0) return rentComp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'name_asc':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'city_asc':
          return (a.city ?? '').toLowerCase().compareTo((b.city ?? '').toLowerCase());
        case 'landlord_asc':
          final landA = (a.landlordName ?? a.landlordEmail ?? '').toLowerCase();
          final landB = (b.landlordName ?? b.landlordEmail ?? '').toLowerCase();
          return landA.compareTo(landB);
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
    final vacantCount = allProps.where((p) => p.tenantId == null).length;

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

  Widget _buildViewModeToggle({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 15,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
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

    final isMobile = MediaQuery.of(context).size.width < 768;
    final effectiveViewMode = _viewMode ?? (isMobile ? 'grid' : 'table');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Bento Style)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: const Icon(LucideIcons.building2, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLandlord ? loc.myProperties : loc.managedProperties,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Quick Filter Chips Bar (Always Outside & Visible)
          propertiesAsync.maybeWhen(
            data: (allProps) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChips(widget.colors, debtPropertyIds, allProps, loc),
                const SizedBox(height: 12),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          // 2. Active Insight Active Filter Indicator Bar (Always Outside & Visible)
          if (_selectedInsight != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: getInsightConfig(_selectedInsight!, loc).severityColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: getInsightConfig(_selectedInsight!, loc).severityColor.withValues(alpha: 0.25)),
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

          // 3. Collapsible Search & Grouping & Sorting Panel
          if (showSearchPanel) ...[
            InkWell(
              onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isFilterExpanded ? const Color(0xFFF1F5F9) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      size: 15,
                      color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                          ? widget.colors.primary
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.searchAndFilterPanel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                            ? widget.colors.primary
                            : const Color(0xFF334155),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loc.filterActiveLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.colors.primary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isFilterExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. Expanded Filter Form Card
            if (_isFilterExpanded) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: loc.searchPlaceholder,
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.colors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Group & Sort Dropdowns
                    Row(
                      children: [
                        // Grouping
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _groupBy,
                                isExpanded: true,
                                icon: const Icon(LucideIcons.layers, size: 14, color: Color(0xFF64748B)),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
                        const SizedBox(width: 10),

                        // Sorting
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sortBy,
                                isExpanded: true,
                                icon: const Icon(LucideIcons.arrowUpDown, size: 14, color: Color(0xFF64748B)),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                items: [
                                  DropdownMenuItem(value: 'newest', child: Text(loc.sortByNewest)),
                                  DropdownMenuItem(value: 'oldest', child: Text(loc.sortByOldest)),
                                  DropdownMenuItem(value: 'debt', child: Text(loc.sortByDebt)),
                                  DropdownMenuItem(value: 'rent_desc', child: Text(loc.sortByRentDesc)),
                                  DropdownMenuItem(value: 'rent_asc', child: Text(loc.sortByRentAsc)),
                                  DropdownMenuItem(value: 'name_asc', child: Text(loc.sortByNameAsc)),
                                  DropdownMenuItem(value: 'city_asc', child: Text(loc.sortByCityAsc)),
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
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 6),
          ],

          // View Mode & Counter Toolbar (Between Filter Card and List)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "x properties" Badge
              propertiesAsync.maybeWhen(
                data: (props) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.building2, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        loc.propertiesCount(props.length),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              // View Mode Toggle (Table vs Grid)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeToggle(
                      icon: LucideIcons.table,
                      isSelected: effectiveViewMode == 'table',
                      tooltip: loc.viewModeTable,
                      onTap: () => setState(() => _viewMode = 'table'),
                    ),
                    const SizedBox(width: 2),
                    _buildViewModeToggle(
                      icon: LucideIcons.layoutGrid,
                      isSelected: effectiveViewMode == 'grid',
                      tooltip: loc.viewModeGrid,
                      onTap: () => setState(() => _viewMode = 'grid'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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
                      if (effectiveViewMode == 'table')
                        _PropertyTableView(
                          properties: groupProps,
                          debtPropertyIds: debtPropertyIds,
                          colors: widget.colors,
                        )
                      else
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
// Agency Finance Tab Implementation (Apple & Stripe Pro Design)
// ---------------------------------------------------------------------------

class AgencyFinanceTab extends ConsumerStatefulWidget {
  final AgencyColorScheme colors;
  final int? initialSegment;

  const AgencyFinanceTab({
    super.key,
    required this.colors,
    this.initialSegment,
  });

  @override
  ConsumerState<AgencyFinanceTab> createState() => _AgencyFinanceTabState();
}

class _AgencyFinanceTabState extends ConsumerState<AgencyFinanceTab> {
  late int _selectedSegment;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'rent', 'bill', 'dues', 'deposit'
  String _groupBy = 'none'; // 'none', 'landlord', 'city', 'status'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'amount_desc', 'amount_asc', 'name_asc', 'landlord_asc'
  String? _viewMode; // null = auto (mobile: grid, desktop: table)
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment ?? 0;
  }

  @override
  void didUpdateWidget(covariant AgencyFinanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSegment != null && widget.initialSegment != oldWidget.initialSegment) {
      setState(() {
        _selectedSegment = widget.initialSegment!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildViewModeToggle({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
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

    final isMobile = MediaQuery.of(context).size.width < 768;
    final effectiveViewMode = _viewMode ?? (isMobile ? 'grid' : 'table');

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

    // 2. Girilmeyen Faturalar (Unentered / Awaiting Bills where amount == 0 for owner expense)
    final unenteredBillsList = allPayments.where((item) {
      final status = item['status'] as String? ?? 'pending';
      if (status == 'paid' || status == 'declared') return false;
      final receiverType = item['receiver_type'] as String? ?? 'owner';
      final title = item['title'] as String? ?? 'Kira';
      final isOwnerExpense = receiverType == 'owner' && title != 'Kira';
      if (!isOwnerExpense) return false;

      final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
      return amt == 0;
    }).toList();
    final unenteredCount = unenteredBillsList.length;

    // 3. Gecikmedeki Borçlar (Overdue / pending with due_date < today)
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

    // 4. Bu Ay Onaylanan (Paid this month)
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

    // Active Segment Raw List
    List<Map<String, dynamic>> rawList;
    if (_selectedSegment == 0) {
      rawList = pendingPayments;
    } else if (_selectedSegment == 1) {
      rawList = unenteredBillsList;
    } else if (_selectedSegment == 2) {
      rawList = overdueList;
    } else {
      rawList = allPayments.where((p) => p['status'] == 'paid').toList();
    }

    // 1. Search & Type Filtering
    final query = _searchQuery.trim().toLowerCase();
    var filtered = rawList.where((payment) {
      // Type Filter
      if (_typeFilter != 'all') {
        final rawTitle = (payment['title'] as String? ?? 'Kira').toLowerCase();
        if (_typeFilter == 'rent' && !(rawTitle == 'kira' || rawTitle.contains('rent'))) return false;
        if (_typeFilter == 'dues' && !rawTitle.contains('aidat') && !rawTitle.contains('due')) return false;
        if (_typeFilter == 'deposit' && !rawTitle.contains('depozit') && !rawTitle.contains('deposit')) return false;
        if (_typeFilter == 'bill' && (rawTitle == 'kira' || rawTitle.contains('rent') || rawTitle.contains('aidat') || rawTitle.contains('depozit'))) return false;
      }

      // Search Query
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
      final title = (payment['title'] as String? ?? '').toLowerCase();

      return propName.contains(query) ||
          propAddress.contains(query) ||
          city.contains(query) ||
          landlord.contains(query) ||
          tenant.contains(query) ||
          title.contains(query);
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

      final dueAStr = a['due_date'] as String? ?? a['created_at'] as String? ?? '';
      final dueBStr = b['due_date'] as String? ?? b['created_at'] as String? ?? '';

      switch (_sortBy) {
        case 'oldest':
          return dueAStr.compareTo(dueBStr);
        case 'amount_desc':
          return amountB.compareTo(amountA);
        case 'amount_asc':
          return amountA.compareTo(amountB);
        case 'name_asc':
          return nameA.compareTo(nameB);
        case 'landlord_asc':
          return landlordA.compareTo(landlordB);
        case 'newest':
        default:
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
          // Header (Bento Style)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                ),
                child: const Icon(LucideIcons.wallet, size: 18, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.financeAndPaymentsHeader,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4 Bento KPI Summary Cards (Interactive Segment Selector)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 850 ? 4 : 2;
              final cardWidth = (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financePendingApprovals,
                    count: pendingCount,
                    totals: pendingTotals,
                    color: const Color(0xFFD97706),
                    icon: LucideIcons.clock,
                    isSelected: _selectedSegment == 0,
                    onTap: () => setState(() => _selectedSegment = 0),
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.unenteredBillsTitle,
                    count: unenteredCount,
                    customHeroValue: '$unenteredCount ${loc.localeName == 'tr' ? 'Fatura' : (loc.localeName == 'ru' ? 'Счетов' : (loc.localeName.startsWith('sr') ? 'Računa' : 'Bills'))}',
                    totals: const {},
                    color: const Color(0xFFEA580C),
                    icon: LucideIcons.fileQuestion,
                    isSelected: _selectedSegment == 1,
                    onTap: () => setState(() => _selectedSegment = 1),
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financeOverduePayments,
                    count: overdueCount,
                    totals: overdueTotals,
                    color: const Color(0xFFE11D48),
                    icon: LucideIcons.alertTriangle,
                    isSelected: _selectedSegment == 2,
                    onTap: () => setState(() => _selectedSegment = 2),
                    colors: widget.colors,
                  ),
                  _FinanceKpiCard(
                    width: cardWidth,
                    title: loc.financePaidThisMonth,
                    count: paidCount,
                    totals: paidTotals,
                    color: const Color(0xFF059669),
                    icon: LucideIcons.checkCircle2,
                    isSelected: _selectedSegment == 3,
                    onTap: () => setState(() => _selectedSegment = 3),
                    colors: widget.colors,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Quick Expense Type Filter Chips Bar (Always Outside & Visible)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip('all', loc.allPropertiesGroup, _typeFilter == 'all'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('rent', loc.filterRent, _typeFilter == 'rent'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('bill', loc.filterBills, _typeFilter == 'bill'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('dues', loc.filterDues, _typeFilter == 'dues'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('deposit', loc.filterDeposit, _typeFilter == 'deposit'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Collapsible Search & Grouping & Sorting Panel Toggle
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isFilterExpanded ? const Color(0xFFF1F5F9) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 15,
                    color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                        ? widget.colors.primary
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.searchAndFilterPanel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                          ? widget.colors.primary
                          : const Color(0xFF334155),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.filterActiveLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: widget.colors.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Expanded Filter Form Card
          if (_isFilterExpanded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: loc.searchPlaceholder,
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grouping & Sorting Dropdowns Row
                  Row(
                    children: [
                      // Grouping Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _groupBy,
                              isExpanded: true,
                              icon: const Icon(LucideIcons.layers, size: 14, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
                      const SizedBox(width: 10),

                      // Sorting Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              icon: const Icon(LucideIcons.arrowUpDown, size: 14, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              items: [
                                DropdownMenuItem(value: 'newest', child: Text(loc.sortByNewest)),
                                DropdownMenuItem(value: 'oldest', child: Text(loc.sortByOldest)),
                                DropdownMenuItem(value: 'amount_desc', child: Text(loc.sortByAmountDesc)),
                                DropdownMenuItem(value: 'amount_asc', child: Text(loc.sortByAmountAsc)),
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
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),

          // View Mode & Counter Toolbar (Between Filter Card and List)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Transactions Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.receipt, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${filtered.length} ${loc.paymentRequests.toLowerCase()}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // View Mode Switcher (Table vs Grid)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeToggle(
                      icon: LucideIcons.table,
                      isSelected: effectiveViewMode == 'table',
                      tooltip: loc.viewModeTable,
                      onTap: () => setState(() => _viewMode = 'table'),
                    ),
                    const SizedBox(width: 2),
                    _buildViewModeToggle(
                      icon: LucideIcons.layoutGrid,
                      isSelected: effectiveViewMode == 'grid',
                      tooltip: loc.viewModeGrid,
                      onTap: () => setState(() => _viewMode = 'grid'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render List (Table View vs Card View & Grouping)
          if (filtered.isEmpty)
            _EmptyCard(
              icon: LucideIcons.receipt,
              message: loc.noPropertiesMatchingFilter,
              colors: widget.colors,
            )
          else if (_groupBy == 'none') ...[
            if (effectiveViewMode == 'table')
              _FinanceTableView(
                payments: filtered,
                propertiesMap: propertiesMap,
                colors: widget.colors,
                loc: loc,
                segment: _selectedSegment,
              )
            else
              ...filtered.map((payment) => _FinancePaymentItemCard(
                    payment: payment,
                    propertiesMap: propertiesMap,
                    colors: widget.colors,
                    loc: loc,
                    segment: _selectedSegment,
                  )),
          ] else ...[
            ...groupedPayments.entries.map((entry) {
              final groupTitle = entry.key;
              final groupItems = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                : (_groupBy == 'landlord' ? LucideIcons.userCheck : LucideIcons.tag),
                            size: 13,
                            color: widget.colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$groupTitle (${groupItems.length})',
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
                  if (effectiveViewMode == 'table')
                    _FinanceTableView(
                      payments: groupItems,
                      propertiesMap: propertiesMap,
                      colors: widget.colors,
                      loc: loc,
                      segment: _selectedSegment,
                    )
                  else
                    ...groupItems.map((payment) => _FinancePaymentItemCard(
                          payment: payment,
                          propertiesMap: propertiesMap,
                          colors: widget.colors,
                          loc: loc,
                          segment: _selectedSegment,
                        )),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],

          const SizedBox(height: 24),
          PoweredByStanomerFooter(textColor: widget.colors.textPrimary),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String key, String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _typeFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bento KPI Card
// ---------------------------------------------------------------------------

class _FinanceKpiCard extends StatelessWidget {
  final double width;
  final String title;
  final int count;
  final Map<String, double> totals;
  final String? customHeroValue;
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
    this.customHeroValue,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final String heroValue = customHeroValue ??
        (totals.isNotEmpty
            ? CurrencyUtils.formatCurrencyMap(
                totals,
                useSymbols: true,
                separator: ' + ',
              )
            : '$count');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    color: color.withValues(alpha: 0.12),
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              heroValue,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: totals.length > 1 ? 12 : 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// High Density Dense Finance Table View & Rows
// ---------------------------------------------------------------------------

class _FinanceTableView extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final Map<String, Property> propertiesMap;
  final AgencyColorScheme colors;
  final AppLocalizations loc;
  final int segment;

  const _FinanceTableView({
    required this.payments,
    required this.propertiesMap,
    required this.colors,
    required this.loc,
    required this.segment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 768;

        if (!isDesktop) {
          // Mobile / Small Screen: Compact List View
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final payment = payments[i];
                  return _FinanceCompactRow(
                    payment: payment,
                    propertiesMap: propertiesMap,
                    colors: colors,
                    loc: loc,
                    segment: segment,
                  );
                },
              ),
            ),
          );
        }

        // Desktop High-Density Proportional Table View
        final tableWidth = screenWidth > 980 ? screenWidth : 980.0;
        const colAction = 140.0;
        const horizontalPadding = 32.0; // 16 left + 16 right
        final usableWidth = tableWidth - horizontalPadding - colAction;
        final colProperty = usableWidth * 0.28;
        final colLandlord = usableWidth * 0.24;
        final colDueDate = usableWidth * 0.16;
        final colAmount = usableWidth * 0.16;
        final colStatus = usableWidth * 0.16;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: colProperty,
                          child: Text(
                            loc.colPropertyAndType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colLandlord,
                          child: Text(
                            '${loc.landlordLabel.toUpperCase()} / ${loc.tenantLabel.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colDueDate,
                          child: Text(
                            loc.colDueDate,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colAmount,
                          child: Text(
                            loc.colAmount,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colStatus,
                          child: Text(
                            loc.statusLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colAction,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              loc.colAction,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rows
                  ...payments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payment = entry.value;
                    final isLast = index == payments.length - 1;

                    return _FinanceTableRow(
                      payment: payment,
                      propertiesMap: propertiesMap,
                      colors: colors,
                      loc: loc,
                      segment: segment,
                      isLast: isLast,
                      colProperty: colProperty,
                      colLandlord: colLandlord,
                      colDueDate: colDueDate,
                      colAmount: colAmount,
                      colStatus: colStatus,
                      colAction: colAction,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FinanceCompactRow extends ConsumerWidget {
  final Map<String, dynamic> payment;
  final Map<String, Property> propertiesMap;
  final AgencyColorScheme colors;
  final AppLocalizations loc;
  final int segment;

  const _FinanceCompactRow({
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
    final dueDateFormatted = dueDate != null ? DateFormat('dd MMM yyyy', loc.localeName).format(dueDate) : null;

    final rawMonth = payment['month'] as String?;
    String periodText = '';
    if (rawMonth != null && rawMonth.trim().isNotEmpty && rawMonth != localizedTitle && rawMonth != rawTitle) {
      periodText = rawMonth;
    } else if (dueDate != null) {
      periodText = DateFormat('MMMM yyyy', loc.localeName).format(dueDate);
    }
    final isCash = payment['is_cash'] == true;
    final status = payment['status'] as String? ?? 'pending';

    final propertyData = payment['property'] as Map<String, dynamic>?;
    final propertyName = propertyData?['name'] as String? ?? pObj?.name ?? loc.managedProperties;

    final targetProperty = pObj ?? (propertyData != null && propertyData['id'] != null ? Property.fromJson(propertyData) : null);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = (status == 'overdue') || (status == 'pending' && dueDate != null && dueDate.isBefore(today) && amount > 0);

    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.building2, size: 17, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    propertyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            localizedTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dueDateFormatted ?? (periodText.isNotEmpty ? periodText : '—'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount > 0 ? '${amount.toStringAsFixed(0)} $currency' : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (isCash) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          loc.cashBadge,
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'paid'
                        ? const Color(0xFFECFDF5)
                        : (isOverdue ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status == 'paid' ? loc.filterActiveLabel : (isOverdue ? loc.statusOverdue : loc.statusPending),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: status == 'paid'
                          ? const Color(0xFF065F46)
                          : (isOverdue ? const Color(0xFFE11D48) : const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _FinanceTableRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> payment;
  final Map<String, Property> propertiesMap;
  final AgencyColorScheme colors;
  final AppLocalizations loc;
  final int segment;
  final bool isLast;
  final double colProperty;
  final double colLandlord;
  final double colDueDate;
  final double colAmount;
  final double colStatus;
  final double colAction;

  const _FinanceTableRow({
    required this.payment,
    required this.propertiesMap,
    required this.colors,
    required this.loc,
    required this.segment,
    required this.isLast,
    required this.colProperty,
    required this.colLandlord,
    required this.colDueDate,
    required this.colAmount,
    required this.colStatus,
    required this.colAction,
  });

  @override
  ConsumerState<_FinanceTableRow> createState() => _FinanceTableRowState();
}

class _FinanceTableRowState extends ConsumerState<_FinanceTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final id = payment['id'] as String;
    final propertyId = payment['property_id'] as String? ?? '';
    final pObj = widget.propertiesMap[propertyId];

    final amount = (payment['amount'] as num?)?.toDouble() ??
        (payment['total_amount'] as num?)?.toDouble() ??
        (payment['rent_amount'] as num?)?.toDouble() ??
        0.0;
    final currency = payment['currency'] as String? ?? pObj?.currency ?? 'EUR';

    final rawTitle = payment['title'] as String? ?? 'Kira';
    final localizedTitle = ExpenseUtils.getLocalizedExpenseName(rawTitle, widget.loc);

    final dueDateStr = payment['due_date'] as String?;
    final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
    final dueDateFormatted = dueDate != null ? DateFormat('dd MMM yyyy', widget.loc.localeName).format(dueDate) : null;

    final rawMonth = payment['month'] as String?;
    String periodText = '';
    if (rawMonth != null && rawMonth.trim().isNotEmpty && rawMonth != localizedTitle && rawMonth != rawTitle) {
      periodText = rawMonth;
    } else if (dueDate != null) {
      periodText = DateFormat('MMMM yyyy', widget.loc.localeName).format(dueDate);
    }
    final isCash = payment['is_cash'] == true;
    final receiverType = payment['receiver_type'] as String? ?? 'owner';
    final status = payment['status'] as String? ?? 'pending';
    final receiptUrl = payment['receipt_url'] as String?;

    // Property info extraction
    final propertyData = payment['property'] as Map<String, dynamic>?;
    final propertyName = propertyData?['name'] as String? ?? pObj?.name ?? widget.loc.managedProperties;
    final cityName = propertyData?['city'] as String? ?? pObj?.city ?? '';

    // Landlord & Tenant info extraction
    final landlordData = propertyData?['landlord'] as Map<String, dynamic>?;
    final landlordName = landlordData?['full_name'] as String? ??
        pObj?.landlordName ??
        (landlordData?['email'] as String? ?? pObj?.landlordEmail ?? widget.loc.groupLandlordPendingInvite);

    final contractsMap = ref.watch(agencyContractsMapProvider).value ?? {};
    final contract = contractsMap[propertyId];

    final tenantData = payment['tenant'] as Map<String, dynamic>?;
    final rawTenantName = tenantData?['full_name'] as String? ?? pObj?.tenantName;
    final tenantEmail = tenantData?['email'] as String? ?? contract?.inviteeEmail;

    final String tenantName;
    if (rawTenantName != null && rawTenantName.trim().isNotEmpty) {
      tenantName = rawTenantName;
    } else if (tenantEmail != null && tenantEmail.trim().isNotEmpty) {
      tenantName = tenantEmail;
    } else {
      tenantName = widget.loc.tenantLabel;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = (status == 'overdue') || (status == 'pending' && dueDate != null && dueDate.isBefore(today) && amount > 0);
    final daysOverdue = dueDate != null && dueDate.isBefore(today) ? today.difference(dueDate).inDays : 0;

    final targetProperty = pObj ?? (propertyData != null && propertyData['id'] != null ? Property.fromJson(propertyData) : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: widget.isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              // 1. Property & Expense Title / Type
              SizedBox(
                width: widget.colProperty,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.building2, size: 15, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propertyName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    localizedTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                              if (cityName.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '· $cityName',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Landlord & Tenant
              SizedBox(
                width: widget.colLandlord,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.userCheck, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            landlordName,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            tenantName,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Due Date / Period
              SizedBox(
                width: widget.colDueDate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dueDateFormatted ?? (periodText.isNotEmpty ? periodText : '—'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? const Color(0xFFE11D48) : const Color(0xFF334155),
                      ),
                    ),
                    if (isOverdue && daysOverdue > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.loc.daysOverdue(daysOverdue),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                      ),
                    ],
                  ],
                ),
              ),

              // 4. Amount
              SizedBox(
                width: widget.colAmount,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amount > 0 ? '${amount.toStringAsFixed(0)} $currency' : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (isCash) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.loc.cashBadge,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 5. Status Badge
              SizedBox(
                width: widget.colStatus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: () {
                    if (status == 'paid') {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          widget.loc.filterActiveLabel,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                        ),
                      );
                    } else if (status == 'declared') {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          widget.loc.financePendingApprovals,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      );
                    } else if (isOverdue) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFE4E6)),
                        ),
                        child: Text(
                          widget.loc.statusOverdue,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                        ),
                      );
                    } else if (amount == 0 && receiverType == 'owner' && rawTitle != 'Kira') {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Text(
                          widget.loc.unenteredBillsTitle,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      );
                    }
                  }(),
                ),
              ),

              // 6. Action Buttons
              SizedBox(
                width: widget.colAction,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Receipt dialog button
                    if (receiptUrl != null &&
                        receiptUrl.isNotEmpty &&
                        receiptUrl != 'CASH' &&
                        !isCash &&
                        (receiptUrl.startsWith('http://') || receiptUrl.startsWith('https://'))) ...[
                      IconButton(
                        icon: const Icon(LucideIcons.fileText, size: 15, color: Color(0xFF2563EB)),
                        tooltip: widget.loc.viewReceipt,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(widget.loc.viewReceipt),
                              content: Image.network(
                                receiptUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(widget.loc.cannotOpenDocument),
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
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Quick Approve for Declared
                    if (widget.segment == 0 || status == 'declared') ...[
                      IconButton(
                        icon: const Icon(LucideIcons.check, size: 15, color: Color(0xFF059669)),
                        tooltip: widget.loc.approvePayment,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () async {
                          try {
                            if (widget.payment['is_maintenance'] == true) {
                              final mRepo = ref.read(maintenanceRepositoryProvider);
                              final mReq = widget.payment['maintenance_request'] as MaintenanceRequest?;
                              final payerRole = (widget.payment['payer_role'] as String?) ?? mReq?.paidBy ?? 'landlord';
                              final isLandlordResponsibility = payerRole == 'landlord';
                              final targetStatus = isLandlordResponsibility ? 'pending_payment' : 'paid';
                              final resolvedAmount = mReq?.costAmount ?? (widget.payment['cost_amount'] as num?)?.toDouble() ?? (widget.payment['amount'] as num?)?.toDouble();

                              await mRepo.updateFinancialDetails(
                                requestId: id,
                                propertyId: propertyId,
                                costAmount: resolvedAmount,
                                settledAmount: isLandlordResponsibility ? 0.0 : (resolvedAmount ?? 0.0),
                                currency: (widget.payment['currency'] as String?) ?? mReq?.currency,
                                paidBy: payerRole,
                                paymentDate: DateTime.now(),
                                paymentStatus: targetStatus,
                                invoicePdfUrl: (widget.payment['receipt_url'] as String?) ?? mReq?.invoicePdfUrl,
                              );
                              try {
                                final msg = isLandlordResponsibility
                                    ? '💰 ${widget.payment['amount']} ${widget.payment['currency']} tutarındaki masraf acente tarafından onaylandı. Kiradan düşülebilir / mahsup edilebilir.'
                                    : '💰 ${widget.payment['amount']} ${widget.payment['currency']} tutarındaki bakım ödemesi acente tarafından onaylandı ve kapatıldı.';
                                await mRepo.addMessage(
                                  id,
                                  propertyId,
                                  msg,
                                );
                              } catch (_) {}
                              ref.invalidate(agencyMaintenanceRequestsProvider);
                            } else {
                              final propRepo = ref.read(propertyRepositoryProvider);
                              final monthName = periodText.isNotEmpty ? periodText : 'Kira';
                              await propRepo.approveRentPayment(id, propertyId, monthName, dueDate ?? DateTime.now());
                            }

                            ref.invalidate(agencyPendingPaymentsProvider);
                            ref.invalidate(agencyAllPaymentsProvider);
                            ref.invalidate(agencyPropertiesProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ödeme onaylandı.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Onay hatası: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],

                    // Chevron Detail button
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),
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
  final int segment; // 0: Onay Kuyruğu, 1: Girilmeyen Faturalar, 2: Borçlular, 3: Tüm Geçmiş

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
    final dueDateFormatted = dueDate != null ? DateFormat('dd MMM yyyy', loc.localeName).format(dueDate) : null;

    final rawMonth = payment['month'] as String?;
    String periodText = '';
    if (rawMonth != null && rawMonth.trim().isNotEmpty && rawMonth != localizedTitle && rawMonth != rawTitle) {
      periodText = rawMonth;
    } else if (dueDate != null) {
      periodText = DateFormat('MMMM yyyy', loc.localeName).format(dueDate);
    }
    final isCash = payment['is_cash'] == true;
    final receiverType = payment['receiver_type'] as String? ?? 'owner';
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

    final contractsMap = ref.watch(agencyContractsMapProvider).value ?? {};
    final contract = contractsMap[propertyId];

    final tenantData = payment['tenant'] as Map<String, dynamic>?;
    final rawTenantName = tenantData?['full_name'] as String? ?? pObj?.tenantName;
    final tenantEmail = tenantData?['email'] as String? ?? contract?.inviteeEmail;

    final String tenantName;
    if (rawTenantName != null && rawTenantName.trim().isNotEmpty) {
      tenantName = rawTenantName;
    } else if (tenantEmail != null && tenantEmail.trim().isNotEmpty) {
      tenantName = tenantEmail;
    } else {
      tenantName = loc.tenantLabel;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = (status == 'overdue') || (status == 'pending' && dueDate != null && dueDate.isBefore(today) && amount > 0);
    final daysOverdue = dueDate != null && dueDate.isBefore(today) ? today.difference(dueDate).inDays : 0;

    final targetProperty = pObj ?? (propertyData != null && propertyData['id'] != null ? Property.fromJson(propertyData) : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFDA4AF)
              : (segment == 0
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFE2E8F0)),
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                        color: isOverdue
                            ? const Color(0xFFFFF1F2)
                            : (segment == 0
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFF2563EB).withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOverdue
                            ? LucideIcons.alertTriangle
                            : (segment == 0 ? LucideIcons.clock : LucideIcons.building),
                        size: 18,
                        color: isOverdue
                            ? const Color(0xFFE11D48)
                            : (segment == 0 ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
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
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF64748B)),
                                      const SizedBox(width: 3),
                                      Text(
                                        cityName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
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
                          amount > 0 ? '${amount.toStringAsFixed(0)} $currency' : '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          periodText.isNotEmpty ? '$localizedTitle · $periodText' : localizedTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Landlord & Tenant Clean Display
                Row(
                  children: [
                    // Landlord Info
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userCheck, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                                children: [
                                  TextSpan(
                                    text: '${loc.landlordLabel}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
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
                          const Icon(LucideIcons.user, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                                children: [
                                  TextSpan(
                                    text: '${loc.tenantLabel}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
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
                    if (dueDateFormatted != null || periodText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.calendar, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              dueDateFormatted != null
                                  ? '${loc.localeName == 'tr' ? 'Vade:' : 'Due:'} $dueDateFormatted'
                                  : periodText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
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
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFE4E6)),
                        ),
                        child: Text(
                          loc.daysOverdue(daysOverdue),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    if (isCash) ...[
                      if (daysOverdue > 0 && status != 'paid') const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.cashPayment,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    ...() {
                      final hasValidReceipt = receiptUrl != null &&
                          receiptUrl.isNotEmpty &&
                          receiptUrl != 'CASH' &&
                          !isCash &&
                          (receiptUrl.startsWith('http://') || receiptUrl.startsWith('https://'));

                      if (!hasValidReceipt) return <Widget>[];

                      return [
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
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            foregroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ];
                    }(),
                  ],
                ),

                const SizedBox(height: 10),

                // Action Buttons Section
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
                              if (payment['is_maintenance'] == true) {
                                final mRepo = ref.read(maintenanceRepositoryProvider);
                                final mReq = payment['maintenance_request'] as MaintenanceRequest?;
                                await mRepo.updateFinancialDetails(
                                  requestId: id,
                                  propertyId: propertyId,
                                  costAmount: mReq?.costAmount ?? (payment['cost_amount'] as num?)?.toDouble(),
                                  settledAmount: mReq?.settledAmount ?? (payment['settled_amount'] as num?)?.toDouble() ?? 0.0,
                                  currency: (payment['currency'] as String?) ?? mReq?.currency,
                                  paidBy: (payment['payer_role'] as String?) ?? mReq?.paidBy,
                                  paymentDate: null,
                                  paymentStatus: 'pending_payment',
                                  invoicePdfUrl: null,
                                );
                                try {
                                  await mRepo.addMessage(
                                    id,
                                    propertyId,
                                    '⚠️ ${payment['amount']} ${payment['currency']} tutarındaki bakım ödemesi acente tarafından reddedildi.',
                                  );
                                } catch (_) {}
                                ref.invalidate(agencyMaintenanceRequestsProvider);
                              } else {
                                final propRepo = ref.read(propertyRepositoryProvider);
                                final monthName = periodText.isNotEmpty ? periodText : 'Kira';
                                await propRepo.rejectRentPayment(id, propertyId, monthName, dueDate ?? DateTime.now());
                              }

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
                            backgroundColor: const Color(0xFFFFF1F2),
                            foregroundColor: const Color(0xFFE11D48),
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
                              if (payment['is_maintenance'] == true) {
                                final mRepo = ref.read(maintenanceRepositoryProvider);
                                final mReq = payment['maintenance_request'] as MaintenanceRequest?;
                                final payerRole = (payment['payer_role'] as String?) ?? mReq?.paidBy ?? 'landlord';
                                final isLandlordResponsibility = payerRole == 'landlord';
                                final targetStatus = isLandlordResponsibility ? 'pending_payment' : 'paid';
                                final resolvedAmount = mReq?.costAmount ?? (payment['cost_amount'] as num?)?.toDouble() ?? (payment['amount'] as num?)?.toDouble();

                                await mRepo.updateFinancialDetails(
                                  requestId: id,
                                  propertyId: propertyId,
                                  costAmount: resolvedAmount,
                                  settledAmount: isLandlordResponsibility ? 0.0 : (resolvedAmount ?? 0.0),
                                  currency: (payment['currency'] as String?) ?? mReq?.currency,
                                  paidBy: payerRole,
                                  paymentDate: DateTime.now(),
                                  paymentStatus: targetStatus,
                                  invoicePdfUrl: (payment['receipt_url'] as String?) ?? mReq?.invoicePdfUrl,
                                );
                                try {
                                  final msg = isLandlordResponsibility
                                      ? '💰 ${payment['amount']} ${payment['currency']} tutarındaki masraf acente tarafından onaylandı. Kiradan düşülebilir / mahsup edilebilir.'
                                      : '💰 ${payment['amount']} ${payment['currency']} tutarındaki bakım ödemesi acente tarafından onaylandı ve kapatıldı.';
                                  await mRepo.addMessage(
                                    id,
                                    propertyId,
                                    msg,
                                  );
                                } catch (_) {}
                                ref.invalidate(agencyMaintenanceRequestsProvider);
                              } else {
                                final propRepo = ref.read(propertyRepositoryProvider);
                                final monthName = periodText.isNotEmpty ? periodText : 'Kira';
                                await propRepo.approveRentPayment(id, propertyId, monthName, dueDate ?? DateTime.now());
                              }

                              ref.invalidate(agencyPendingPaymentsProvider);
                              ref.invalidate(agencyAllPaymentsProvider);
                              ref.invalidate(agencyPropertiesProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ödeme başarıyla onaylandı.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Onay hatası: $e'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.check, size: 14),
                          label: Text(
                            loc.approvePayment,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ]
                      // Segment 1: Girilmeyen Faturalar (Fatura Gir Butonu)
                      else if (segment == 1 || (amount == 0 && receiverType == 'owner' && rawTitle != 'Kira')) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            final targetProperty = propertiesMap[propertyId];
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
                          icon: const Icon(LucideIcons.filePlus, size: 14),
                          label: Text(
                            loc.enterBill,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ]
                      // Segment 2: Gecikmedeki Borçlar Actions
                      else if (segment == 2 || status == 'overdue' || (status == 'pending' && amount > 0)) ...[
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
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF334155),
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
                      // Status Indicator Badge
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'paid'
                                ? const Color(0xFFECFDF5)
                                : (status == 'declared' ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: status == 'paid'
                                  ? const Color(0xFFA7F3D0)
                                  : (status == 'declared' ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'paid'
                                  ? const Color(0xFF065F46)
                                  : (status == 'declared' ? const Color(0xFFB45309) : const Color(0xFF64748B)),
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

class AgencyMaintenanceTab extends ConsumerStatefulWidget {
  final AgencyColorScheme colors;

  const AgencyMaintenanceTab({super.key, required this.colors});

  @override
  ConsumerState<AgencyMaintenanceTab> createState() => _AgencyMaintenanceTabState();
}

class _AgencyMaintenanceTabState extends ConsumerState<AgencyMaintenanceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _groupBy = 'none'; // 'none', 'status', 'priority', 'category', 'property'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'priority_desc', 'title_asc'
  String? _selectedKpiFilter; // null, 'urgent', 'active', 'resolved'
  bool _isFilterExpanded = false;
  String? _viewMode; // null = auto (mobile: grid, desktop: table)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildViewModeToggle({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 15,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

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
          'view_detail': 'Detayı Gör',
          'col_priority': 'Öncelik',
          'col_issue_status': 'Arıza Durumu',
          'col_payment_status': 'Ödeme / Masraf',
          'col_date': 'Tarih',
          'no_financials': 'Masraf Belirtilmedi',
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
          'view_detail': 'Pogledaj Detalje',
          'col_priority': 'Prioritet',
          'col_issue_status': 'Status Kvara',
          'col_payment_status': 'Plaćanje / Trošak',
          'col_date': 'Datum',
          'no_financials': 'Nema troška',
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
          'view_detail': 'Подробнее',
          'col_priority': 'Приоритет',
          'col_issue_status': 'Статус Заявки',
          'col_payment_status': 'Оплата / Расход',
          'col_date': 'Дата',
          'no_financials': 'Без расходов',
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
          'view_detail': 'View Details',
          'col_priority': 'Priority',
          'col_issue_status': 'Issue Status',
          'col_payment_status': 'Payment & Cost',
          'col_date': 'Date',
          'no_financials': 'No cost assigned',
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

    final isMobile = MediaQuery.of(context).size.width < 768;
    final effectiveViewMode = _viewMode ?? (isMobile ? 'grid' : 'table');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Luxury Bento Style)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.colors.primary.withValues(alpha: 0.25)),
                ),
                child: Icon(LucideIcons.wrench, size: 19, color: widget.colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.maintenanceRequestsHeader,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 768 ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          requestsAsync.when(
            data: (rawRequests) {
              // Ensure only requests belonging to the user's properties are included
              final userPropertyIds = properties.map((p) => p.id).toSet();
              final allRequests = properties.isNotEmpty
                  ? rawRequests.where((r) => userPropertyIds.contains(r.propertyId)).toList()
                  : rawRequests;

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
                  // --- INTERACTIVE BENTO KPI SUMMARY STRIP ---
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
                            color: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFFF1F2),
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
                            bgColor: const Color(0xFFFFFBEB),
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
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
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
                            color: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
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
                        borderRadius: BorderRadius.circular(14),
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
                                  fontWeight: FontWeight.w700,
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

                  // --- COLLAPSIBLE SEARCH & FILTERS TOGGLE ---
                  InkWell(
                    onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isFilterExpanded ? const Color(0xFFF1F5F9) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.slidersHorizontal,
                            size: 15,
                            color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                                ? widget.colors.primary
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.searchAndFilterPanel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest' || _isFilterExpanded)
                                  ? widget.colors.primary
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _groupBy != 'none' || _sortBy != 'newest') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.filterActiveLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: widget.colors.primary,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          AnimatedRotation(
                            turns: _isFilterExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- LINEAR / APPLE PRO TOOLBAR (SEARCH & FILTERS) ---
                  if (_isFilterExpanded) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: txt['search_hint'],
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.colors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Group & Sort Dropdowns
                          Row(
                            children: [
                              // Grouping
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _groupBy,
                                      isExpanded: true,
                                      icon: const Icon(LucideIcons.layers, size: 14, color: Color(0xFF64748B)),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
                              const SizedBox(width: 10),

                              // Sorting
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _sortBy,
                                      isExpanded: true,
                                      icon: const Icon(LucideIcons.arrowUpDown, size: 14, color: Color(0xFF64748B)),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 6),

                  // --- VIEW MODE & COUNTER TOOLBAR (Between Filter Card and List) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Requests Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.wrench, size: 13, color: widget.colors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${filtered.length} ${txt['request_unit']?.toLowerCase() ?? loc.tabRequests.toLowerCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // View Mode Selector (Dense Segmented Control)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewModeToggle(
                              icon: LucideIcons.table,
                              isSelected: effectiveViewMode == 'table',
                              tooltip: loc.viewModeTable,
                              onTap: () => setState(() => _viewMode = 'table'),
                            ),
                            const SizedBox(width: 2),
                            _buildViewModeToggle(
                              icon: LucideIcons.layoutGrid,
                              isSelected: effectiveViewMode == 'grid',
                              tooltip: loc.viewModeGrid,
                              onTap: () => setState(() => _viewMode = 'grid'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // --- REQUEST LIST (TABLE OR CARDS) ---
                  if (filtered.isEmpty)
                    _EmptyCard(
                      icon: LucideIcons.clipboardCheck,
                      message: _searchQuery.isNotEmpty ? txt['no_search_results']! : loc.noOpenRequestsYet,
                      colors: widget.colors,
                    )
                  else if (effectiveViewMode == 'table')
                    _MaintenanceTableView(
                      requests: filtered,
                      properties: properties,
                      loc: loc,
                      txt: txt,
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
    required Color bgColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final badgeStr = customBadge ?? '$count';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 20 : 10,
              offset: Offset(0, isSelected ? 6 : 2),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isSelected ? color : bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    badgeStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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
            padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((req) => _buildRequestCard(req, properties, loc, txt)),
          const SizedBox(height: 8),
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
    final property = properties.firstWhere(
      (p) => p.id == req.propertyId,
      orElse: () => Property(
        id: req.propertyId,
        landlordId: '',
        name: txt['property_detail']!,
        address: txt['managed_unit']!,
        defaultMonthlyRent: 0,
      ),
    );

    return _MaintenanceTicketCard(
      req: req,
      property: property,
      loc: loc,
      txt: txt,
      colors: widget.colors,
    );
  }

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing:
        return loc.categoryPlumbing;
      case MaintenanceCategory.electrical:
        return loc.categoryElectrical;
      case MaintenanceCategory.heating:
        return loc.categoryHeating;
      case MaintenanceCategory.internet:
        return loc.categoryInternet;
      case MaintenanceCategory.appliance:
        return loc.categoryAppliance;
      case MaintenanceCategory.structural:
        return loc.categoryStructural;
      case MaintenanceCategory.other:
        return loc.categoryOther;
    }
  }
}

class _MaintenanceTicketCard extends StatefulWidget {
  final MaintenanceRequest req;
  final Property property;
  final AppLocalizations loc;
  final Map<String, String> txt;
  final AgencyColorScheme colors;

  const _MaintenanceTicketCard({
    required this.req,
    required this.property,
    required this.loc,
    required this.txt,
    required this.colors,
  });

  @override
  State<_MaintenanceTicketCard> createState() => _MaintenanceTicketCardState();
}

class _MaintenanceTicketCardState extends State<_MaintenanceTicketCard> {
  bool _isHovered = false;

  IconData _getCategoryIcon(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing:
        return LucideIcons.droplets;
      case MaintenanceCategory.electrical:
        return LucideIcons.zap;
      case MaintenanceCategory.heating:
        return LucideIcons.flame;
      case MaintenanceCategory.internet:
        return LucideIcons.wifi;
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
        return LucideIcons.wrench;
    }
  }

  Color _getCategoryColor(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing:
        return const Color(0xFF0284C7);
      case MaintenanceCategory.electrical:
        return const Color(0xFFD97706);
      case MaintenanceCategory.heating:
        return const Color(0xFFEA580C);
      case MaintenanceCategory.internet:
        return const Color(0xFF2563EB);
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
        return const Color(0xFF9333EA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    final property = widget.property;
    final loc = widget.loc;
    final txt = widget.txt;

    // Status mapping (Soft Tinted)
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusColor = const Color(0xFF475569);
    Color statusDotColor = const Color(0xFF94A3B8);
    String statusText = 'Bilinmiyor';

    switch (req.status) {
      case MaintenanceStatus.open:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
        statusDotColor = const Color(0xFFD97706);
        statusText = loc.statusActive;
        break;
      case MaintenanceStatus.investigating:
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        statusDotColor = const Color(0xFF2563EB);
        statusText = loc.statusInvestigating;
        break;
      case MaintenanceStatus.inProgress:
        statusBg = const Color(0xFFFFF7ED);
        statusColor = const Color(0xFFC2410C);
        statusDotColor = const Color(0xFFEA580C);
        statusText = txt['status_technician_sent']!;
        break;
      case MaintenanceStatus.resolved:
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF065F46);
        statusDotColor = const Color(0xFF10B981);
        statusText = loc.statusResolved;
        break;
      case MaintenanceStatus.closed:
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF64748B);
        statusDotColor = const Color(0xFF94A3B8);
        statusText = txt['status_closed']!;
        break;
      case MaintenanceStatus.pending:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFD97706);
        statusDotColor = const Color(0xFFF59E0B);
        statusText = txt['status_pending']!;
        break;
      case MaintenanceStatus.cancelled:
        statusBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
        statusDotColor = const Color(0xFFEF4444);
        statusText = txt['status_cancelled']!;
        break;
    }

    // Priority mapping (Soft Tinted)
    final isUrgent = req.priority == MaintenancePriority.urgent;
    final isHigh = req.priority == MaintenancePriority.high;
    final categoryColor = _getCategoryColor(req.category);
    final categoryIcon = _getCategoryIcon(req.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.colors.primary.withValues(alpha: 0.35)
                : (isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
            width: _isHovered || isUrgent ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.055 : 0.025),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 5 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Squircle + Property Info + Status & Priority Badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Squircle Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(categoryIcon, size: 16, color: categoryColor),
                      ),
                      const SizedBox(width: 12),

                      // Property Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.name.isNotEmpty ? property.name : property.address,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (property.address.isNotEmpty && property.name.isNotEmpty)
                              Text(
                                property.address,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      // Priority Badge (if urgent/high)
                      if (isUrgent || isHigh) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUrgent ? const Color(0xFFFFE4E6) : const Color(0xFFFFEDD5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.alertTriangle,
                                size: 10,
                                color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUrgent ? txt['urgent_badge']! : txt['high_badge']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Status Badge with Dot Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                color: statusDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Issue Title
                  Text(
                    req.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (req.description != null && req.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      req.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  _buildFinancialRow(req, context, loc, txt),
                  const SizedBox(height: 14),

                  // Footer Divider & Meta info
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date info
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(
                              req.createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(req.createdAt!) : '-',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        // Action arrow with hover slide
                        Row(
                          children: [
                            Text(
                              txt['view_detail']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isHovered ? widget.colors.primary : const Color(0xFF64748B),
                              ),
                            ),
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.only(left: _isHovered ? 6 : 2),
                              child: Icon(
                                LucideIcons.arrowRight,
                                size: 13,
                                color: _isHovered ? widget.colors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialRow(MaintenanceRequest req, BuildContext context, AppLocalizations loc, Map<String, String> txt) {
    if (req.costAmount == null && req.invoicePdfUrl == null) {
      return const SizedBox.shrink();
    }

    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    String tenantLabel;
    String landlordLabel;
    String pendingReviewLabel;
    String pendingPaymentLabel;
    String paidLabel;
    String rejectedLabel;

    switch (lang) {
      case 'tr':
        tenantLabel = 'Kiracı';
        landlordLabel = 'Ev Sahibi';
        pendingReviewLabel = 'İnceleme Bekliyor';
        pendingPaymentLabel = 'Ödeme Bekliyor';
        paidLabel = 'Ödendi';
        rejectedLabel = 'Reddedildi';
        break;
      case 'sr':
        tenantLabel = 'Stanar';
        landlordLabel = 'Vlasnik';
        pendingReviewLabel = 'Čeka proveru';
        pendingPaymentLabel = 'Čeka plaćanje';
        paidLabel = 'Plaćeno';
        rejectedLabel = 'Odbijeno';
        break;
      case 'ru':
        tenantLabel = 'Арендатор';
        landlordLabel = 'Владелец';
        pendingReviewLabel = 'На проверке';
        pendingPaymentLabel = 'Ожидает оплаты';
        paidLabel = 'Оплачено';
        rejectedLabel = 'Отклонено';
        break;
      default:
        tenantLabel = 'Tenant';
        landlordLabel = 'Landlord';
        pendingReviewLabel = 'Pending Review';
        pendingPaymentLabel = 'Pending Payment';
        paidLabel = 'Paid';
        rejectedLabel = 'Rejected';
        break;
    }

    Color finStatusColor;
    Color finStatusBg;
    IconData finStatusIcon;
    String finStatusLabel;

    switch (req.financialStatus) {
      case MaintenancePaymentStatus.pendingReview:
        finStatusColor = const Color(0xFF1A5EB8);
        finStatusBg = const Color(0xFFEBF3FC);
        finStatusIcon = LucideIcons.fileSearch;
        finStatusLabel = pendingReviewLabel;
        break;
      case MaintenancePaymentStatus.pendingPayment:
        finStatusColor = const Color(0xFFB06C10);
        finStatusBg = const Color(0xFFFEF6E8);
        finStatusIcon = LucideIcons.clock;
        finStatusLabel = pendingPaymentLabel;
        break;
      case MaintenancePaymentStatus.paid:
        finStatusColor = const Color(0xFF2DB87A);
        finStatusBg = const Color(0xFFE6F7F0);
        finStatusIcon = LucideIcons.checkCircle2;
        finStatusLabel = paidLabel;
        break;
      case MaintenancePaymentStatus.rejected:
        finStatusColor = const Color(0xFFC8503A);
        finStatusBg = const Color(0xFFFDF0EE);
        finStatusIcon = LucideIcons.xCircle;
        finStatusLabel = rejectedLabel;
        break;
    }

    final currency = req.currency ?? (widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR');

    String dateLabel = '';
    IconData dateIcon = LucideIcons.calendar;
    Color dateColor = const Color(0xFF64748B);
    Color dateBg = const Color(0xFFF1F5F9);

    if (req.financialStatus == MaintenancePaymentStatus.paid) {
      final pDate = req.paymentDate ?? req.updatedAt ?? req.createdAt;
      final dateStr = pDate != null ? DateFormat('dd.MM.yyyy').format(pDate) : '-';
      dateLabel = '${loc.paymentDate}: $dateStr';
      dateIcon = LucideIcons.checkCircle2;
      dateColor = const Color(0xFF065F46);
      dateBg = const Color(0xFFECFDF5);
    } else if (req.paymentDate != null) {
      final dateStr = DateFormat('dd.MM.yyyy').format(req.paymentDate!);
      dateLabel = '${loc.dueDatePrefix}: $dateStr';
      dateIcon = LucideIcons.clock;
      dateColor = const Color(0xFFB45309);
      dateBg = const Color(0xFFFFFBEB);
    } else if (req.createdAt != null) {
      final dateStr = DateFormat('dd.MM.yyyy').format(req.createdAt!);
      dateLabel = '${loc.tblDate}: $dateStr';
      dateIcon = LucideIcons.calendar;
      dateColor = const Color(0xFF475569);
      dateBg = const Color(0xFFF1F5F9);
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Amount + Payer + Status Badge
          Row(
            children: [
              // Cost Amount
              if (req.costAmount != null) ...[
                Text(
                  '${req.costAmount!.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Payer badge
              if (req.paidBy != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (req.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        req.paidBy == 'tenant' ? LucideIcons.user : LucideIcons.home,
                        size: 10,
                        color: req.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        req.paidBy == 'tenant' ? tenantLabel : landlordLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: req.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Payment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: finStatusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: finStatusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(finStatusIcon, size: 11, color: finStatusColor),
                    const SizedBox(width: 4),
                    Text(
                      finStatusLabel,
                      style: TextStyle(
                        color: finStatusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Date Info + Clickable Invoice Link
          Row(
            children: [
              // Date Badge (Due Date or Payment Date)
              if (dateLabel.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: dateBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(dateIcon, size: 11, color: dateColor),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: dateColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Clickable Invoice Link
              if (req.invoicePdfUrl != null && req.invoicePdfUrl!.isNotEmpty) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse(req.invoicePdfUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.fileText, size: 11, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            loc.viewReceipt,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B2B SaaS (Linear + Stripe + Ramp) Precision Data Table & Rows
// ---------------------------------------------------------------------------

class _MaintenanceTableView extends StatelessWidget {
  final List<MaintenanceRequest> requests;
  final List<Property> properties;
  final AppLocalizations loc;
  final Map<String, String> txt;
  final AgencyColorScheme colors;

  const _MaintenanceTableView({
    required this.requests,
    required this.properties,
    required this.loc,
    required this.txt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final propertiesMap = {for (var p in properties) p.id: p};
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Comfortable minimum table width so columns never crunch
        final tableWidth = screenWidth > 1150 ? screenWidth : 1150.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // SaaS Table Header Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 48,
                          child: Text(
                            'ID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 28,
                          child: Text(
                            loc.tblRequestProperty.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Text(
                            loc.tblPriority.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 14,
                          child: Text(
                            loc.tblIssueStatus.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 15,
                          child: Text(
                            loc.tblCostPayer.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Text(
                            loc.tblFinancialStatus.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 11,
                          child: Text(
                            loc.tblDate.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 40,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'İŞLEM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SaaS Table Rows
                  ...requests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final req = entry.value;
                    final isLast = index == requests.length - 1;
                    final prop = propertiesMap[req.propertyId] ??
                        Property(
                          id: req.propertyId,
                          landlordId: '',
                          name: txt['property_detail']!,
                          address: txt['managed_unit']!,
                          defaultMonthlyRent: 0,
                        );

                    return _MaintenanceSaasRow(
                      index: index + 1,
                      req: req,
                      property: prop,
                      loc: loc,
                      txt: txt,
                      colors: colors,
                      isLast: isLast,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaintenanceSaasRow extends StatefulWidget {
  final int index;
  final MaintenanceRequest req;
  final Property property;
  final AppLocalizations loc;
  final Map<String, String> txt;
  final AgencyColorScheme colors;
  final bool isLast;

  const _MaintenanceSaasRow({
    required this.index,
    required this.req,
    required this.property,
    required this.loc,
    required this.txt,
    required this.colors,
    required this.isLast,
  });

  @override
  State<_MaintenanceSaasRow> createState() => _MaintenanceSaasRowState();
}

class _MaintenanceSaasRowState extends State<_MaintenanceSaasRow> {
  bool _isHovered = false;

  IconData _getCategoryIcon(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing:
        return LucideIcons.droplets;
      case MaintenanceCategory.electrical:
        return LucideIcons.zap;
      case MaintenanceCategory.heating:
        return LucideIcons.flame;
      case MaintenanceCategory.internet:
        return LucideIcons.wifi;
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
        return LucideIcons.wrench;
    }
  }

  Color _getCategoryColor(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing:
        return const Color(0xFF0284C7);
      case MaintenanceCategory.electrical:
        return const Color(0xFFD97706);
      case MaintenanceCategory.heating:
        return const Color(0xFFEA580C);
      case MaintenanceCategory.internet:
        return const Color(0xFF2563EB);
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    final property = widget.property;
    final loc = widget.loc;
    final txt = widget.txt;
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    // 1. Issue Status (Linear Style Dot + Pill)
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusColor = const Color(0xFF475569);
    Color statusDotColor = const Color(0xFF94A3B8);
    String statusText = 'Bilinmiyor';

    switch (req.status) {
      case MaintenanceStatus.open:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
        statusDotColor = const Color(0xFFD97706);
        statusText = loc.statusActive;
        break;
      case MaintenanceStatus.investigating:
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        statusDotColor = const Color(0xFF2563EB);
        statusText = loc.statusInvestigating;
        break;
      case MaintenanceStatus.inProgress:
        statusBg = const Color(0xFFFFF7ED);
        statusColor = const Color(0xFFC2410C);
        statusDotColor = const Color(0xFFEA580C);
        statusText = txt['status_technician_sent']!;
        break;
      case MaintenanceStatus.resolved:
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF065F46);
        statusDotColor = const Color(0xFF10B981);
        statusText = loc.statusResolved;
        break;
      case MaintenanceStatus.closed:
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF64748B);
        statusDotColor = const Color(0xFF94A3B8);
        statusText = txt['status_closed']!;
        break;
      case MaintenanceStatus.pending:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFD97706);
        statusDotColor = const Color(0xFFF59E0B);
        statusText = txt['status_pending']!;
        break;
      case MaintenanceStatus.cancelled:
        statusBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
        statusDotColor = const Color(0xFFEF4444);
        statusText = txt['status_cancelled']!;
        break;
    }

    // 2. Priority (Linear Minimal Tag)
    Color priorityBg = const Color(0xFFF8FAFC);
    Color priorityColor = const Color(0xFF64748B);
    IconData priorityIcon = LucideIcons.minus;
    String priorityText = txt['normal_badge']!;

    switch (req.priority) {
      case MaintenancePriority.urgent:
        priorityBg = const Color(0xFFFFF1F2);
        priorityColor = const Color(0xFFE11D48);
        priorityIcon = LucideIcons.alertTriangle;
        priorityText = txt['urgent_badge']!;
        break;
      case MaintenancePriority.high:
        priorityBg = const Color(0xFFFFF7ED);
        priorityColor = const Color(0xFFEA580C);
        priorityIcon = LucideIcons.arrowUp;
        priorityText = txt['high_badge']!;
        break;
      case MaintenancePriority.medium:
        priorityBg = const Color(0xFFEFF6FF);
        priorityColor = const Color(0xFF2563EB);
        priorityIcon = LucideIcons.arrowRight;
        priorityText = txt['medium_badge']!;
        break;
      case MaintenancePriority.normal:
        priorityBg = const Color(0xFFF8FAFC);
        priorityColor = const Color(0xFF475569);
        priorityIcon = LucideIcons.minus;
        priorityText = txt['normal_badge']!;
        break;
      case MaintenancePriority.low:
        priorityBg = const Color(0xFFF1F5F9);
        priorityColor = const Color(0xFF94A3B8);
        priorityIcon = LucideIcons.arrowDown;
        priorityText = txt['low_badge']!;
        break;
    }

    // 3. Category
    final categoryColor = _getCategoryColor(req.category);
    final categoryIcon = _getCategoryIcon(req.category);

    // 4. Financials (Stripe / Ramp Structure)
    final currency = req.currency ?? (property.currency.isNotEmpty ? property.currency : 'EUR');

    String payerLabel = '';
    if (req.paidBy != null) {
      if (req.paidBy == 'tenant') {
        payerLabel = loc.payerTenant;
      } else {
        payerLabel = loc.payerLandlord;
      }
    }

    String finStatusLabel = '';
    Color finStatusColor = const Color(0xFF64748B);
    Color finStatusBg = const Color(0xFFF1F5F9);
    IconData finStatusIcon = LucideIcons.clock;

    switch (req.financialStatus) {
      case MaintenancePaymentStatus.pendingReview:
        finStatusLabel = loc.financialStatusPendingReview;
        finStatusColor = const Color(0xFF1D4ED8);
        finStatusBg = const Color(0xFFEFF6FF);
        finStatusIcon = LucideIcons.fileSearch;
        break;
      case MaintenancePaymentStatus.pendingPayment:
        finStatusLabel = loc.financialStatusPendingPayment;
        finStatusColor = const Color(0xFFB45309);
        finStatusBg = const Color(0xFFFFFBEB);
        finStatusIcon = LucideIcons.clock;
        break;
      case MaintenancePaymentStatus.paid:
        finStatusLabel = loc.financialStatusPaid;
        finStatusColor = const Color(0xFF059669);
        finStatusBg = const Color(0xFFECFDF5);
        finStatusIcon = LucideIcons.checkCircle2;
        break;
      case MaintenancePaymentStatus.rejected:
        finStatusLabel = loc.financialStatusRejected;
        finStatusColor = const Color(0xFFDC2626);
        finStatusBg = const Color(0xFFFEF2F2);
        finStatusIcon = LucideIcons.xCircle;
        break;
    }

    String dateStr = '-';
    if (req.createdAt != null) {
      dateStr = DateFormat('dd.MM.yyyy').format(req.createdAt!);
    }

    String dueDateStr = '';
    if (req.paymentDate != null) {
      dueDateStr = DateFormat('dd.MM.yyyy').format(req.paymentDate!);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          context.push(
            '/maintenance/detail',
            extra: {
              'property': property,
              'request': req,
            },
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: Border(
              bottom: widget.isLast
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Monospace ID (48px)
              SizedBox(
                width: 48,
                child: Text(
                  '#${widget.index.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isHovered ? const Color(0xFF5E6AD2) : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              // 2. Request Title & Property (flex: 28)
              Expanded(
                flex: 28,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(categoryIcon, size: 15, color: categoryColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              req.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              property.name.isNotEmpty
                                  ? '${property.name}${property.address.isNotEmpty ? ' • ${property.address}' : ''}'
                                  : (property.address.isNotEmpty ? property.address : txt['property_detail']!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Priority (flex: 12)
              Expanded(
                flex: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 10, color: priorityColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            priorityText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Issue Status (flex: 14)
              Expanded(
                flex: 14,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4.5),
                        Flexible(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Cost & Payer (flex: 15)
              Expanded(
                flex: 15,
                child: req.costAmount != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${req.costAmount!.toStringAsFixed(2)} $currency',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (payerLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              payerLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),

              // 6. Financial Approval & Invoice PDF Link (flex: 20)
              Expanded(
                flex: 20,
                child: (req.costAmount != null || req.invoicePdfUrl != null)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: finStatusBg,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: finStatusColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(finStatusIcon, size: 9, color: finStatusColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      finStatusLabel,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: finStatusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (req.invoicePdfUrl != null && req.invoicePdfUrl!.isNotEmpty)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final uri = Uri.parse(req.invoicePdfUrl!);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.fileText, size: 9, color: Color(0xFFDC2626)),
                                          SizedBox(width: 2),
                                          Text(
                                            'PDF',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (dueDateStr.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${loc.dueDatePrefix}: $dueDateStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        '-',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
              ),

              // 7. Created Date (flex: 11)
              Expanded(
                flex: 11,
                child: Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),

              // 8. Action Arrow (40px)
              SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _isHovered ? const Color(0xFF5E6AD2).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: _isHovered ? const Color(0xFF5E6AD2) : const Color(0xFF94A3B8),
                    ),
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


// ---------------------------------------------------------------------------
// Apple-Styled Ajans Kokpiti & Actionable Insights Components
// ---------------------------------------------------------------------------

Map<String, String> _getCockpitTexts(String lang) {
  switch (lang) {
    case 'tr':
      return {
        'section_contracts': 'Sözleşme ve Portföy',
        'section_finance': 'Finans ve Tahsilat',
        'section_operations': 'Operasyon ve Bakım',
        'expired_title': 'Süresi Dolanlar',
        'expired_action': 'Portföy detaylarını gör',
        'expiring_title': 'Bitişi Yaklaşanlar',
        'expiring_action': 'Süresi yaklaşanları incele',
        'without_contracts_title': 'Kontratsız Mülkler',
        'without_contracts_action': 'Boş mülkleri yönet',
        'overdue_title': 'Geciken Borçlar',
        'overdue_action': 'Borçlu listesine git',
        'upcoming_title': 'Vadesi Yaklaşanlar',
        'upcoming_action': 'Bekleyen işlemleri gör',
        'pending_approvals_title': 'Bekleyen Onaylar',
        'pending_approvals_action': 'Onay merkezini aç',
        'maintenance_title': 'Bakım Talepleri',
        'maintenance_action': 'Aktif talepleri yönet',
        'contract_unit': 'Kontrat',
        'property_unit': 'Mülk',
        'operation_unit': 'İşlem',
        'request_unit': 'Talep',
        'action_pending': 'Aksiyon Bekliyor',
        'in_negotiation': 'Müzakerede',
        'vacant': 'Boşta',
        'invite_pending': 'Davet Aşamasında',
        'rent': 'Kira',
        'bill': 'Fatura',
        'rent_collection': 'Kira Tahsilatı',
        'bill_due': 'Fatura Vadesi',
        'receipt_approval': 'Dekont Onayı',
        'contract_invite_approval': 'Sözleşme / Davet Onayı',
        'days_oldest': 'En eski: {days} gün',
        'no_open_requests': 'Açık talep bulunmuyor',
        'no_overdue_debt': 'Gecikmiş borç yok',
        'days_7_badge': '7 Günlük',
        'urgent': 'Acil',
        'high': 'Yüksek',
        'normal': 'Normal',
        'today': 'Bugün',
        'days_1_15': '1–15 Gün',
        'days_16_30': '16–30 Gün',
        'months_1_2': '1–2 Ay',
        'empty_tooltip_overdue': 'Gecikmiş borcu bulunan kontrat veya fatura yok.',
        'empty_tooltip_upcoming': 'Önümüzdeki 7 gün içinde vadesi dolan işlem yok.',
        'empty_tooltip_pending_approvals': 'Ajans onayı bekleyen dekont veya sözleşme bulunmuyor.',
        'empty_tooltip_expired': 'Süresi dolmuş veya aksiyon bekleyen sözleşme yok.',
        'empty_tooltip_expiring': 'Önümüzdeki 60 gün içinde bitecek aktif sözleşme yok.',
        'empty_tooltip_without_contracts': 'Tüm mülkleriniz aktif bir sözleşmeye bağlı.',
        'empty_tooltip_maintenance': 'İşlem bekleyen açık bakım talebi bulunmuyor.',
        'no_action_needed': 'İşlem gerekmiyor',
        'view_list': 'Listeyi Gör',
        'agency_management_portal': 'Ajans Yönetim Portalı',
        'quick_portfolio': 'Mülk Portföyü',
        'quick_contracts': 'Aktif Sözleşmeler',
        'quick_actions': 'Hızlı Aksiyonlar',
        'status_all_good': 'Tümü Güncel',
        'status_actions_pending': '{count} İşlem Bekliyor',
      };
    case 'sr':
      return {
        'section_contracts': 'Ugovori i portfolio',
        'section_finance': 'Finansije i naplata',
        'section_operations': 'Operacije i održavanje',
        'expired_title': 'Istekli ugovori',
        'expired_action': 'Pogledaj portfolio',
        'expiring_title': 'Ugovori koji uskoro ističu',
        'expiring_action': 'Pregledaj ugovore',
        'without_contracts_title': 'Nekretnine bez ugovora',
        'without_contracts_action': 'Upravljaj praznim stanovima',
        'overdue_title': 'Dugovanja',
        'overdue_action': 'Lista dužnika',
        'upcoming_title': 'Predstojeća plaćanja',
        'upcoming_action': 'Prikaži na čekanju',
        'pending_approvals_title': 'Čeka odobrenje',
        'pending_approvals_action': 'Otvori centar za odobrenja',
        'maintenance_title': 'Zahtevi za održavanje',
        'maintenance_action': 'Upravljaj zahtevima',
        'contract_unit': 'Ugovor',
        'property_unit': 'Nekretnina',
        'operation_unit': 'Transakcija',
        'request_unit': 'Zahtev',
        'action_pending': 'Čeka akciju',
        'in_negotiation': 'U pregovorima',
        'vacant': 'Prazno',
        'invite_pending': 'Pozivnica na čekanju',
        'rent': 'Kirija',
        'bill': 'Račun',
        'rent_collection': 'Naplata kirije',
        'bill_due': 'Dospeće računa',
        'receipt_approval': 'Odobrenje priznanice',
        'contract_invite_approval': 'Odobrenje ugovora/pozivnice',
        'days_oldest': 'Najstariji: {days} dana',
        'no_open_requests': 'Nema otvorenih zahteva',
        'no_overdue_debt': 'Nema dugovanja',
        'days_7_badge': '7 Dana',
        'urgent': 'Hitno',
        'high': 'Visoko',
        'normal': 'Normalno',
        'today': 'Danas',
        'days_1_15': '1–15 dana',
        'days_16_30': '16–30 dana',
        'months_1_2': '1–2 meseca',
        'empty_tooltip_overdue': 'Nema ugovora ili računa sa zakašnjenjem.',
        'empty_tooltip_upcoming': 'Nema plaćanja koja dospevaju u narednih 7 dana.',
        'empty_tooltip_pending_approvals': 'Nema priznanica ili ugovora koji čekaju odobrenje.',
        'empty_tooltip_expired': 'Nema isteklih ugovora ili ugovora koji čekaju akciju.',
        'empty_tooltip_expiring': 'Nema ugovora koji ističu u narednih 60 dana.',
        'empty_tooltip_without_contracts': 'Sve nekretnine su povezane sa aktivnim ugovorom.',
        'empty_tooltip_maintenance': 'Nema otvorenih zahteva za održavanje.',
        'no_action_needed': 'Nije potrebna akcija',
        'view_list': 'Prikaži listu',
        'agency_management_portal': 'Agencijski portal',
        'quick_portfolio': 'Portfolio nekretnina',
        'quick_contracts': 'Aktivni ugovori',
        'quick_actions': 'Brze akcije',
        'status_all_good': 'Sve ažurno',
        'status_actions_pending': '{count} na čekanju',
      };
    case 'ru':
      return {
        'section_contracts': 'Договоры и портфель',
        'section_finance': 'Финансы и платежи',
        'section_operations': 'Обслуживание и операции',
        'expired_title': 'Истекшие договоры',
        'expired_action': 'Посмотреть портфель',
        'expiring_title': 'Истекающие договоры',
        'expiring_action': 'Проверить договоры',
        'without_contracts_title': 'Объекты без договора',
        'without_contracts_action': 'Управление объектами',
        'overdue_title': 'Просроченная задолженность',
        'overdue_action': 'Список должников',
        'upcoming_title': 'Ближайшие платежи',
        'upcoming_action': 'Ожидающие операции',
        'pending_approvals_title': 'Ожидают подтверждения',
        'pending_approvals_action': 'Центр подтверждений',
        'maintenance_title': 'Заявки на ремонт',
        'maintenance_action': 'Управление заявками',
        'contract_unit': 'Договор',
        'property_unit': 'Объект',
        'operation_unit': 'Операций',
        'request_unit': 'Заявок',
        'action_pending': 'Требует действий',
        'in_negotiation': 'На согласовании',
        'vacant': 'Свободно',
        'invite_pending': 'Ожидает приглашения',
        'rent': 'Аренда',
        'bill': 'Счет',
        'rent_collection': 'Сбор аренды',
        'bill_due': 'Срок счета',
        'receipt_approval': 'Проверка чека',
        'contract_invite_approval': 'Подтверждение договора',
        'days_oldest': 'Самая старая: {days} дн.',
        'no_open_requests': 'Нет открытых заявок',
        'no_overdue_debt': 'Нет задолженности',
        'days_7_badge': '7 Дней',
        'urgent': 'Срочно',
        'high': 'Высокий',
        'normal': 'Обычный',
        'today': 'Сегодня',
        'days_1_15': '1–15 дней',
        'days_16_30': '16–30 дней',
        'months_1_2': '1–2 месяца',
        'empty_tooltip_overdue': 'Нет договоров или счетов с просрочкой.',
        'empty_tooltip_upcoming': 'Нет платежей со сроком в ближайшие 7 дней.',
        'empty_tooltip_pending_approvals': 'Нет чеков или договоров, ожидающих подтверждения.',
        'empty_tooltip_expired': 'Нет истекших договоров или требующих действий.',
        'empty_tooltip_expiring': 'Нет активных договоров, истекающих в ближайшие 60 дней.',
        'empty_tooltip_without_contracts': 'Все объекты привязаны к активным договорам.',
        'empty_tooltip_maintenance': 'Нет открытых заявок на ремонт.',
        'no_action_needed': 'Действий не требуется',
        'view_list': 'Посмотреть список',
        'agency_management_portal': 'Портал управления агентством',
        'quick_portfolio': 'Портфель объектов',
        'quick_contracts': 'Активные договоры',
        'quick_actions': 'Быстрые действия',
        'status_all_good': 'Все актуально',
        'status_actions_pending': '{count} в ожидании',
      };
    case 'en':
    default:
      return {
        'section_contracts': 'Contracts & Portfolio',
        'section_finance': 'Finance & Collections',
        'section_operations': 'Operations & Maintenance',
        'expired_title': 'Expired Contracts',
        'expired_action': 'View portfolio details',
        'expiring_title': 'Expiring Soon',
        'expiring_action': 'Inspect expiring contracts',
        'without_contracts_title': 'Properties Without Contracts',
        'without_contracts_action': 'Manage vacant units',
        'overdue_title': 'Overdue Debts',
        'overdue_action': 'Go to debtors list',
        'upcoming_title': 'Upcoming Due',
        'upcoming_action': 'View pending operations',
        'pending_approvals_title': 'Pending Approvals',
        'pending_approvals_action': 'Open approval center',
        'maintenance_title': 'Maintenance Requests',
        'maintenance_action': 'Manage active requests',
        'contract_unit': 'Contracts',
        'property_unit': 'Properties',
        'operation_unit': 'Operations',
        'request_unit': 'Requests',
        'action_pending': 'Action Required',
        'in_negotiation': 'In Negotiation',
        'vacant': 'Vacant',
        'invite_pending': 'Invite Pending',
        'rent': 'Rent',
        'bill': 'Bill',
        'rent_collection': 'Rent Collection',
        'bill_due': 'Bill Due',
        'receipt_approval': 'Receipt Approval',
        'contract_invite_approval': 'Contract / Invite Approval',
        'days_oldest': 'Oldest: {days} days',
        'no_open_requests': 'No open requests',
        'no_overdue_debt': 'No overdue debts',
        'days_7_badge': '7 Days',
        'urgent': 'Urgent',
        'high': 'High',
        'normal': 'Normal',
        'today': 'Today',
        'days_1_15': '1–15 Days',
        'days_16_30': '16–30 Days',
        'months_1_2': '1–2 Months',
        'empty_tooltip_overdue': 'No contracts or bills with overdue debts.',
        'empty_tooltip_upcoming': 'No operations due in the next 7 days.',
        'empty_tooltip_pending_approvals': 'No receipts or contracts awaiting agency approval.',
        'empty_tooltip_expired': 'No expired contracts requiring action.',
        'empty_tooltip_expiring': 'No active contracts expiring in the next 60 days.',
        'empty_tooltip_without_contracts': 'All properties are covered by active contracts.',
        'empty_tooltip_maintenance': 'No open maintenance requests pending.',
        'no_action_needed': 'No action needed',
        'view_list': 'View List',
        'agency_management_portal': 'Agency Management Portal',
        'quick_portfolio': 'Property Portfolio',
        'quick_contracts': 'Active Contracts',
        'quick_actions': 'Quick Actions',
        'status_all_good': 'All Current',
        'status_actions_pending': '{count} Pending',
      };
  }
}

String _formatCockpitCurrencyTotals(Map<String, double> totals, String emptyText) {
  if (totals.isEmpty || totals.values.every((v) => v <= 0)) {
    return emptyText;
  }
  final parts = <String>[];
  totals.forEach((curr, amount) {
    if (amount > 0) {
      if (curr.toUpperCase() == 'EUR') {
        parts.add(CurrencyUtils.formatAmount(amount, 'EUR', useSymbol: true));
      } else if (curr.toUpperCase() == 'RSD') {
        if (amount >= 1000) {
          final k = (amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1);
          parts.add('${k}k RSD');
        } else {
          parts.add('${amount.toInt()} RSD');
        }
      } else if (curr.toUpperCase() == 'USD') {
        parts.add(CurrencyUtils.formatAmount(amount, 'USD', useSymbol: true));
      } else {
        parts.add('${CurrencyUtils.formatAmount(amount, curr)} $curr');
      }
    }
  });
  return parts.isEmpty ? emptyText : parts.join(' + ');
}

class _ActionCockpitCard extends StatefulWidget {
  final String title;
  final String metric;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? iconBorderColor;
  final Color actionTextColor;
  final List<String> items;
  final String linkText;
  final VoidCallback onTap;
  final bool isMuted;
  final String? tooltipText;

  const _ActionCockpitCard({
    required this.title,
    required this.metric,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.iconBorderColor,
    required this.actionTextColor,
    required this.items,
    required this.linkText,
    required this.onTap,
    this.isMuted = false,
    this.tooltipText,
  });

  @override
  State<_ActionCockpitCard> createState() => _ActionCockpitCardState();
}

class _ActionCockpitCardState extends State<_ActionCockpitCard> {
  bool _isHovered = false;

  void _handleTap(BuildContext context) {
    if (widget.isMuted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.tooltipText ?? widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Listeyi Gör',
            textColor: const Color(0xFF38BDF8),
            onPressed: widget.onTap,
          ),
        ),
      );
    } else {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.isMuted ? const Color(0xFF94A3B8) : widget.iconColor;
    final effectiveIconBg = widget.isMuted ? const Color(0xFFF8FAFC) : widget.iconBgColor;
    final effectiveBorderColor = widget.isMuted
        ? const Color(0xFFE2E8F0)
        : (widget.iconBorderColor ?? widget.iconColor.withValues(alpha: 0.15));

    Widget cardBody = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.isMuted ? (_isHovered ? 0.92 : 0.65) : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? (widget.isMuted ? const Color(0xFFCBD5E1) : widget.iconColor.withValues(alpha: 0.35))
                  : const Color(0xFFE2E8F0),
              width: _isHovered ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.055 : 0.025),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Arkaplan silik ikonu (Watermark ~2.5% opacity)
              Positioned(
                right: -24,
                bottom: -24,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.isMuted ? 0.012 : 0.025,
                    child: Icon(
                      widget.icon,
                      size: 150,
                      color: effectiveIconColor,
                    ),
                  ),
                ),
              ),

              // Card Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleTap(context),
                  hoverColor: widget.isMuted
                      ? Colors.black.withValues(alpha: 0.01)
                      : widget.iconColor.withValues(alpha: 0.02),
                  splashColor: widget.isMuted
                      ? Colors.black.withValues(alpha: 0.03)
                      : widget.iconColor.withValues(alpha: 0.05),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top: Squircle Icon + Chevron / Zen Checkmark
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: effectiveIconBg,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: effectiveBorderColor),
                              ),
                              child: Icon(widget.icon, size: 20, color: effectiveIconColor),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.isMuted
                                    ? const Color(0xFFF8FAFC)
                                    : (_isHovered ? effectiveIconBg : const Color(0xFFF8FAFC)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.isMuted
                                      ? const Color(0xFFE2E8F0)
                                      : (_isHovered ? effectiveBorderColor : const Color(0xFFF1F5F9)),
                                ),
                              ),
                              child: Icon(
                                widget.isMuted ? LucideIcons.check : LucideIcons.chevronRight,
                                size: widget.isMuted ? 14 : 15,
                                color: widget.isMuted
                                    ? const Color(0xFF10B981)
                                    : (_isHovered ? effectiveIconColor : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isMuted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Big Metric
                        Text(
                          widget.metric,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: widget.isMuted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),

                        // Items List (Bullet points with subtle dots)
                        ...widget.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.isMuted
                                        ? const Color(0xFFCBD5E1)
                                        : effectiveIconColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: widget.isMuted ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Footer Action Link
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.linkText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isMuted
                                        ? const Color(0xFF94A3B8)
                                        : (_isHovered ? effectiveIconColor : const Color(0xFF475569)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedPadding(
                                duration: const Duration(milliseconds: 180),
                                padding: EdgeInsets.only(left: _isHovered ? 4 : 0),
                                child: Icon(
                                  widget.isMuted ? LucideIcons.checkCircle : LucideIcons.arrowRight,
                                  size: 13,
                                  color: widget.isMuted
                                      ? const Color(0xFF10B981)
                                      : (_isHovered ? effectiveIconColor : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isMuted && widget.tooltipText != null && widget.tooltipText!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltipText!,
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        child: cardBody,
      );
    }

    return cardBody;
  }
}

class _AgencyCockpitSection extends StatefulWidget {
  final List<Property> properties;
  final Map<String, Contract?> contractsMap;
  final List<Map<String, dynamic>> allPayments;
  final List<Map<String, dynamic>> pendingPayments;
  final List<MaintenanceRequest> maintenanceRequests;
  final AgencyColorScheme colors;
  final AppLocalizations loc;
  final String lang;
  final ValueChanged<ActionableInsightType> onSelectInsight;
  final ValueChanged<int> onSelectFinanceSegment;
  final VoidCallback onOpenMaintenance;

  const _AgencyCockpitSection({
    required this.properties,
    required this.contractsMap,
    required this.allPayments,
    required this.pendingPayments,
    required this.maintenanceRequests,
    required this.colors,
    required this.loc,
    required this.lang,
    required this.onSelectInsight,
    required this.onSelectFinanceSegment,
    required this.onOpenMaintenance,
  });

  @override
  State<_AgencyCockpitSection> createState() => _AgencyCockpitSectionState();
}

class _AgencyCockpitSectionState extends State<_AgencyCockpitSection> {
  bool? _isFinanceExpanded;
  bool? _isContractsExpanded;
  bool? _isOperationsExpanded;

  Map<String, double> _calculateCurrencyTotals(List<Map<String, dynamic>> items) {
    final Map<String, double> totals = {};
    for (final item in items) {
      final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final curr = item['currency'] as String? ?? 'EUR';
      if (amt > 0) {
        totals[curr] = (totals[curr] ?? 0.0) + amt;
      }
    }
    return totals;
  }

  Widget _buildCardGrid(BuildContext context, List<Widget> cards) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);

    if (crossAxisCount == 1) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 14), child: c)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final cardWidth = (constraints.maxWidth - (gap * (crossAxisCount - 1))) / crossAxisCount;
        return Wrap(spacing: gap, runSpacing: gap, children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final txt = _getCockpitTexts(widget.lang);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Sözleşme ve Portföy Hesaplamaları
    final expiredProps = widget.properties.where((p) {
      final c = widget.contractsMap[p.id];
      if (c == null) return false;
      if (c.status == ContractStatus.expired) return true;
      if (c.endDate != null && c.endDate!.isBefore(now)) return true;
      return false;
    }).toList();
    final expiredCount = expiredProps.length;
    final expiredNegotiating = expiredProps.where((p) => widget.contractsMap[p.id]?.status == ContractStatus.negotiating).length;
    final expiredPendingAction = expiredCount - expiredNegotiating;
    final isExpiredEmpty = expiredCount == 0;

    final expiringProps = widget.properties.where((p) {
      final c = widget.contractsMap[p.id];
      if (c == null || c.endDate == null || c.status != ContractStatus.active) return false;
      final days = c.endDate!.difference(now).inDays;
      return days >= 0 && days <= 60;
    }).toList();
    final expiringCount = expiringProps.length;
    final t0 = expiringProps.where((p) => widget.contractsMap[p.id]!.endDate!.difference(now).inDays == 0).length;
    final t15 = expiringProps.where((p) {
      final d = widget.contractsMap[p.id]!.endDate!.difference(now).inDays;
      return d >= 1 && d <= 15;
    }).length;
    final t30 = expiringProps.where((p) {
      final d = widget.contractsMap[p.id]!.endDate!.difference(now).inDays;
      return d >= 16 && d <= 30;
    }).length;
    final t60 = expiringProps.where((p) {
      final d = widget.contractsMap[p.id]!.endDate!.difference(now).inDays;
      return d >= 31 && d <= 60;
    }).length;
    final isExpiringEmpty = expiringCount == 0;

    final withoutContractProps = widget.properties.where((p) => widget.contractsMap[p.id] == null).toList();
    final withoutContractsCount = withoutContractProps.length;
    final vacantCount = withoutContractProps.where((p) => p.tenantId == null).length;
    final invitePendingCount = withoutContractProps.where((p) => p.tenantId != null || p.landlordId == null).length;
    final isWithoutContractsEmpty = withoutContractsCount == 0;

    // 2. Finans ve Tahsilat Hesaplamaları
    final overdueList = widget.allPayments.where((item) {
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
    final overdueTotals = _calculateCurrencyTotals(overdueList);
    final overdueRents = overdueList.where((p) => (p['title'] as String? ?? 'Kira') == 'Kira').toList();
    final overdueBills = overdueList.where((p) => (p['title'] as String? ?? 'Kira') != 'Kira').toList();
    final overdueRentCount = overdueRents.length;
    final overdueBillCount = overdueBills.length;
    final overdueRentTotals = _calculateCurrencyTotals(overdueRents);
    final overdueBillTotals = _calculateCurrencyTotals(overdueBills);
    final isOverdueEmpty = overdueList.isEmpty;

    final upcomingList = widget.allPayments.where((item) {
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
    final upcomingRents = upcomingList.where((p) => (p['title'] as String? ?? 'Kira') == 'Kira').length;
    final upcomingBills = upcomingList.where((p) => (p['title'] as String? ?? 'Kira') != 'Kira').length;
    final isUpcomingEmpty = upcomingCount == 0;

    final declaredPaymentsCount = widget.pendingPayments.where((p) => (p['status'] as String?) == 'declared').length;
    final pendingContractsCount = widget.properties.where((p) {
      final c = widget.contractsMap[p.id];
      return c != null && (c.status == ContractStatus.pending || c.status == ContractStatus.negotiating);
    }).length;
    final pendingApprovalsTotal = declaredPaymentsCount + pendingContractsCount;
    final isPendingApprovalsEmpty = pendingApprovalsTotal == 0;

    // 3. Operasyon ve Bakım Hesaplamaları
    final openRequests = widget.maintenanceRequests.where((r) =>
        r.status == MaintenanceStatus.open ||
        r.status == MaintenanceStatus.investigating ||
        r.status == MaintenanceStatus.inProgress ||
        r.status == MaintenanceStatus.pending).toList();
    final openRequestsCount = openRequests.length;
    final urgentCount = openRequests.where((r) => r.priority == MaintenancePriority.urgent).length;
    final highCount = openRequests.where((r) => r.priority == MaintenancePriority.high).length;
    final normalCount = openRequests.where((r) =>
        r.priority == MaintenancePriority.normal ||
        r.priority == MaintenancePriority.medium ||
        r.priority == MaintenancePriority.low).length;
    final oldestDays = openRequests.isEmpty
        ? 0
        : openRequests
            .map((r) => r.createdAt != null ? now.difference(r.createdAt!).inDays : 0)
            .reduce((a, b) => a > b ? a : b);
    final isMaintenanceEmpty = openRequestsCount == 0;

    final contractCards = [
      _ActionCockpitCard(
        title: txt['expired_title']!,
        metric: '$expiredCount ${txt['contract_unit']}',
        icon: LucideIcons.alertTriangle,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEF2F2),
        iconBorderColor: const Color(0xFFFEE2E2),
        actionTextColor: const Color(0xFFB91C1C),
        isMuted: isExpiredEmpty,
        tooltipText: isExpiredEmpty ? txt['empty_tooltip_expired'] : null,
        items: isExpiredEmpty
            ? [txt['empty_tooltip_expired']!]
            : [
                '$expiredPendingAction ${txt['action_pending']}',
                '$expiredNegotiating ${txt['in_negotiation']}',
              ],
        linkText: isExpiredEmpty ? txt['no_action_needed']! : txt['expired_action']!,
        onTap: () => widget.onSelectInsight(ActionableInsightType.expiredContracts),
      ),
      _ActionCockpitCard(
        title: txt['expiring_title']!,
        metric: '$expiringCount ${txt['contract_unit']}',
        icon: LucideIcons.clock,
        iconColor: const Color(0xFFEA580C),
        iconBgColor: const Color(0xFFFFF7ED),
        iconBorderColor: const Color(0xFFFFEDD5),
        actionTextColor: const Color(0xFFC2410C),
        isMuted: isExpiringEmpty,
        tooltipText: isExpiringEmpty ? txt['empty_tooltip_expiring'] : null,
        items: isExpiringEmpty
            ? [txt['empty_tooltip_expiring']!]
            : [
                '${txt['today']!}: $t0 • ${txt['days_1_15']!}: $t15',
                '${txt['days_16_30']!}: $t30 • ${txt['months_1_2']!}: $t60',
              ],
        linkText: isExpiringEmpty ? txt['no_action_needed']! : txt['expiring_action']!,
        onTap: () => widget.onSelectInsight(ActionableInsightType.expiringContracts),
      ),
      _ActionCockpitCard(
        title: txt['without_contracts_title']!,
        metric: '$withoutContractsCount ${txt['property_unit']}',
        icon: LucideIcons.fileMinus,
        iconColor: const Color(0xFF475569),
        iconBgColor: const Color(0xFFF8FAFC),
        iconBorderColor: const Color(0xFFE2E8F0),
        actionTextColor: const Color(0xFF334155),
        isMuted: isWithoutContractsEmpty,
        tooltipText: isWithoutContractsEmpty ? txt['empty_tooltip_without_contracts'] : null,
        items: isWithoutContractsEmpty
            ? [txt['empty_tooltip_without_contracts']!]
            : [
                '$vacantCount ${txt['vacant']}',
                '$invitePendingCount ${txt['invite_pending']}',
              ],
        linkText: isWithoutContractsEmpty ? txt['no_action_needed']! : txt['without_contracts_action']!,
        onTap: () => widget.onSelectInsight(ActionableInsightType.withoutContracts),
      ),
    ];

    final financeCards = [
      _ActionCockpitCard(
        title: txt['overdue_title']!,
        metric: _formatCockpitCurrencyTotals(overdueTotals, txt['no_overdue_debt']!),
        icon: LucideIcons.wallet,
        iconColor: const Color(0xFFE11D48),
        iconBgColor: const Color(0xFFFFF1F2),
        iconBorderColor: const Color(0xFFFFE4E6),
        actionTextColor: const Color(0xFFBE123C),
        isMuted: isOverdueEmpty,
        tooltipText: isOverdueEmpty ? txt['empty_tooltip_overdue'] : null,
        items: isOverdueEmpty
            ? [txt['empty_tooltip_overdue']!]
            : [
                '$overdueRentCount ${txt['rent']} (${_formatCockpitCurrencyTotals(overdueRentTotals, "0")})',
                '$overdueBillCount ${txt['bill']} (${_formatCockpitCurrencyTotals(overdueBillTotals, "0")})',
              ],
        linkText: isOverdueEmpty ? txt['no_action_needed']! : txt['overdue_action']!,
        onTap: () => widget.onSelectFinanceSegment(2), // Borçlular segment
      ),
      _ActionCockpitCard(
        title: txt['upcoming_title']!,
        metric: isUpcomingEmpty
            ? '0 ${txt['operation_unit']}'
            : '${txt['days_7_badge']} ($upcomingCount ${txt['operation_unit']})',
        icon: LucideIcons.calendar,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFFFBEB),
        iconBorderColor: const Color(0xFFFEF3C7),
        actionTextColor: const Color(0xFFB45309),
        isMuted: isUpcomingEmpty,
        tooltipText: isUpcomingEmpty ? txt['empty_tooltip_upcoming'] : null,
        items: isUpcomingEmpty
            ? [txt['empty_tooltip_upcoming']!]
            : [
                '$upcomingRents ${txt['rent_collection']}',
                '$upcomingBills ${txt['bill_due']}',
              ],
        linkText: isUpcomingEmpty ? txt['no_action_needed']! : txt['upcoming_action']!,
        onTap: () => widget.onSelectFinanceSegment(0),
      ),
      _ActionCockpitCard(
        title: txt['pending_approvals_title']!,
        metric: '$pendingApprovalsTotal ${txt['operation_unit']}',
        icon: LucideIcons.checkCircle2,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFEFF6FF),
        iconBorderColor: const Color(0xFFDBEAFE),
        actionTextColor: const Color(0xFF1D4ED8),
        isMuted: isPendingApprovalsEmpty,
        tooltipText: isPendingApprovalsEmpty ? txt['empty_tooltip_pending_approvals'] : null,
        items: isPendingApprovalsEmpty
            ? [txt['empty_tooltip_pending_approvals']!]
            : [
                '$declaredPaymentsCount ${txt['receipt_approval']}',
                '$pendingContractsCount ${txt['contract_invite_approval']}',
              ],
        linkText: isPendingApprovalsEmpty ? txt['no_action_needed']! : txt['pending_approvals_action']!,
        onTap: () => widget.onSelectFinanceSegment(0), // Onay Kuyruğu segment
      ),
    ];

    final operationsCards = [
      _ActionCockpitCard(
        title: txt['maintenance_title']!,
        metric: '$openRequestsCount ${txt['request_unit']}',
        icon: LucideIcons.wrench,
        iconColor: const Color(0xFF9333EA),
        iconBgColor: const Color(0xFFFAF5FF),
        iconBorderColor: const Color(0xFFF3E8FF),
        actionTextColor: const Color(0xFF7E22CE),
        isMuted: isMaintenanceEmpty,
        tooltipText: isMaintenanceEmpty ? txt['empty_tooltip_maintenance'] : null,
        items: isMaintenanceEmpty
            ? [txt['empty_tooltip_maintenance']!]
            : [
                '$urgentCount ${txt['urgent']}, $highCount ${txt['high']}, $normalCount ${txt['normal']}',
                txt['days_oldest']!.replaceAll('{days}', '$oldestDays'),
              ],
        linkText: isMaintenanceEmpty ? txt['no_action_needed']! : txt['maintenance_action']!,
        onTap: widget.onOpenMaintenance,
      ),
    ];

    final totalFinancePending = (isOverdueEmpty ? 0 : (overdueRentCount + overdueBillCount)) +
        (isUpcomingEmpty ? 0 : upcomingCount) +
        (isPendingApprovalsEmpty ? 0 : pendingApprovalsTotal);

    final totalContractsPending = (isExpiredEmpty ? 0 : expiredCount) +
        (isExpiringEmpty ? 0 : expiringCount) +
        (isWithoutContractsEmpty ? 0 : withoutContractsCount);

    final totalOperationsPending = (isMaintenanceEmpty ? 0 : openRequestsCount);

    // Boşsa (totalPending == 0) varsayılan olarak collapsed, kayıt varsa açık
    final isFinanceOpen = _isFinanceExpanded ?? (totalFinancePending > 0);
    final isContractsOpen = _isContractsExpanded ?? (totalContractsPending > 0);
    final isOperationsOpen = _isOperationsExpanded ?? (totalOperationsPending > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Finans ve Tahsilat Bölümü (En Üstte) ─────────────────────
        _BentoSectionHeader(
          number: 1,
          title: txt['section_finance']!,
          icon: LucideIcons.wallet,
          accentColor: const Color(0xFF0284C7),
          badgeText: totalFinancePending == 0
              ? txt['status_all_good']
              : txt['status_actions_pending']!.replaceAll('{count}', '$totalFinancePending'),
          isBadgePositive: totalFinancePending == 0,
          isExpanded: isFinanceOpen,
          onToggle: () => setState(() => _isFinanceExpanded = !isFinanceOpen),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _buildCardGrid(context, financeCards),
          ),
          crossFadeState: isFinanceOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOutCubic,
        ),

        // Ayrım çizgisi
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEF0)),
        ),

        // ── 2. Sözleşme ve Portföy Bölümü (İkinci Sırada) ────────────────
        _BentoSectionHeader(
          number: 2,
          title: txt['section_contracts']!,
          icon: LucideIcons.fileText,
          accentColor: const Color(0xFF3B82F6),
          badgeText: totalContractsPending == 0
              ? txt['status_all_good']
              : txt['status_actions_pending']!.replaceAll('{count}', '$totalContractsPending'),
          isBadgePositive: totalContractsPending == 0,
          isExpanded: isContractsOpen,
          onToggle: () => setState(() => _isContractsExpanded = !isContractsOpen),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _buildCardGrid(context, contractCards),
          ),
          crossFadeState: isContractsOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOutCubic,
        ),

        // Ayrım çizgisi
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEF0)),
        ),

        // ── 3. Operasyon ve Bakım Bölümü (En Sonda) ─────────────────────
        _BentoSectionHeader(
          number: 3,
          title: txt['section_operations']!,
          icon: LucideIcons.wrench,
          accentColor: const Color(0xFF9333EA),
          badgeText: totalOperationsPending == 0
              ? txt['status_all_good']
              : txt['status_actions_pending']!.replaceAll('{count}', '$totalOperationsPending'),
          isBadgePositive: totalOperationsPending == 0,
          isExpanded: isOperationsOpen,
          onToggle: () => setState(() => _isOperationsExpanded = !isOperationsOpen),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _buildCardGrid(context, operationsCards),
          ),
          crossFadeState: isOperationsOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }
}

class _BentoSectionHeader extends StatefulWidget {
  final int number;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final bool isBadgePositive;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _BentoSectionHeader({
    required this.number,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    this.isBadgePositive = false,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_BentoSectionHeader> createState() => _BentoSectionHeaderState();
}

class _BentoSectionHeaderState extends State<_BentoSectionHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Group: Icon + Title
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: _isHovered ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.accentColor.withValues(alpha: _isHovered ? 0.35 : 0.2)),
                      ),
                      child: Icon(widget.icon, size: 16, color: widget.accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Group: Status Pill + Chevron (Always Flush Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: widget.isBadgePositive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.isBadgePositive
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.isBadgePositive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.isBadgePositive
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Animated Chevron Indicator
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _isHovered ? const Color(0xFFF1F5F9) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: _isHovered ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
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
    final activeColor = badgeColor ?? const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends ConsumerStatefulWidget {
  final String companyName;
  final String email;
  final AgencyColorScheme colors;

  const _WelcomeBanner({
    required this.companyName,
    required this.email,
    required this.colors,
  });

  @override
  ConsumerState<_WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends ConsumerState<_WelcomeBanner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final txt = _getCockpitTexts(lang);
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? (user?.email != null ? user!.email!.split('@').first : '');

    final primaryColor = widget.colors.primary;
    final primaryHsl = HSLColor.fromColor(primaryColor);
    final primaryDark = primaryHsl.withLightness((primaryHsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    final primaryLight = primaryHsl.withLightness((primaryHsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
    final primaryGradient = [primaryLight, primaryDark];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? primaryColor.withValues(alpha: 0.45)
                : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? primaryDark.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 20 : 14,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Arkaplan silik bina ikonu (Watermark ~3.5% opacity)
            Positioned(
              right: -20,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.035,
                  child: Icon(
                    LucideIcons.building2,
                    size: 180,
                    color: primaryDark,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Squircle Gradient Brand Icon + Live Status Pill Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: primaryGradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryDark.withValues(alpha: _isHovered ? 0.4 : 0.25),
                              blurRadius: _isHovered ? 12 : 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.building2, size: 24, color: Colors.white),
                      ),

                      // Live Status Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.colors.accent.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.colors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              txt['agency_management_portal'] ?? 'Agency Management Portal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.colors.textPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Eyebrow Tag
                  Text(
                    loc.welcomeUser(userName.isNotEmpty ? userName : widget.companyName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Big Prominent Company Name
                  Text(
                    widget.companyName.isNotEmpty ? widget.companyName : 'Stanomer Exclusive',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Info items (Email with brand bullet)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 13,
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
            ),

            // Powered by stanomer.online (Muted White-Label Signature - Sağ Alt Köşe)
            Positioned(
              right: 24,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 10,
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'powered by stanomer.online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PropertyTableView extends StatelessWidget {
  final List<Property> properties;
  final Set<String> debtPropertyIds;
  final AgencyColorScheme colors;

  const _PropertyTableView({
    required this.properties,
    required this.debtPropertyIds,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 768;

        if (!isDesktop) {
          // Mobile / Small Screen: Compact List View
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: properties.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final property = properties[i];
                  return _PropertyCompactRow(
                    property: property,
                    hasPendingDebt: debtPropertyIds.contains(property.id),
                    colors: colors,
                  );
                },
              ),
            ),
          );
        }

        // Desktop High-Density Table View
        final tableWidth = screenWidth > 900 ? screenWidth : 900.0;
        final colAction = 60.0;
        final usableWidth = tableWidth - 36 - colAction; // 36 is horizontal padding (18+18)
        final colProperty = usableWidth * 0.30;
        final colLandlord = usableWidth * 0.22;
        final colTenant = usableWidth * 0.18;
        final colContract = usableWidth * 0.18;
        final colStatus = usableWidth * 0.12;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table Column Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: colProperty,
                            child: Text(
                              loc.tabPortfolio.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: colLandlord,
                            child: Text(
                              loc.landlord.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: colTenant,
                            child: Text(
                              loc.roleTenant.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: colContract,
                            child: Text(
                              loc.contract.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: colStatus,
                            child: Text(
                              loc.statusLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: colAction,
                            child: const Text(''),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: properties.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final property = properties[i];
                        return _PropertyTableRow(
                          property: property,
                          hasPendingDebt: debtPropertyIds.contains(property.id),
                          colProperty: colProperty,
                          colLandlord: colLandlord,
                          colTenant: colTenant,
                          colContract: colContract,
                          colStatus: colStatus,
                          colAction: colAction,
                          colors: colors,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PropertyTableRow extends ConsumerStatefulWidget {
  final Property property;
  final bool hasPendingDebt;
  final double colProperty;
  final double colLandlord;
  final double colTenant;
  final double colContract;
  final double colStatus;
  final double colAction;
  final AgencyColorScheme colors;

  const _PropertyTableRow({
    required this.property,
    required this.hasPendingDebt,
    required this.colProperty,
    required this.colLandlord,
    required this.colTenant,
    required this.colContract,
    required this.colStatus,
    required this.colAction,
    required this.colors,
  });

  @override
  ConsumerState<_PropertyTableRow> createState() => _PropertyTableRowState();
}

class _PropertyTableRowState extends ConsumerState<_PropertyTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final property = widget.property;
    final hasPendingDebt = widget.hasPendingDebt;
    final hasActiveTenant = property.tenantId != null;
    final isClaimed = property.landlordId != null;
    final landlordName = property.landlordName ?? property.landlordEmail ?? loc.landlord;

    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final contract = activeContractAsync.value;
    final tenantProfileAsync = property.tenantId != null ? ref.watch(profileProvider(property.tenantId!)) : null;
    final tenantProfileName = tenantProfileAsync?.value?['full_name'] as String?;

    final tenantName = (property.tenantName != null && property.tenantName!.trim().isNotEmpty)
        ? property.tenantName!
        : (tenantProfileName != null && tenantProfileName.trim().isNotEmpty)
            ? tenantProfileName
            : (contract?.inviteeEmail != null && contract!.inviteeEmail.trim().isNotEmpty)
                ? contract.inviteeEmail
                : (hasActiveTenant ? loc.roleTenant : loc.vacant);
    final cityName = property.city?.trim() ?? '';

    final iconBg = hasPendingDebt
        ? const Color(0xFFFFF1F2)
        : (hasActiveTenant ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC));
    final iconColor = hasPendingDebt
        ? const Color(0xFFE11D48)
        : (hasActiveTenant ? const Color(0xFF2563EB) : const Color(0xFF94A3B8));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
        child: InkWell(
          onTap: () => context.push('/property-detail', extra: property),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                // 1. Property Name & City & Address
                SizedBox(
                  width: widget.colProperty,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasPendingDebt ? LucideIcons.alertTriangle : LucideIcons.building,
                          size: 16,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    property.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Color(0xFF0F172A),
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
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cityName,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              property.address,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Landlord
                SizedBox(
                  width: widget.colLandlord,
                  child: Row(
                    children: [
                      Icon(
                        isClaimed ? LucideIcons.userCheck : LucideIcons.clock,
                        size: 13,
                        color: isClaimed ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isClaimed ? landlordName : '$landlordName (${loc.invitePending})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isClaimed ? const Color(0xFF334155) : const Color(0xFFB45309),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Tenant
                SizedBox(
                  width: widget.colTenant,
                  child: hasActiveTenant
                      ? Row(
                          children: [
                            const Icon(LucideIcons.user, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tenantName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loc.vacantLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                ),

                // 4. Contract Info
                SizedBox(
                  width: widget.colContract,
                  child: contract != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${contract.monthlyRent > 0 ? contract.monthlyRent.toStringAsFixed(0) : (property.defaultMonthlyRent > 0 ? property.defaultMonthlyRent.toStringAsFixed(0) : "-")} ${contract.currency}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              contract.endDate != null
                                  ? DateFormat('dd.MM.yyyy').format(contract.endDate!)
                                  : loc.unlimited,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          loc.latestContractNone,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),

                // 5. Status / Debt Badge
                SizedBox(
                  width: widget.colStatus,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: hasPendingDebt
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFE4E6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.alertTriangle, size: 11, color: Color(0xFFE11D48)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    loc.statusOverdue,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE11D48),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.check, size: 11, color: Color(0xFF065F46)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    loc.statusClean,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF065F46),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                // 6. Action Buttons
                SizedBox(
                  width: widget.colAction,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                const Icon(LucideIcons.userCheck, size: 15),
                                const SizedBox(width: 8),
                                Text(loc.inviteTenantOrAddContract, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share_qr',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.qrCode, size: 15),
                                const SizedBox(width: 8),
                                Text(loc.ownershipQrOrLink, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'property_settings',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.settings, size: 15),
                                const SizedBox(width: 8),
                                Text(loc.propertySettingsLabel, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'change_landlord',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.userPlus, size: 15),
                                const SizedBox(width: 8),
                                Text(loc.changeLandlord, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _PropertyCompactRow extends ConsumerWidget {
  final Property property;
  final bool hasPendingDebt;
  final AgencyColorScheme colors;

  const _PropertyCompactRow({
    required this.property,
    required this.hasPendingDebt,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final hasActiveTenant = property.tenantId != null;
    final isClaimed = property.landlordId != null;
    final landlordName = property.landlordName ?? property.landlordEmail ?? loc.landlord;
    final cityName = property.city?.trim() ?? '';

    final iconBg = hasPendingDebt
        ? const Color(0xFFFFF1F2)
        : (hasActiveTenant ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC));
    final iconColor = hasPendingDebt
        ? const Color(0xFFE11D48)
        : (hasActiveTenant ? const Color(0xFF2563EB) : const Color(0xFF94A3B8));

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.push('/property-detail', extra: property),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasPendingDebt ? LucideIcons.alertTriangle : LucideIcons.building,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            property.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cityName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cityName,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isClaimed ? landlordName : loc.invitePending,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isClaimed ? const Color(0xFF64748B) : const Color(0xFFB45309),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hasActiveTenant ? (property.tenantName ?? loc.roleTenant) : loc.vacantLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: hasActiveTenant ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
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
              if (hasPendingDebt) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    loc.statusOverdue,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFE11D48)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends ConsumerStatefulWidget {
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
  ConsumerState<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends ConsumerState<_PropertyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final property = widget.property;
    final hasPendingDebt = widget.hasPendingDebt;
    final colors = widget.colors;
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

    final iconBg = hasPendingDebt
        ? const Color(0xFFFFF1F2)
        : (hasActiveTenant ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC));
    final iconColor = hasPendingDebt
        ? const Color(0xFFE11D48)
        : (hasActiveTenant ? const Color(0xFF2563EB) : const Color(0xFF64748B));
    final iconBorder = hasPendingDebt
        ? const Color(0xFFFFE4E6)
        : (hasActiveTenant ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? colors.primary.withValues(alpha: 0.35)
                : (hasPendingDebt ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
            width: _isHovered || hasPendingDebt ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.055 : 0.025),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 5 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Property Icon Squircle + Title & City + Popup Menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: iconBorder),
                        ),
                        child: Icon(
                          hasPendingDebt ? LucideIcons.alertTriangle : LucideIcons.building,
                          size: 18,
                          color: iconColor,
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
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (cityName.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFDBEAFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 3),
                                        Text(
                                          cityName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
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
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreHorizontal, size: 18, color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

                  // Pending Debt Pill
                  if (hasPendingDebt) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFE11D48)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.pendingDebtWarning,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE11D48),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Landlord & Tenant Clean Info Rows
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        // Landlord Info
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isClaimed ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isClaimed ? LucideIcons.userCheck : LucideIcons.clock,
                                  size: 13,
                                  color: isClaimed ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.landlordLabel.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      isClaimed ? landlordName : '$landlordName (${loc.invitePending})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isClaimed ? const Color(0xFF0F172A) : const Color(0xFFB45309),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: hasActiveTenant ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  hasActiveTenant ? LucideIcons.user : LucideIcons.userX,
                                  size: 13,
                                  color: hasActiveTenant ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.tenantLabel.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      hasActiveTenant ? (tenantName ?? loc.roleTenant) : loc.vacantLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: hasActiveTenant ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Contract Info Box
                  _ContractInfoBadge(contract: contract, colors: colors, loc: loc),

                  const SizedBox(height: 10),

                  // Footer Divider & Action
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.propertyDetails,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              loc.propertyDetails,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isHovered ? colors.primary : const Color(0xFF64748B),
                              ),
                            ),
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.only(left: _isHovered ? 6 : 2),
                              child: Icon(
                                LucideIcons.arrowRight,
                                size: 13,
                                color: _isHovered ? colors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.fileX, size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              loc.latestContractNone,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
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

    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeColor = const Color(0xFF64748B);
    Color badgeBorder = const Color(0xFFE2E8F0);

    if (contract!.status == ContractStatus.active) {
      badgeBg = const Color(0xFFECFDF5);
      badgeColor = const Color(0xFF065F46);
      badgeBorder = const Color(0xFFA7F3D0);
    } else if (contract!.status == ContractStatus.pending || contract!.status == ContractStatus.negotiating) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeColor = const Color(0xFFB45309);
      badgeBorder = const Color(0xFFFDE68A);
    } else if (contract!.status == ContractStatus.expired || contract!.status == ContractStatus.declined) {
      badgeBg = const Color(0xFFFFF1F2);
      badgeColor = const Color(0xFFE11D48);
      badgeBorder = const Color(0xFFFFE4E6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeBorder),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, size: 13, color: badgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.contractDateRange('$startDateStr - $endDateStr'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
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
    final propertiesList = ref.watch(agencyPropertiesProvider).value ?? [];
    final propertiesMap = {for (var p in propertiesList) p.id: p};

    return _FinancePaymentItemCard(
      payment: payment,
      propertiesMap: propertiesMap,
      colors: colors,
      loc: loc,
      segment: 0,
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
