import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../flavors.dart';

/// Environment Configuration using compile-time `--dart-define` or `.env`.
class EnvConfig {
  static const _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _envEnvironment = String.fromEnvironment('ENVIRONMENT');

  /// Supabase URL (checks dart-define, then .env if initialized, then Flavor fallback)
  static String get supabaseUrl {
    if (_envSupabaseUrl.isNotEmpty) return _envSupabaseUrl;
    if (F.appFlavor == Flavor.dev) {
      return 'https://thvbpifahvasyzmngpzp.supabase.co';
    }
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.env['SUPABASE_URL'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    }
    return 'https://ustcsvvkzsmsgzbptvpm.supabase.co';
  }

  /// Supabase Anon Key (checks dart-define, then .env if initialized, then Flavor fallback)
  static String get supabaseAnonKey {
    if (_envSupabaseAnonKey.isNotEmpty) return _envSupabaseAnonKey;
    if (F.appFlavor == Flavor.dev) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU';
    }
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.env['SUPABASE_ANON_KEY'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzdGNzdnZrenNtc2d6YnB0dnBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzY1NjIsImV4cCI6MjA5MDkxMjU2Mn0.g1A1GfLrebJ3MnQUaCmr45JGPPAPLU77XtUKP6doA4g';
  }

  /// Environment Name ('dev', 'prod', or 'production')
  static String get environment {
    if (_envEnvironment.isNotEmpty) return _envEnvironment;
    if (F.appFlavor == Flavor.dev) return 'dev';
    return 'production';
  }

  static bool get isDev => environment == 'dev' || F.appFlavor == Flavor.dev;
  static bool get isProd => (environment == 'prod' || environment == 'production') && F.appFlavor != Flavor.dev;

  /// Validates environment variables and logs status.
  static void validate() {
    debugPrint('[EnvConfig] Active Environment: $environment | Flavor: ${F.appFlavor} | URL: $supabaseUrl');
  }
}
