import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.privacyPolicy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.termsOfServiceContent,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: StanomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
