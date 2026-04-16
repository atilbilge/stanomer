import 'package:flutter/material.dart';
import 'package:stanomer/core/theme/colors.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import '../../domain/contract.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentResponsibilitySelector extends StatelessWidget {
  final PaymentReceiver value;
  final ValueChanged<PaymentReceiver>? onChanged;

  const PaymentResponsibilitySelector({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isUnselected = value == PaymentReceiver.unselected;
    final bool isDisabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  context: context,
                  title: loc.utility,
                  subtitle: loc.tenantPaysDirectlyToUtility,
                  icon: LucideIcons.landmark,
                  isSelected: value == PaymentReceiver.utility,
                  isDisabled: isDisabled,
                  onTap: () => onChanged?.call(PaymentReceiver.utility),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOptionCard(
                  context: context,
                  title: loc.owner,
                  subtitle: loc.tenantPaysToLandlord,
                  icon: LucideIcons.home,
                  isSelected: value == PaymentReceiver.owner,
                  isDisabled: isDisabled,
                  onTap: () => onChanged?.call(PaymentReceiver.owner),
                ),
              ),
            ],
          ),
          if (isUnselected)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6), // Light orange/yellow background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.selectPaymentReceiverWarning,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB05000), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBorderColor = isDark ? StanomerColors.borderDefault.withOpacity(0.3) : StanomerColors.borderDefault;
    final baseBgColor = isDark ? Colors.black26 : StanomerColors.bgCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? StanomerColors.brandPrimarySurface : baseBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? StanomerColors.brandPrimary : baseBorderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textSecondary,
                  ),
                  Icon(
                    isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                    size: 18,
                    color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textTertiary.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: StanomerColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
