import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/connection_status_indicator.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';

enum _MaintenanceFilter {
  all,
  active,
  urgent,
  investigating,
  resolved,
  withCost,
}

class MaintenanceScreen extends ConsumerStatefulWidget {
  final Property property;
  final bool isEmbedded;

  const MaintenanceScreen({
    super.key,
    required this.property,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  _MaintenanceFilter _activeFilter = _MaintenanceFilter.all;
  MaintenanceCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _activeFilter = _MaintenanceFilter.all;
      _selectedCategory = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<MaintenanceRequest> _filterRequests(List<MaintenanceRequest> requests) {
    return requests.where((r) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final titleMatch = r.title.toLowerCase().contains(_searchQuery);
        final descMatch = (r.description ?? '').toLowerCase().contains(_searchQuery);
        if (!titleMatch && !descMatch) return false;
      }

      // 2. Category Filter
      if (_selectedCategory != null && r.category != _selectedCategory) {
        return false;
      }

      // 3. Status/Type Filter
      switch (_activeFilter) {
        case _MaintenanceFilter.all:
          return true;
        case _MaintenanceFilter.active:
          return r.status == MaintenanceStatus.open ||
              r.status == MaintenanceStatus.inProgress ||
              r.status == MaintenanceStatus.investigating ||
              r.status == MaintenanceStatus.pending;
        case _MaintenanceFilter.urgent:
          return r.priority == MaintenancePriority.urgent ||
              r.priority == MaintenancePriority.high;
        case _MaintenanceFilter.investigating:
          return r.status == MaintenanceStatus.investigating;
        case _MaintenanceFilter.resolved:
          return r.status == MaintenanceStatus.resolved ||
              r.status == MaintenanceStatus.closed;
        case _MaintenanceFilter.withCost:
          return (r.costAmount != null && r.costAmount! > 0) ||
              (r.invoicePdfUrl != null && r.invoicePdfUrl!.isNotEmpty);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null
        ? ref.watch(profileProvider(user!.id))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ??
        user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id ||
        profileRole == 'tenant' ||
        (!isLandlord && !isAgency);

    final requestsAsync = ref.watch(maintenanceRequestsProvider(widget.property.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/maintenance/new', extra: widget.property);
          ref.invalidate(maintenanceRequestsProvider(widget.property.id));
        },
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
        label: Text(
          loc.reportIssue,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: Colors.white,
            letterSpacing: -0.1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ConnectionStatusIndicator(
              hasError: requestsAsync.hasError,
              onRetry: () => ref.invalidate(maintenanceRequestsProvider(widget.property.id)),
            ),
            Expanded(
              child: requestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(maintenanceRequestsProvider(widget.property.id)),
                ),
                data: (allRequests) {
                  final activeCount = allRequests.where((r) =>
                      r.status == MaintenanceStatus.open ||
                      r.status == MaintenanceStatus.inProgress ||
                      r.status == MaintenanceStatus.investigating ||
                      r.status == MaintenanceStatus.pending).length;
                  final urgentCount = allRequests.where((r) =>
                      r.priority == MaintenancePriority.urgent ||
                      r.priority == MaintenancePriority.high).length;
                  final resolvedCount = allRequests.where((r) =>
                      r.status == MaintenanceStatus.resolved ||
                      r.status == MaintenanceStatus.closed).length;
                  final withCostCount = allRequests.where((r) =>
                      (r.costAmount != null && r.costAmount! > 0) ||
                      (r.invoicePdfUrl != null && r.invoicePdfUrl!.isNotEmpty)).length;

                  final filteredList = _filterRequests(allRequests);

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // 1. Dynamic Hero Header with Back button & Title
                        SliverToBoxAdapter(
                          child: _MaintenanceHeroHeader(
                            property: widget.property,
                            isTenant: isTenant,
                            isAgency: isAgency,
                            isEmbedded: widget.isEmbedded,
                          ),
                        ),

                        // 2. Interactive KPI Stats Deck (4 metrics)
                        if (allRequests.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: _MaintenanceStatDeck(
                                activeCount: activeCount,
                                urgentCount: urgentCount,
                                resolvedCount: resolvedCount,
                                withCostCount: withCostCount,
                                activeFilter: _activeFilter,
                                onSelectFilter: (filter) {
                                  setState(() {
                                    if (_activeFilter == filter) {
                                      _activeFilter = _MaintenanceFilter.all;
                                    } else {
                                      _activeFilter = filter;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),

                        // 3. Search & Filter Bar Controls
                        if (allRequests.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search Field
                                  _buildSearchBar(loc),
                                  const SizedBox(height: 12),

                                  // Status Filter Chips
                                  _buildStatusFilterChips(loc),
                                  const SizedBox(height: 10),

                                  // Category Filter Scroll Row
                                  _buildCategoryFilterRow(loc),
                                ],
                              ),
                            ),
                          ),

                        // 4. Request Listing or Empty View
                        if (allRequests.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyMaintenanceView(
                              property: widget.property,
                              isTenant: isTenant,
                              isAgency: isAgency,
                              onNewRequest: () async {
                                await context.push('/maintenance/new', extra: widget.property);
                                ref.invalidate(maintenanceRequestsProvider(widget.property.id));
                              },
                            ),
                          )
                        else if (filteredList.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyFilteredView(
                              onClearFilters: _clearFilters,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final req = filteredList[index];
                                  return _MaintenanceCard(
                                    key: ValueKey(req.id),
                                    request: req,
                                    property: widget.property,
                                    isLandlord: isLandlord,
                                    isTenant: isTenant,
                                    onTap: () async {
                                      await context.push(
                                        '/maintenance/detail',
                                        extra: {
                                          'property': widget.property,
                                          'request': req,
                                        },
                                      );
                                      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
                                    },
                                  );
                                },
                                childCount: filteredList.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: loc.searchMaintenancePlaceholder,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChips(AppLocalizations loc) {
    final chips = [
      _StatusChipItem(
        label: loc.filterAll,
        filter: _MaintenanceFilter.all,
        icon: LucideIcons.layers,
      ),
      _StatusChipItem(
        label: loc.filterActive,
        filter: _MaintenanceFilter.active,
        icon: LucideIcons.clock,
      ),
      _StatusChipItem(
        label: loc.filterUrgent,
        filter: _MaintenanceFilter.urgent,
        icon: LucideIcons.alertTriangle,
        color: const Color(0xFFE11D48),
      ),
      _StatusChipItem(
        label: loc.filterInvestigating,
        filter: _MaintenanceFilter.investigating,
        icon: LucideIcons.search,
      ),
      _StatusChipItem(
        label: loc.filterCompleted,
        filter: _MaintenanceFilter.resolved,
        icon: LucideIcons.checkCircle2,
      ),
      _StatusChipItem(
        label: loc.filterCost,
        filter: _MaintenanceFilter.withCost,
        icon: LucideIcons.creditCard,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((item) {
          final isSelected = _activeFilter == item.filter;
          final chipColor = item.color ?? const Color(0xFF0F766E);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                item.icon,
                size: 13,
                color: isSelected ? Colors.white : chipColor,
              ),
              label: Text(item.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _activeFilter = selected ? item.filter : _MaintenanceFilter.all;
                });
              },
              selectedColor: chipColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? chipColor : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilterRow(AppLocalizations loc) {
    final categories = [
      null,
      MaintenanceCategory.plumbing,
      MaintenanceCategory.electrical,
      MaintenanceCategory.heating,
      MaintenanceCategory.appliance,
      MaintenanceCategory.internet,
      MaintenanceCategory.structural,
      MaintenanceCategory.other,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final label = cat == null ? loc.filterAll : _getCategoryName(cat, loc);
          final icon = cat == null ? LucideIcons.tag : _getCategoryIcon(cat);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : cat;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChipItem {
  final String label;
  final _MaintenanceFilter filter;
  final IconData icon;
  final Color? color;

  const _StatusChipItem({
    required this.label,
    required this.filter,
    required this.icon,
    this.color,
  });
}

/// ── Dynamic Hero Header Component ─────────────────────────────
class _MaintenanceHeroHeader extends StatelessWidget {
  final Property property;
  final bool isTenant;
  final bool isAgency;
  final bool isEmbedded;

  const _MaintenanceHeroHeader({
    required this.property,
    required this.isTenant,
    required this.isAgency,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final topPadding = isEmbedded ? 4.0 : MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B),
            Color(0xFF0F766E),
            Color(0xFF115E59),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isEmbedded ? 20 : 28),
          bottomRight: Radius.circular(isEmbedded ? 20 : 28),
          topLeft: Radius.circular(isEmbedded ? 20 : 0),
          topRight: Radius.circular(isEmbedded ? 20 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient shapes
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, isEmbedded ? 10 : topPadding + 8, 16, isEmbedded ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single Top Navigation & Title Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isEmbedded) ...[
                      InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.maybePop(context);
                          } else {
                            context.go('/dashboard');
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Title & Subtitle with page icon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.maintenanceTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.wrench,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  loc.maintenanceSubtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 11,
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

                    const SizedBox(width: 8),

                    // Property Context Badge
                    if (!isEmbedded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.home, size: 11, color: Colors.white70),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                property.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
    );
  }
}

/// ── Interactive 4-Tier KPI Stats Deck ──────────────────────────
class _MaintenanceStatDeck extends StatelessWidget {
  final int activeCount;
  final int urgentCount;
  final int resolvedCount;
  final int withCostCount;
  final _MaintenanceFilter activeFilter;
  final ValueChanged<_MaintenanceFilter> onSelectFilter;

  const _MaintenanceStatDeck({
    required this.activeCount,
    required this.urgentCount,
    required this.resolvedCount,
    required this.withCostCount,
    required this.activeFilter,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        // 1. Active & In Progress
        Expanded(
          child: _StatDeckTile(
            icon: LucideIcons.clock,
            label: loc.statActiveIssues,
            count: activeCount,
            accentColor: const Color(0xFF0F766E),
            isSelected: activeFilter == _MaintenanceFilter.active,
            onTap: () => onSelectFilter(_MaintenanceFilter.active),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Urgent Issues
        Expanded(
          child: _StatDeckTile(
            icon: LucideIcons.alertTriangle,
            label: loc.statUrgentIssues,
            count: urgentCount,
            accentColor: const Color(0xFFE11D48),
            isSelected: activeFilter == _MaintenanceFilter.urgent,
            isPulsing: urgentCount > 0,
            onTap: () => onSelectFilter(_MaintenanceFilter.urgent),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Resolved
        Expanded(
          child: _StatDeckTile(
            icon: LucideIcons.checkCircle2,
            label: loc.statResolvedIssues,
            count: resolvedCount,
            accentColor: const Color(0xFF10B981),
            isSelected: activeFilter == _MaintenanceFilter.resolved,
            onTap: () => onSelectFilter(_MaintenanceFilter.resolved),
          ),
        ),
        const SizedBox(width: 8),

        // 4. Financial Settlements
        Expanded(
          child: _StatDeckTile(
            icon: LucideIcons.creditCard,
            label: loc.statPendingSettlement,
            count: withCostCount,
            accentColor: const Color(0xFF6366F1),
            isSelected: activeFilter == _MaintenanceFilter.withCost,
            onTap: () => onSelectFilter(_MaintenanceFilter.withCost),
          ),
        ),
      ],
    );
  }
}

class _StatDeckTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color accentColor;
  final bool isSelected;
  final bool isPulsing;
  final VoidCallback onTap;

  const _StatDeckTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.accentColor,
    required this.isSelected,
    this.isPulsing = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 14, color: accentColor),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: count > 0 ? (isPulsing ? const Color(0xFFE11D48) : accentColor) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accentColor : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Redesigned Modern Maintenance Card ─────────────────────────
class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRequest request;
  final Property property;
  final bool isLandlord;
  final bool isTenant;
  final VoidCallback onTap;

  const _MaintenanceCard({
    super.key,
    required this.request,
    required this.property,
    required this.isLandlord,
    required this.isTenant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isUrgent = request.priority == MaintenancePriority.urgent ||
        request.priority == MaintenancePriority.high;

    final statusStyle = _getStatusVisuals(request.status, loc);
    final categoryIcon = _getCategoryIcon(request.category);
    final categoryName = _getCategoryName(request.category, loc);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
          width: isUrgent ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFE11D48).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Strip Accent if Urgent
              if (isUrgent)
                Container(
                  height: 3,
                  width: double.infinity,
                  color: const Color(0xFFE11D48),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Meta Row: Category Badge + Priority Pill + Status Pill
                    Row(
                      children: [
                        // Category Icon & Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon, size: 12, color: const Color(0xFF475569)),
                              const SizedBox(width: 5),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Urgent Badge (if urgent)
                        if (isUrgent)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.alertTriangle, size: 11, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.priorityUrgent.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusStyle.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusStyle.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusStyle.icon, size: 11, color: statusStyle.fgColor),
                              const SizedBox(width: 4),
                              Text(
                                statusStyle.label.toUpperCase(),
                                style: TextStyle(
                                  color: statusStyle.fgColor,
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
                    const SizedBox(height: 12),

                    // 2. Request Title
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 3. Description (if available)
                    if (request.description != null && request.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.description!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 4. Photo Thumbnails Strip (if attached)
                    if (request.photosUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPhotosPreviewStrip(request.photosUrls, loc),
                    ],

                    // 5. 4-Stage Visual Progress Stepper Track
                    const SizedBox(height: 14),
                    _MaintenanceProgressStepper(status: request.status),

                    // 6. Financial Reconciliation Box (if cost / invoice exists)
                    if (request.costAmount != null || (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty)) ...[
                      const SizedBox(height: 12),
                      _MaintenanceFinancialBox(
                        request: request,
                        property: property,
                      ),
                    ],

                    // 7. Footer Meta: Creation Date & Details Link
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  request.createdAt != null
                                      ? DateFormat('dd MMM yyyy, HH:mm', loc.localeName).format(request.createdAt!)
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.viewDetailsAction,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF0F766E)),
                          ],
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
    );
  }

  Widget _buildPhotosPreviewStrip(List<String> urls, AppLocalizations loc) {
    final maxPreview = 3;
    final displayUrls = urls.take(maxPreview).toList();
    final remaining = urls.length - maxPreview;

    return Row(
      children: [
        ...displayUrls.map((url) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            )),
        if (remaining > 0)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$remaining',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

/// ── 4-Stage Visual Progress Stepper ────────────────────────────
class _MaintenanceProgressStepper extends StatelessWidget {
  final MaintenanceStatus status;

  const _MaintenanceProgressStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    int currentStep = 1;
    if (status == MaintenanceStatus.investigating) {
      currentStep = 2;
    } else if (status == MaintenanceStatus.inProgress) {
      currentStep = 3;
    } else if (status == MaintenanceStatus.resolved || status == MaintenanceStatus.closed) {
      currentStep = 4;
    }

    final steps = [
      loc.progressReported,
      loc.progressInvestigating,
      loc.progressInProgress,
      loc.progressResolved,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = stepNum <= currentStep;
          final isCurrent = stepNum == currentStep;
          final isLast = index == steps.length - 1;

          final Color stepColor;
          if (isCompleted) {
            stepColor = currentStep == 4 ? const Color(0xFF10B981) : const Color(0xFF0F766E);
          } else {
            stepColor = const Color(0xFFCBD5E1);
          }

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isCompleted ? stepColor : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: stepColor, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: isCompleted
                            ? const Icon(LucideIcons.check, size: 10, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: stepColor,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF0F172A)
                              : (isCompleted ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: stepNum < currentStep ? stepColor : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// ── Financial Settlement & Cost Box ────────────────────────────
class _MaintenanceFinancialBox extends StatelessWidget {
  final MaintenanceRequest request;
  final Property property;

  const _MaintenanceFinancialBox({
    required this.request,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currency = request.currency ?? (property.currency.isNotEmpty ? property.currency : 'EUR');

    String payerLabel = '';
    if (request.paidBy == 'tenant') {
      payerLabel = loc.costPaidByTenant;
    } else if (request.paidBy == 'landlord') {
      payerLabel = loc.costPaidByLandlord;
    }

    // Status pill
    final Color finColor;
    final Color finBg;
    final String finLabel;
    final IconData finIcon;

    switch (request.financialStatus) {
      case MaintenancePaymentStatus.pendingReview:
        finColor = const Color(0xFF0284C7);
        finBg = const Color(0xFFF0F9FF);
        finIcon = LucideIcons.search;
        finLabel = loc.costPendingReview;
        break;
      case MaintenancePaymentStatus.pendingPayment:
        finColor = const Color(0xFFD97706);
        finBg = const Color(0xFFFFFBEB);
        finIcon = LucideIcons.repeat;
        if (request.paidBy == 'landlord') {
          finLabel = loc.costDeductFromRent;
        } else if (request.paidBy == 'tenant') {
          finLabel = loc.costAddToRent;
        } else {
          finLabel = loc.waiting;
        }
        break;
      case MaintenancePaymentStatus.paid:
        finColor = const Color(0xFF059669);
        finBg = const Color(0xFFECFDF5);
        finIcon = LucideIcons.checkCircle2;
        finLabel = loc.paidLabel;
        break;
      case MaintenancePaymentStatus.rejected:
        finColor = const Color(0xFFE11D48);
        finBg = const Color(0xFFFFF1F2);
        finIcon = LucideIcons.xCircle;
        finLabel = loc.costRejected;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (request.costAmount != null) ...[
                Text(
                  CurrencyUtils.formatAmount(request.costAmount!, currency, useSymbol: true),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (request.hasPartialSettlement) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      loc.localeName == 'tr'
                          ? 'Kalan: ${CurrencyUtils.formatAmount(request.remainingAmount, currency, useSymbol: true)}'
                          : (loc.localeName == 'ru'
                              ? 'Остаток: ${CurrencyUtils.formatAmount(request.remainingAmount, currency, useSymbol: true)}'
                              : (loc.localeName.startsWith('sr')
                                  ? 'Preostalo: ${CurrencyUtils.formatAmount(request.remainingAmount, currency, useSymbol: true)}'
                                  : 'Rem: ${CurrencyUtils.formatAmount(request.remainingAmount, currency, useSymbol: true)}')),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
              ],
              if (payerLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    payerLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: finBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: finColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(finIcon, size: 11, color: finColor),
                    const SizedBox(width: 4),
                    Text(
                      finLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: finColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(request.invoicePdfUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.fileText, size: 12, color: Color(0xFFE11D48)),
                    const SizedBox(width: 5),
                    Text(
                      loc.viewInvoiceAction,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ── Empty States ───────────────────────────────────────────────
class _EmptyMaintenanceView extends StatelessWidget {
  final Property property;
  final bool isTenant;
  final bool isAgency;
  final VoidCallback onNewRequest;

  const _EmptyMaintenanceView({
    required this.property,
    required this.isTenant,
    required this.isAgency,
    required this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, size: 40, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 20),
            Text(
              loc.noIssuesTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.noIssuesMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (isTenant) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onNewRequest,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(
                  loc.reportIssue,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredView extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _EmptyFilteredView({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.filter, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 18),
            Text(
              loc.noMatchingIssues,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.x, size: 14),
              label: Text(loc.clearFilters),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                foregroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Helpers for Status and Category Visuals ────────────────────
class _StatusVisuals {
  final String label;
  final Color fgColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const _StatusVisuals({
    required this.label,
    required this.fgColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}

_StatusVisuals _getStatusVisuals(MaintenanceStatus status, AppLocalizations loc) {
  switch (status) {
    case MaintenanceStatus.open:
      return _StatusVisuals(
        label: loc.statusActive,
        fgColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        icon: LucideIcons.clock,
      );
    case MaintenanceStatus.investigating:
      return _StatusVisuals(
        label: loc.statusInvestigating,
        fgColor: const Color(0xFF0284C7),
        bgColor: const Color(0xFFF0F9FF),
        borderColor: const Color(0xFFBAE6FD),
        icon: LucideIcons.search,
      );
    case MaintenanceStatus.inProgress:
      return _StatusVisuals(
        label: loc.statusInProgressTechnician,
        fgColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        borderColor: const Color(0xFFDDD6FE),
        icon: LucideIcons.wrench,
      );
    case MaintenanceStatus.resolved:
      return _StatusVisuals(
        label: loc.statusResolved,
        fgColor: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFFA7F3D0),
        icon: LucideIcons.checkCircle2,
      );
    case MaintenanceStatus.closed:
      return _StatusVisuals(
        label: loc.statusClosed,
        fgColor: const Color(0xFF475569),
        bgColor: const Color(0xFFF1F5F9),
        borderColor: const Color(0xFFE2E8F0),
        icon: LucideIcons.archive,
      );
    case MaintenanceStatus.pending:
      return _StatusVisuals(
        label: loc.waiting,
        fgColor: const Color(0xFFB45309),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        icon: LucideIcons.clock,
      );
    case MaintenanceStatus.cancelled:
      return _StatusVisuals(
        label: loc.statusCancelled,
        fgColor: const Color(0xFFE11D48),
        bgColor: const Color(0xFFFFF1F2),
        borderColor: const Color(0xFFFECDD3),
        icon: LucideIcons.xCircle,
      );
  }
}

IconData _getCategoryIcon(MaintenanceCategory cat) {
  switch (cat) {
    case MaintenanceCategory.plumbing:
      return LucideIcons.droplets;
    case MaintenanceCategory.electrical:
      return LucideIcons.zap;
    case MaintenanceCategory.heating:
      return LucideIcons.flame;
    case MaintenanceCategory.appliance:
      return LucideIcons.tv;
    case MaintenanceCategory.internet:
      return LucideIcons.wifi;
    case MaintenanceCategory.structural:
      return LucideIcons.building2;
    case MaintenanceCategory.other:
      return LucideIcons.wrench;
  }
}

String _getCategoryName(MaintenanceCategory cat, AppLocalizations loc) {
  switch (cat) {
    case MaintenanceCategory.plumbing:
      return loc.categoryPlumbing;
    case MaintenanceCategory.electrical:
      return loc.categoryElectrical;
    case MaintenanceCategory.heating:
      return loc.categoryHeating;
    case MaintenanceCategory.appliance:
      return loc.categoryAppliance;
    case MaintenanceCategory.internet:
      return loc.categoryInternet;
    case MaintenanceCategory.structural:
      return loc.categoryStructural;
    case MaintenanceCategory.other:
      return loc.categoryOther;
  }
}
