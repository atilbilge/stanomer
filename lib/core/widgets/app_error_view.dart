import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/colors.dart';
import '../l10n/app_localizations.dart';

class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? message;

  const AppErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    // Check if it's a known timeout or connection error to show a better message
    final errorStr = error.toString();
    final isTimeout = errorStr.contains('timedOut') || errorStr.contains('timeout');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: StanomerColors.alertPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTimeout ? LucideIcons.wifiOff : LucideIcons.alertTriangle,
                size: 48,
                color: StanomerColors.alertPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message ?? loc.errorWithDetails(isTimeout ? 'Bağlantı Zaman Aşımı' : 'Bir Hata Oluştu'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              isTimeout 
                ? 'İnternet bağlantınız zayıf olabilir. Lütfen bağlantınızı kontrol edip tekrar deneyin.'
                : error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StanomerColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(loc.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: StanomerColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
