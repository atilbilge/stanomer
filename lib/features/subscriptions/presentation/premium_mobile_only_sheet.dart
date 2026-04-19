import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/l10n/app_localizations.dart';

const _appStoreUrl = 'https://apps.apple.com/app/stanomer/idXXXXXXXXX'; // Replace with real App Store ID
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.aboptima.stanomer';

/// Shows a bottom sheet informing users that premium is only available on mobile.
void showPremiumMobileOnlySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _PremiumMobileOnlySheet(),
  );
}

class _PremiumMobileOnlySheet extends StatelessWidget {
  const _PremiumMobileOnlySheet();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Crown icon + header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: StanomerColors.brandPrimarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: StanomerColors.brandPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            loc.premiumMobileOnly,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.premiumMobileOnlyDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: StanomerColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Feature list
          Text(
            loc.premiumFeatures,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureRow(text: loc.premiumFeature1),
          _FeatureRow(text: loc.premiumFeature2),
          _FeatureRow(text: loc.premiumFeature3),
          _FeatureRow(text: loc.premiumFeature4),

          const SizedBox(height: 28),

          // App Store button
          _StoreButton(
            label: loc.downloadOnAppStore,
            logoAsset: 'assets/badge_appstore.png',
            color: Colors.black,
            onTap: () => _openUrl(_appStoreUrl),
          ),
          const SizedBox(height: 12),

          // Play Store button
          _StoreButton(
            label: loc.downloadOnPlayStore,
            logoAsset: 'assets/badge_playstore.png',
            color: const Color(0xFF01875F),
            onTap: () => _openUrl(_playStoreUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: StanomerColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: StanomerColors.successPrimary,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: StanomerColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final String label;
  final String logoAsset;
  final Color color;
  final VoidCallback onTap;

  const _StoreButton({
    required this.label,
    required this.logoAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
