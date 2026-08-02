import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../providers/agency_branding_provider.dart';
import '../../features/agency/domain/agency_color_scheme.dart';
import 'expandable_agency_logo.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/dashboard/presentation/widgets/profile_pill.dart';
import '../../features/property/data/property_repository.dart';
import '../../features/property/domain/property.dart';
import '../theme/colors.dart';
import 'app_logo.dart';

/// Item definition for desktop sidebar navigation
class DesktopNavItem {
  final IconData icon;
  final String label;
  final String route;
  final int badgeCount;
  final int index;
  /// If true, the item is shown greyed out and non-clickable.
  final bool isDisabled;
  /// Tooltip shown when the item is disabled.
  final String disabledTooltip;
  /// Optional tap handler override. When set, overrides the default route navigation.
  final VoidCallback? onTap;

  const DesktopNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badgeCount = 0,
    required this.index,
    this.isDisabled = false,
    this.disabledTooltip = '',
    this.onTap,
  });
}

/// A responsive shell for Web / Desktop viewports (screenWidth >= 900px)
/// Features a fixed (non-collapsible) Left Sidebar with Company/Agency Logo,
/// and a Top Workspace Header displaying Company / App Name & Role badge.
class DesktopNavigationShell extends ConsumerWidget {
  final Widget child;
  final int currentTabIndex;
  final ValueChanged<int>? onTabChanged;
  final List<DesktopNavItem>? navItems;
  final Widget? rightSidePanel;
  final VoidCallback? onRoleSwitcherTap;

  const DesktopNavigationShell({
    super.key,
    required this.child,
    this.currentTabIndex = 0,
    this.onTabChanged,
    this.navItems,
    this.rightSidePanel,
    this.onRoleSwitcherTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    // On mobile viewports (< 900px), return original mobile layout
    if (!isDesktop) {
      return child;
    }

    final loc = AppLocalizations.of(context)!;
    final brandingState = ref.watch(agencyBrandingProvider);
    final agencyColors = ref.watch(agencyColorSchemeProvider);
    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String? ?? 'landlord';
    final isAgency = role == 'agency';

    // Theme color resolution
    final primaryColor = isAgency
        ? agencyColors.primary
        : (brandingState.brandColor ?? StanomerColors.getRoleColor(role));

    final agencyProfileData = isAgency ? ref.watch(profileFutureProvider).value : null;
    final agencyUserLogoUrl = agencyProfileData?['logo_url'] as String?;
    final agencyCompanyName = (agencyProfileData?['company_name'] as String?)?.isNotEmpty == true
        ? agencyProfileData!['company_name'] as String
        : (agencyProfileData?['full_name'] as String?);

    final effectiveLogoUrl = brandingState.logoUrl ?? agencyUserLogoUrl;
    final displayTitle = brandingState.hasAgencyBranding
        ? brandingState.appTitle
        : (isAgency ? (agencyCompanyName ?? 'Acente') : 'Stanomer');

    const sidebarWidth = 240.0;

    // Tenant: watch their property for dynamic nav item behaviour
    final isTenant = role == 'tenant';
    Property? tenantProperty;
    if (isTenant) {
      final propertiesAsync = ref.watch(propertiesStreamProvider);
      tenantProperty = propertiesAsync.valueOrNull?.isNotEmpty == true
          ? propertiesAsync.valueOrNull!.first
          : null;
    }

    // Default nav items if none provided
    final navItemsList = navItems ??
        (isAgency
            ? [
                DesktopNavItem(
                  icon: LucideIcons.layoutDashboard,
                  label: loc.localeName == 'tr' ? 'Ana Panel' : 'Dashboard',
                  route: '/agency-dashboard',
                  index: 0,
                ),
                DesktopNavItem(
                  icon: LucideIcons.building2,
                  label: loc.tabPortfolio,
                  route: '/agency-dashboard?tab=portfolio',
                  index: 1,
                ),
                DesktopNavItem(
                  icon: LucideIcons.wallet,
                  label: loc.tabFinance,
                  route: '/agency-dashboard?tab=finance',
                  index: 2,
                ),
                DesktopNavItem(
                  icon: LucideIcons.wrench,
                  label: loc.localeName == 'tr' ? 'Bakım & Onarım' : 'Maintenance',
                  route: '/agency-dashboard?tab=requests',
                  index: 3,
                ),
              ]
            : role == 'landlord'
                // ── Landlord nav items ────────────────────────────────────────
                ? [
                    DesktopNavItem(
                      icon: LucideIcons.layoutDashboard,
                      label: loc.tabHome,
                      route: '/dashboard',
                      index: 0,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.building2,
                      label: loc.myProperties,
                      route: '/dashboard',
                      index: 1,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.wallet,
                      label: loc.tabFinance,
                      route: '/dashboard',
                      index: 2,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.wrench,
                      label: loc.tabRequests,
                      route: '/dashboard',
                      index: 3,
                    ),
                  ]
                // ── Tenant nav items ──────────────────────────────────────────
                : [
                    DesktopNavItem(
                      icon: LucideIcons.layoutDashboard,
                      label: loc.localeName == 'tr' ? 'Ana Panel' : 'Dashboard',
                      route: '/dashboard',
                      index: 0,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.wrench,
                      label: loc.localeName == 'tr' ? 'Bakım & Onarım' : 'Maintenance',
                      route: '/tenant-maintenance',
                      index: 1,
                      isDisabled: isTenant && tenantProperty == null,
                      disabledTooltip: loc.tenantNoPropertyMaintenanceTooltip,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.building,
                      label: loc.myProperty,
                      route: '/property-detail',
                      index: 2,
                      isDisabled: isTenant && tenantProperty == null,
                      disabledTooltip: loc.tenantNoPropertyTooltip,
                      onTap: isTenant && tenantProperty != null
                          ? () => context.push('/property-detail', extra: tenantProperty)
                          : null,
                    ),
                    DesktopNavItem(
                      icon: LucideIcons.settings,
                      label: loc.settingsHeader,
                      route: '/profile',
                      index: 3,
                    ),
                  ]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ── 1. Non-Collapsible Fixed Left Sidebar Navigation ─────────────────
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Sidebar Top Logo Section (Logo Only) ──────────────────────
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (effectiveLogoUrl != null && effectiveLogoUrl.trim().isNotEmpty)
                        ExpandableAgencyLogo(
                          logoUrl: effectiveLogoUrl,
                          title: displayTitle,
                          height: 38,
                        )
                      else if (brandingState.hasAgencyBranding || isAgency)
                        ExpandableAgencyLogo(
                          logoUrl: null,
                          title: displayTitle,
                          height: 38,
                        )
                      else
                        const AppLogo(height: 38),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Navigation Menu Items ─────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: navItemsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final item = navItemsList[i];
                      final isSelected = currentTabIndex == item.index;

                      return _buildSidebarNavItem(
                        context: context,
                        item: item,
                        isSelected: isSelected,
                        primaryColor: primaryColor,
                      );
                    },
                  ),
                ),

                // ── Bottom User Profile Tile (Hidden for Agency) ─────────────
                if (!isAgency)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: ProfilePill(
                      role: role,
                      email: user?.email,
                      onTap: onRoleSwitcherTap ?? () {},
                    ),
                  ),
              ],
            ),
          ),

          // ── 2. Main Desktop Workspace (Header + Content Area) ─────────────────
          Expanded(
            child: Column(
              children: [
                // ── Top Global Header (Company Name / App Title & Role Badge) ─
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Company / App Name Header
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      // Role / Landlord / Tenant Badge (Hidden for Agency)
                      if (!isAgency) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.20)),
                          ),
                          child: Text(
                            role == 'landlord' ? loc.landlord : loc.tenant,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Action Icons
                      IconButton(
                        icon: const Icon(LucideIcons.bell, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => context.push('/notifications'),
                        tooltip: 'Bildirimler',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.settings, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => context.push('/profile'),
                        tooltip: loc.settingsHeader,
                      ),
                    ],
                  ),
                ),

                // ── Desktop Content View ──────────────────────────────────────
                Expanded(
                  child: rightSidePanel != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: child,
                            ),
                            Container(
                              width: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: rightSidePanel!,
                              ),
                            ),
                          ],
                        )
                      : child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required BuildContext context,
    required DesktopNavItem item,
    required bool isSelected,
    required Color primaryColor,
  }) {
    final isDisabled = item.isDisabled;
    final bgColor = isDisabled
        ? Colors.transparent
        : isSelected
            ? primaryColor.withValues(alpha: 0.12)
            : Colors.transparent;

    final iconColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : isSelected
            ? primaryColor
            : const Color(0xFF64748B);

    final textColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : isSelected
            ? primaryColor
            : const Color(0xFF1E293B);

    return Tooltip(
      message: isDisabled ? item.disabledTooltip : '',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    if (item.onTap != null) {
                      item.onTap!();
                    } else if (onTabChanged != null) {
                      onTabChanged!(item.index);
                    } else {
                      context.go(item.route);
                    }
                  },
            hoverColor: isDisabled ? Colors.transparent : primaryColor.withValues(alpha: 0.08),
            splashColor: isDisabled ? Colors.transparent : primaryColor.withValues(alpha: 0.15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: (!isDisabled && isSelected)
                  ? BoxDecoration(
                      border: Border(
                        left: BorderSide(color: primaryColor, width: 3.5),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (!isDisabled && isSelected) ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDisabled)
                    const Icon(LucideIcons.lock, size: 13, color: Color(0xFFCBD5E1))
                  else if (item.badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
