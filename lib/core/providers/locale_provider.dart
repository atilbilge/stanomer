import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/subscriptions/data/subscription_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const _localeKey = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_localeKey);
    
    if (languageCode == 'sr_Cyrl') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl');
    } else if (languageCode == 'sr_Latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    } else if (languageCode == 'en') {
      return const Locale('en');
    } else if (languageCode == 'tr') {
      return const Locale('tr');
    }
    // Default to Serbian Latin with explicit script tag
    return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String code = locale.languageCode;
    if (locale.scriptCode != null) {
      code = '${locale.languageCode}_${locale.scriptCode}';
    }
    await prefs.setString(_localeKey, code);
    state = locale;

    // Sync language preference to RevenueCat Paywall
    ref.read(subscriptionServiceProvider).syncLocale(locale);
  }
}
