import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../data/subscription_service.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StanomerColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: StanomerColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: PaywallView(
        onDismiss: () => context.pop(),
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          ref.read(subscriptionServiceProvider).updatePurchaseStatus();
          context.pop();
        },
      ),
    );
  }
}
