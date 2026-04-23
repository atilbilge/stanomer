import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'features/subscriptions/data/subscription_service.dart';
import 'core/providers/lifecycle_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable path URL strategy (removes # from URLs)
  // This is vital for Supabase Auth redirect and GoRouter stability on web
  usePathUrlStrategy();
  
  // Log Flutter errors to console
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CATCHED ERROR: ${details.exception}');
  };

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
  @override
  void initState() {
    super.initState();
    // Initialize the lifecycle observer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLifecycleProvider).init();
    });
  }

  @override
  void dispose() {
    // Clean up
    ref.read(appLifecycleProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Stanomer',
      debugShowCheckedModeBanner: false,
      theme: StanomerTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
