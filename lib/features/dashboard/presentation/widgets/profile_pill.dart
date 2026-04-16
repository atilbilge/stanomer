import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class ProfilePill extends StatelessWidget {
  final String? role;
  final String? email;
  final VoidCallback onTap;

  const ProfilePill({
    super.key,
    required this.role,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accentColor = StanomerColors.getRoleColor(role);
    final roleName = role == 'landlord' ? loc.landlord : (role == 'tenant' ? loc.tenant : '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: StanomerColors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: accentColor,
              child: Text(
                (email ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (roleName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: StanomerColors.borderDefault,
              ),
              const SizedBox(width: 8),
              Text(
                roleName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StanomerColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: StanomerColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
