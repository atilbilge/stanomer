import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/colors.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final bool hasError;
  final VoidCallback onRetry;

  const ConnectionStatusIndicator({
    super.key,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasError) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: StanomerColors.alertPrimary.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(color: StanomerColors.alertPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 14, color: StanomerColors.alertPrimary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Şu an çevrimdışısınız, mevcut verilerle devam edebilirsiniz. Bağlanınca güncellenecektir.',
              style: TextStyle(
                color: StanomerColors.alertPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'YENİLE',
                style: TextStyle(
                  color: StanomerColors.alertPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
