import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Reusable small muted footer for agency screens and white-label views.
class PoweredByStanomerFooter extends StatelessWidget {
  final Color? textColor;

  const PoweredByStanomerFooter({super.key, this.textColor});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = (textColor ?? StanomerColors.textTertiary).withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Powered by Stanomer © 2026',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: effectiveColor,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
