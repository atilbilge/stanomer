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
import '../../features/support/presentation/support_screen.dart';
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
          property: state.extra is Property
              ? state.extra as Property
              : (state.extra is Map<String, dynamic>
                  ? Property.fromJson(state.extra as Map<String, dynamic>)
                  : null),
        ),
      ),
      GoRoute(
        path: '/property-detail',
        builder: (context, state) {
          // Guard: extra can be null if iOS cleared navigation state while the
          // app was backgrounded / the tablet was sleeping. Fall back to the
          // Dashboard so the user sees a clean state instead of a crash.
          if (state.extra == null) return const DashboardScreen();

          if (state.extra is Property) {
            return PropertyDetailScreen(property: state.extra! as Property);
          }

          final extras = state.extra as Map<String, dynamic>;
          final rawProperty = extras['property'];
          final property = rawProperty is Property
              ? rawProperty
              : (rawProperty is Map<String, dynamic>
                  ? Property.fromJson(rawProperty)
                  : null);
          if (property == null) return const DashboardScreen();

          return PropertyDetailScreen(
            property: property,
            initialTabIndex: extras['initialTabIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/invite-tenant',
        builder: (context, state) {
          if (state.extra == null) return const DashboardScreen();
          final extras = state.extra as Map<String, dynamic>;
          final rawProperty = extras['property'];
          final property = rawProperty is Property
              ? rawProperty
              : (rawProperty is Map<String, dynamic>
                  ? Property.fromJson(rawProperty)
                  : null);
          if (property == null) return const DashboardScreen();
          return InviteTenantScreen(
            property: property,
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
        builder: (context, state) {
          if (state.extra == null || state.extra is! Property) {
            return const DashboardScreen();
          }
          return MaintenanceScreen(
            property: state.extra! as Property,
          );
        },
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) {
          if (state.extra == null || state.extra is! Property) {
            return const DashboardScreen();
          }
          return CreateMaintenanceRequestScreen(
            property: state.extra! as Property,
          );
        },
      ),
      GoRoute(
        path: '/property-settings',
        builder: (context, state) {
          if (state.extra == null) return const DashboardScreen();
          final extras = state.extra as Map<String, dynamic>;
          final rawProperty = extras['property'];
          final property = rawProperty is Property
              ? rawProperty
              : (rawProperty is Map<String, dynamic>
                  ? Property.fromJson(rawProperty)
                  : null);
          if (property == null) return const DashboardScreen();
          return PropertySettingsScreen(
            property: property,
            initialTab: extras['initialTab'] as String? ?? 'contract',
          );
        },
      ),
      GoRoute(
        path: '/maintenance/detail',
        builder: (context, state) {
          if (state.extra == null) return const DashboardScreen();
          final extras = state.extra as Map<String, dynamic>;
          final rawProperty = extras['property'];
          final property = rawProperty is Property
              ? rawProperty
              : (rawProperty is Map<String, dynamic>
                  ? Property.fromJson(rawProperty)
                  : null);
          final request = extras['request'] as MaintenanceRequest?;
          if (property == null || request == null) return const DashboardScreen();
          return MaintenanceDetailScreen(
            property: property,
            request: request,
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
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );
});
