import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// REVENUECAT CONFIG (Updated with user provided key)
const _apiKey = "test_kznmOrXWcBgsbbxxebGCBalOJJi";
const _entitlementId = "Stanomer Pro";

final isPremiumProvider = StateProvider<bool>((ref) => false);

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref);
});

class SubscriptionService {
  final Ref _ref;

  SubscriptionService(this._ref);

  Future<void> init() async {
    if (kIsWeb) return; // RevenueCat flutter SDK doesn't support Web yet

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
    
    await Purchases.configure(configuration);
    await updatePurchaseStatus();

    // Listen to customer info changes
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatusFromInfo(customerInfo);
    });
  }

  Future<void> updatePurchaseStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint("RevenueCat Error: $e");
    }
  }

  void _updateStatusFromInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[_entitlementId];
    final isPremium = entitlement != null && entitlement.isActive;
    _ref.read(isPremiumProvider.notifier).state = isPremium;
  }

  /// Present the Paywall using the RevenueCat UI SDK
  Future<void> presentPaywall() async {
    try {
      await RevenueCatUI.presentPaywall();
    } catch (e) {
      debugPrint("Paywall Error: $e");
    }
  }

  /// Present the Paywall only if the user is not already premium
  Future<void> presentPaywallIfNeeded() async {
    try {
      await RevenueCatUI.presentPaywallIfNeeded(_entitlementId);
    } catch (e) {
      debugPrint("Paywall Error: $e");
    }
  }

  /// Present the Customer Center for subscription management
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint("Customer Center Error: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint("Restore Error: $e");
    }
  }
}
