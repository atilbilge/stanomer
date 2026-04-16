import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: StanomerColors.textPrimary,
        side: const BorderSide(color: StanomerColors.borderDefault),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: StanomerColors.brandPrimary,
              ),
            )
          else ...[
            const Icon(
              LucideIcons.apple,
              size: 20,
              color: StanomerColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Text(loc.continueWithApple),
          ],
        ],
      ),
    );
  }
}
