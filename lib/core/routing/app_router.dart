import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/property/presentation/add_property_screen.dart';
import '../../features/property/presentation/property_detail_screen.dart';
import '../../features/property/presentation/invitation_accept_screen.dart';
import '../../features/property/domain/property.dart';
import '../../features/property/presentation/property_settings_screen.dart';
import '../../features/auth/presentation/terms_conditions_screen.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/property/presentation/invite_tenant_screen.dart';
import '../../features/property/domain/contract.dart';
import '../../features/maintenance/presentation/create_maintenance_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/maintenance/presentation/maintenance_detail_screen.dart';
import '../../features/maintenance/domain/maintenance_request.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../../features/subscriptions/presentation/paywall_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authRepository = ref.read(authRepositoryProvider);
      
      // If we are currently deleting the account, do NOT redirect anywhere.
      // This prevents jumping to Dashboard during OAuth re-authentication.
      if (authRepository.isDeletingAccount) return null;

      final user = authRepository.currentUser;
      
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignup = state.matchedLocation == '/signup';
      final isGoingToInvite = state.matchedLocation == '/invite';

      if (user == null) {
        if (!isGoingToLogin && !isGoingToSignup && !isGoingToInvite) return '/login';
      } else {
        if (isGoingToLogin || isGoingToSignup || state.matchedLocation == '/') return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/add-property',
        builder: (context, state) => AddPropertyScreen(
          property: state.extra as Property?,
        ),
      ),
      GoRoute(
        path: '/property-detail',
        builder: (context, state) {
          if (state.extra is Property) {
            return PropertyDetailScreen(property: state.extra as Property);
          }
          final extras = state.extra as Map<String, dynamic>;
          return PropertyDetailScreen(
            property: extras['property'] as Property,
            initialTabIndex: extras['initialTabIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/invite-tenant',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return InviteTenantScreen(
            property: extras['property'] as Property,
            existingContract: extras['contract'] as Contract?,
            leaseTemplate: extras['leaseTemplate'] as Contract?,
          );
        },
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) => InvitationAcceptScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => MaintenanceScreen(
          property: state.extra as Property,
        ),
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) => CreateMaintenanceRequestScreen(
          property: state.extra as Property,
        ),
      ),
      GoRoute(
        path: '/property-settings',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return PropertySettingsScreen(
            property: extras['property'] as Property,
            initialTab: extras['initialTab'] as String? ?? 'contract',
          );
        },
      ),
      GoRoute(
        path: '/maintenance/detail',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return MaintenanceDetailScreen(
            property: extras['property'] as Property,
            request: extras['request'] as MaintenanceRequest,
          );
        },
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsScreen(),
      ),
    ],
  );
});
