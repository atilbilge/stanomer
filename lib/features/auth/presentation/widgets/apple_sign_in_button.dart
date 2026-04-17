import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

    return SignInWithAppleButton(
      onPressed: isLoading ? null : onPressed,
      text: loc.continueWithApple,
      borderRadius: const BorderRadius.all(StanomerRadius.md),
    );
  }
}
