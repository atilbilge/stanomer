import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class RoleSwitcherBottomSheet extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? activeRole;
  final Function(String) onRoleSelected;
  final VoidCallback onProfileTap;
  final VoidCallback onSignOutTap;

  const RoleSwitcherBottomSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.activeRole,
    required this.onRoleSelected,
    required this.onProfileTap,
    required this.onSignOutTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accentColor = StanomerColors.getRoleColor(activeRole);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StanomerColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Profil Başlığı
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accentColor.withOpacity(0.1),
                child: Text(
                  (userName ?? userEmail ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? (userEmail?.split('@')[0] ?? 'User'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: StanomerColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (userEmail != null)
                      Text(
                        userEmail!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: StanomerColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Text(
            loc.whatAreYou,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: StanomerColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _RoleOption(
            title: loc.landlord,
            subtitle: loc.portfolioManagement,
            icon: LucideIcons.building,
            isActive: activeRole == 'landlord',
            activeColor: StanomerColors.landlord,
            onTap: () => onRoleSelected('landlord'),
          ),
          const SizedBox(height: 12),
          _RoleOption(
            title: loc.tenant,
            subtitle: loc.paymentRequests,
            icon: LucideIcons.user,
            isActive: activeRole == 'tenant',
            activeColor: StanomerColors.tenant,
            onTap: () => onRoleSelected('tenant'),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _ActionItem(
            icon: LucideIcons.settings,
            label: loc.profileSettings,
            onTap: onProfileTap,
          ),
          _ActionItem(
            icon: LucideIcons.logOut,
            label: loc.logout,
            onTap: onSignOutTap,
            isDestructive: true,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : StanomerColors.borderDefault,
            width: isActive ? 2 : 1,
          ),
          color: isActive ? activeColor.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? activeColor : StanomerColors.bgPage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : StanomerColors.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isActive ? activeColor : StanomerColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StanomerColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(LucideIcons.checkCircle2, color: activeColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? StanomerColors.alertPrimary : StanomerColors.textPrimary;
    
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
