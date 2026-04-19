import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// REVENUECAT CONFIG (Updated from dashboard screenshots)
const _iosApiKey = "appl_FcQuazkBVIyEJMFWXtdCNPCJIrR";
const _androidApiKey = "goog_DXsEfTLjfUTHBSqYcnfvJNkCQzq";
const _entitlementId = "Stanomer Pro";

final isPremiumProvider = StateProvider<bool>((ref) => false);

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref);
});

class SubscriptionService {
  final Ref _ref;

  SubscriptionService(this._ref);

  Future<void> init({Locale? locale}) async {
    if (kIsWeb) return; 

    await Purchases.setLogLevel(LogLevel.debug);

    final String apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;
    final config = PurchasesConfiguration(apiKey);
    
    await Purchases.configure(config);
    await updatePurchaseStatus();

    // Sync locale immediately if provided
    if (locale != null) await syncLocale(locale);

    // Listen to customer info changes
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatusFromInfo(customerInfo);
    });
  }

  /// Sync the app locale to RevenueCat so the Paywall opens in the correct language.
  /// RevenueCat uses the '$preferredLanguage' reserved subscriber attribute.
  Future<void> syncLocale(Locale locale) async {
    if (kIsWeb) return;
    try {
      String tag;
      
      if (locale.languageCode == 'en') {
        tag = 'en-US'; // Matches "English (US)" in dashboard
      } else if (locale.languageCode == 'tr') {
        tag = 'tr';    // Matches "Turkish" in dashboard
      } else if (locale.languageCode == 'sr') {
        if (locale.scriptCode == 'Cyrl') {
          tag = 'sr-Cyrl'; // Matches "Serbian (Cyrillic)" in dashboard
        } else {
          tag = 'sr-Latn'; // Matches "Serbian (Latin)" in dashboard
        }
      } else {
        tag = locale.languageCode;
      }

      await Purchases.setAttributes({r'$preferredLanguage': tag});
      
      // Sometimes we need to refresh offerings to ensure the native UI 
      // picks up the attribute change for the paywall.
      await Purchases.getOfferings();
      
      debugPrint('RevenueCat locale synced to: $tag');
    } catch (e) {
      debugPrint('RevenueCat syncLocale error: $e');
    }
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
