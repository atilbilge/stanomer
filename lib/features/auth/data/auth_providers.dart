import 'dart:async';
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

final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  final profileAsync = ref.watch(profileFutureProvider);

  final dbRole = profileAsync.value?['role'] as String?;
  if (dbRole != null && dbRole.isNotEmpty) {
    return dbRole;
  }
  return user?.userMetadata?['role'] as String?;
});

final routerListenableProvider = Provider<Listenable>((ref) {
  final listenable = _RouterListenable();
  
  // Listen to auth state, profile and role changes to update routing dynamically
  ref.listen(authStateProvider, (_, __) {
    listenable.notify();
  });
  ref.listen(profileFutureProvider, (_, __) {
    listenable.notify();
  });
  ref.listen(userRoleProvider, (_, __) {
    listenable.notify();
  });

  ref.onDispose(() {
    listenable.dispose();
  });
  
  return listenable;
});

class _RouterListenable extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void notify() {
    scheduleMicrotask(() {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }
}

