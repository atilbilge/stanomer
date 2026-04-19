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

  /// Helper to convert Flutter Locale to the BCP-47 / RevenueCat tag format (underscore preferred)
  String _getRevenueCatTag(Locale locale) {
    if (locale.languageCode == 'en') {
      return 'en_US'; // Matches "English (US)" in dashboard
    } else if (locale.languageCode == 'tr') {
      return 'tr'; // Matches "Turkish" in dashboard
    } else if (locale.languageCode == 'sr') {
      if (locale.scriptCode == 'Cyrl') {
        return 'sr_Cyrl'; // Matches "Serbian (Cyrillic)" in dashboard
      } else {
        return 'sr_Latn'; // Matches "Serbian (Latin)" in dashboard
      }
    }
    return locale.languageCode;
  }

  Future<void> init({Locale? locale}) async {
    if (kIsWeb) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final String apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;
    final config = PurchasesConfiguration(apiKey);

    // CRITICAL: Force the Native UI to use the app's selected locale 
    // instead of the device system locale.
    if (locale != null) {
      config.preferredUILocaleOverride = _getRevenueCatTag(locale);
      debugPrint('RevenueCat UI Locale forced to: ${config.preferredUILocaleOverride}');
    }

    await Purchases.configure(config);
    await updatePurchaseStatus();

    // Sync backend attribute as well
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
      final tag = _getRevenueCatTag(locale);

      // This attribute affects the backend/dashboard localization selection
      await Purchases.setAttributes({r'$preferredLanguage': tag});

      // Sometimes refreshing offerings helps the native UI sync with attribute changes
      await Purchases.getOfferings();

      debugPrint('RevenueCat subscriber attribute synced to: $tag');
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
