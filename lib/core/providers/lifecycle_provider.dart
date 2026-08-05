import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/agency/presentation/agency_dashboard_screen.dart';
import '../../features/property/data/property_repository.dart';

/// Provider that monitors the application lifecycle and handles
/// reconnections for Supabase Realtime when the app is resumed.
final appLifecycleProvider = Provider<AppLifecycleObserver>((ref) {
  return AppLifecycleObserver(ref);
});

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;
  bool _isInitialized = false;

  AppLifecycleObserver(this._ref);

  void init() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('DEBUG: App resumed - Refreshing Supabase Realtime connection');
      
      // 1. Force Supabase Realtime to reconnect
      // This is helpful if the socket was closed due to backgrounding
      // ignore: invalid_use_of_internal_member
      Supabase.instance.client.realtime.connect();

      // 2. Invalidate key stream providers to force a fresh subscription
      // This ensures that any staleness or 'timeout' errors in the streams are cleared
      _ref.invalidate(propertiesStreamProvider);
      _ref.invalidate(landlordSummaryProvider);
      _ref.invalidate(agencyAllPaymentsProvider);
    }
  }
}
