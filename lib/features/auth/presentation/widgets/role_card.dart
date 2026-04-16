import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(StanomerRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(StanomerRadius.lg),
          border: Border.all(
            color: isSelected ? StanomerColors.brandPrimary : StanomerColors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? StanomerColors.brandPrimarySurface : StanomerColors.bgCard,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textTertiary, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
