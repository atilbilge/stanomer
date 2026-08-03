import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'flavors.dart';
import 'core/config/env_config.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'features/subscriptions/data/subscription_service.dart';
import 'core/providers/lifecycle_provider.dart';
import 'core/widgets/web_responsive_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable path URL strategy (removes # from URLs)
  // This is vital for Supabase Auth redirect and GoRouter stability on web
  usePathUrlStrategy();
  
  // Log Flutter errors to console
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CATCHED ERROR: ${details.exception}\n${details.stack}');
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[main] .env file not found or failed to load: $e');
  }

  EnvConfig.validate();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  
  // Initialize RevenueCat
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  // Initialize RevenueCat with the current app locale
  final locale = container.read(localeProvider);
  await container.read(subscriptionServiceProvider).init(locale: locale);

  // No need to call syncLocale separately — init already handles it

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = kIsWeb ? null : AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledToken; // çift tetiklenmeyi önler

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLifecycleProvider).init();
      if (!kIsWeb) _initDeepLinks();
    });
  }

  Future<void> _initDeepLinks() async {
    if (kIsWeb || _appLinks == null) return;
    try {
      // Warm start: uygulama arka plandayken/açıkken gelen linkler
      _linkSubscription = _appLinks!.uriLinkStream.listen(
        (uri) {
          debugPrint('Deep link (warm): $uri');
          _scheduleDeepLink(uri);
        },
        onError: (err) => debugPrint('Deep link stream error: $err'),
      );

      // Cold start: uygulama kapalıyken link ile açılma
      final initialUri = await _appLinks!.getInitialLink();
      debugPrint('Deep link (cold): $initialUri');
      if (initialUri != null) {
        _scheduleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
  }

  /// Navigation'ı 300ms geciktir — uygulama resume sırasında router
  /// refreshListenable yarışını önler ve aynı token'ı tekrar işlemez.
  void _scheduleDeepLink(Uri uri) {
    if (uri.host != 'invite') return;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;
    if (token == _lastHandledToken) {
      debugPrint('Deep link: token $token zaten işlendi, atlanıyor');
      return;
    }
    _lastHandledToken = token;
    debugPrint('Handling deep link: $uri  token=$token');

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        debugPrint('Deep link navigate: widget unmounted, atlanıyor');
        return;
      }
      debugPrint('Deep link navigate: /invite?token=$token çağrılıyor');
      ref.read(goRouterProvider).go('/invite?token=$token');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    ref.read(appLifecycleProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: F.title,
      debugShowCheckedModeBanner: false,
      theme: StanomerTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return WebResponsiveWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
