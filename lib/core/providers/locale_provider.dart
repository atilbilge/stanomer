import 'package:flutter/foundation.dart';
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

  /// Normalizes and parses incoming language code into a supported Flutter Locale.
  static Locale? parseLocale(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toLowerCase().replaceAll('-', '_');

    if (normalized == 'sr_cyrl' || normalized == 'sr_cyr' || normalized == 'cyrl') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl');
    } else if (normalized == 'sr_latn' ||
        normalized == 'sr_lat' ||
        normalized == 'sr' ||
        normalized == 'rs' ||
        normalized == 'latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    } else if (normalized == 'en' || normalized == 'en_us' || normalized == 'en_gb') {
      return const Locale('en');
    } else if (normalized == 'tr' || normalized == 'tr_tr') {
      return const Locale('tr');
    } else if (normalized == 'ru' || normalized == 'ru_ru') {
      return const Locale('ru');
    }
    return null;
  }

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // 1. On Web, prioritize URL query parameters (?lang=sr or ?locale=sr_Latn)
    if (kIsWeb) {
      final uri = Uri.base;
      final queryParam = uri.queryParameters['lang'] ?? uri.queryParameters['locale'];
      final urlLocale = parseLocale(queryParam);
      if (urlLocale != null) {
        String saveCode = urlLocale.languageCode;
        if (urlLocale.scriptCode != null) {
          saveCode = '${urlLocale.languageCode}_${urlLocale.scriptCode}';
        }
        prefs.setString(_localeKey, saveCode);
        return urlLocale;
      }
    }

    // 2. Read saved preference
    final languageCode = prefs.getString(_localeKey);
    final savedLocale = parseLocale(languageCode);
    if (savedLocale != null) {
      return savedLocale;
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

    // Re-initialize RevenueCat with the new locale to force the Paywall to update
    if (!kIsWeb) {
      try {
        ref.read(subscriptionServiceProvider).init(locale: locale);
      } catch (_) {}
    }
  }
}
