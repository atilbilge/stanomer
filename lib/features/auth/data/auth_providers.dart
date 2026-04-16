import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

final profileFutureProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  
  return data;
});

final routerListenableProvider = Provider<Listenable>((ref) {
  final listenable = _RouterListenable();
  
  // Listen to auth state changes and notify the router
  ref.listen(authStateProvider, (_, __) {
    listenable.notify();
  });
  
  return listenable;
});

class _RouterListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
