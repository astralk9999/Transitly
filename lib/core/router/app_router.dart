import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data_service.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/auth_repository.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/models/user_role.dart';
import '../../features/auth/signin_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/magic_link_screen.dart';
import '../../features/auth/recover_password_screen.dart';
import '../../features/auth/activate_driver_screen.dart';
import '../../features/auth/email_verify_pending_screen.dart';
import '../theme/transit_animations.dart';
import '../../features/city_picker/city_picker_screen.dart';
import '../../features/contributions/my_contributions_screen.dart';
import '../../features/debug/component_showcase_screen.dart';
import '../../features/driver/active_route_screen.dart';
import '../../features/driver/ai_schedule_import.dart';
import '../../features/driver/driver_dashboard_screen.dart';
import '../../features/driver/driver_history_screen.dart';
import '../../features/driver/driver_stats_screen.dart';
import '../../features/driver/route_editor/live_route_recorder.dart';
import '../../features/driver/route_editor/manual_route_editor.dart';
import '../../features/driver/route_editor/post_recording_editor.dart';
import '../../features/driver/route_editor/recorded_session.dart';
import '../../features/driver/start_route_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/home/tabs/card_tab.dart';
import '../../features/home/tabs/home_tab.dart';
import '../../features/home/tabs/map_tab.dart';
import '../../features/home/tabs/profile_tab.dart';
import '../../features/home/tabs/search_tab.dart';
import '../../features/management/manager_inbox_screen.dart';
import '../../features/operator_admin/operator_dashboard_screen.dart';
import '../../features/operator_admin/invitation_codes_screen.dart';
import '../../features/operator_admin/drivers_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/accessibility_settings_screen.dart';
import '../../features/profile/achievements_screen.dart';
import '../../features/profile/filter_presets_screen.dart';
import '../../features/offline/offline_regions_screen.dart';
import '../../features/profile/offline_data_screen.dart';
import '../../features/profile/planned_trips_screen.dart';
import '../../features/profile/reputation_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/accessible_buses/accessible_buses_screen.dart';
import '../../features/admin/admin_operators_screen.dart';
import '../../features/appearance/appearance_screen.dart';
import '../../features/appearance/custom_palette_screen.dart';
import '../../features/route_detail/route_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stop_detail/stop_detail_screen.dart';
import '../../features/suggestions/suggest_route_screen.dart';
import '../../features/suggestions/suggestion_contribute_screen.dart';
import '../../features/error/not_found_screen.dart';
import '../../features/suggestions/suggestion_detail_screen.dart';

/// Initial location of the app router. Overridable in tests to bypass the
/// splash screen (which holds a real `Future.delayed(3s)` timer).
final routerInitialLocationProvider = Provider<String>((ref) => '/splash');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final isAuth = authState is AuthAuthenticated;

  return GoRouter(
    initialLocation: ref.watch(routerInitialLocationProvider),
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/sign-in') ||
          loc.startsWith('/sign-up') ||
          loc.startsWith('/magic-link') ||
          loc.startsWith('/recover-password') ||
          loc.startsWith('/verify-email');
      final isHomeRoute = loc.startsWith('/home') ||
          loc.startsWith('/route') ||
          loc.startsWith('/stop');
      final isPublicRoute = loc == '/splash' || loc == '/onboarding';
      final isAdminRoute = loc.startsWith('/admin');
      final isManagementRoute = loc.startsWith('/management');

      // Auth routes: redirect to home if already authenticated
      if (isAuthRoute && isAuth) return '/home/inicio';

      // Admin/management routes require auth + role
      if (isAdminRoute || isManagementRoute) {
        if (!isAuth) return '/home/inicio';
        final role = ref.read(currentUserProvider).role;
        if (isAdminRoute && role != UserRole.admin) return '/home/inicio';
        if (isManagementRoute && role != UserRole.admin && role != UserRole.moderator) {
          return '/home/inicio';
        }
      }

      // All existing routes are guestOk for now
      if (isHomeRoute || isPublicRoute || isAuthRoute) return null;

      // Driver, management, contributions, etc. — guestOk for now
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeSlow(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlow(state, const OnboardingScreen()),
      ),

      // ── Auth routes ──
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => _slide(state, const SignInScreen()),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (context, state) => _slide(state, const SignUpScreen()),
      ),
      GoRoute(
        path: '/magic-link',
        pageBuilder: (context, state) => _slide(state, const MagicLinkScreen()),
      ),
      GoRoute(
        path: '/recover-password',
        pageBuilder: (context, state) => _slide(state, const RecoverPasswordScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => _slide(state, const EmailVerifyPendingScreen()),
      ),
      GoRoute(
        path: '/activate-driver',
        pageBuilder: (context, state) => _slide(state, const ActivateDriverScreen()),
      ),

      // ── Home shell with 5 tabs ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/inicio',
              pageBuilder: (context, state) => _fadeTab(state, const HomeTab()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/mapa',
              pageBuilder: (context, state) => _fadeTab(state, const MapTab()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/buscar',
              pageBuilder: (context, state) => _fadeTab(state, const SearchTab()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/tarjeta',
              pageBuilder: (context, state) => _fadeTab(state, const CardTab()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/perfil',
              pageBuilder: (context, state) => _fadeTab(state, const ProfileTab()),
            ),
          ]),
        ],
      ),

      // ── Detail screens (slide horizontal) ──
      GoRoute(
        path: '/route/:routeId',
        redirect: (context, state) {
          final id = state.pathParameters['routeId'];
          final mock = ref.read(mockDataServiceProvider);
          if (id == null || mock.getRouteById(id) == null) {
            return '/home/inicio';
          }
          return null;
        },
        pageBuilder: (context, state) => _slide(
          state,
          RouteDetailScreen(routeId: state.pathParameters['routeId']!),
        ),
      ),
      GoRoute(
        path: '/stop/:stopId',
        redirect: (context, state) {
          final id = state.pathParameters['stopId'];
          final mock = ref.read(mockDataServiceProvider);
          if (id == null || mock.getStopById(id) == null) {
            return '/home/inicio';
          }
          return null;
        },
        pageBuilder: (context, state) => _slide(
          state,
          StopDetailScreen(stopId: state.pathParameters['stopId']!),
        ),
      ),
      // ── Driver screens ──
      GoRoute(
        path: '/driver/dashboard',
        pageBuilder: (context, state) =>
            _slide(state, const DriverDashboardScreen()),
      ),
      GoRoute(
        path: '/driver/start',
        pageBuilder: (context, state) =>
            _slide(state, const StartRouteScreen()),
      ),
      GoRoute(
        path: '/driver/active',
        pageBuilder: (context, state) =>
            _slide(state, const ActiveRouteScreen()),
      ),
      GoRoute(
        path: '/driver/history',
        pageBuilder: (context, state) =>
            _slide(state, const DriverHistoryScreen()),
      ),
      GoRoute(
        path: '/driver/stats',
        pageBuilder: (context, state) =>
            _slide(state, const DriverStatsScreen()),
      ),
      GoRoute(
        path: '/driver/editor/manual',
        pageBuilder: (context, state) =>
            _slide(state, const ManualRouteEditor()),
      ),
      GoRoute(
        path: '/driver/editor/live',
        pageBuilder: (context, state) =>
            _slide(state, const LiveRouteRecorder()),
      ),
      GoRoute(
        path: '/driver/editor/post',
        pageBuilder: (context, state) {
          final session = state.extra as RecordedSession?;
          return _slide(
            state,
            PostRecordingEditor(
              trace: session?.trace ?? const [],
              stops: session?.stops ?? const [],
            ),
          );
        },
      ),
      GoRoute(
        path: '/driver/ai-import',
        pageBuilder: (context, state) =>
            _slide(state, const AiScheduleImport()),
      ),

      // ── Suggestions (static paths before parameterized) ──
      GoRoute(
        path: '/suggestions/new',
        pageBuilder: (context, state) =>
            _slide(state, const SuggestRouteScreen()),
      ),
      GoRoute(
        path: '/suggestions/contribute',
        pageBuilder: (context, state) =>
            _slide(state, const SuggestionContributeScreen()),
      ),
      GoRoute(
        path: '/suggestions/:suggestionId',
        pageBuilder: (context, state) => _slide(
          state,
          SuggestionDetailScreen(
              suggestionId: state.pathParameters['suggestionId']!),
        ),
      ),

      // ── Feedback ──
      GoRoute(
        path: '/feedback/:routeId',
        pageBuilder: (context, state) => _slideUp(
          state,
          FeedbackScreen(routeId: state.pathParameters['routeId']!),
        ),
      ),

      // ── Management ──
      GoRoute(
        path: '/management/inbox',
        pageBuilder: (context, state) =>
            _slide(state, const ManagerInboxScreen()),
      ),

      // ── Admin ──
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            _slide(state, const AdminScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) =>
            _slide(state, const AdminUsersScreen()),
      ),
      GoRoute(
        path: '/admin/operators',
        pageBuilder: (context, state) =>
            _slide(state, const AdminOperatorsScreen()),
      ),

      // ── Operator Admin ──
      GoRoute(
        path: '/operator-admin',
        pageBuilder: (context, state) =>
            _slide(state, const OperatorDashboardScreen()),
      ),
      GoRoute(
        path: '/city-picker',
        pageBuilder: (context, state) =>
            _slide(state, const CityPickerScreen()),
      ),
      GoRoute(
        path: '/operator-admin/invitation-codes',
        pageBuilder: (context, state) =>
            _slide(state, const InvitationCodesScreen()),
      ),
      GoRoute(
        path: '/operator-admin/drivers',
        pageBuilder: (context, state) =>
            _slide(state, const DriversScreen()),
      ),

      // ── Contributions ──
      GoRoute(
        path: '/contributions',
        pageBuilder: (context, state) =>
            _slide(state, const MyContributionsScreen()),
      ),

      // ── Profile sub-screens ──
      GoRoute(
        path: '/profile/reputation',
        pageBuilder: (context, state) =>
            _slide(state, const ReputationScreen()),
      ),
      GoRoute(
        path: '/profile/achievements',
        pageBuilder: (context, state) =>
            _slide(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/profile/accessibility',
        pageBuilder: (context, state) =>
            _slide(state, const AccessibilitySettingsScreen()),
      ),
      GoRoute(
        path: '/profile/filters',
        pageBuilder: (context, state) =>
            _slide(state, const FilterPresetsScreen()),
      ),
      GoRoute(
        path: '/profile/offline',
        pageBuilder: (context, state) =>
            _slide(state, const OfflineDataScreen()),
      ),
      GoRoute(
        path: '/profile/offline-regions',
        pageBuilder: (context, state) =>
            _slide(state, const OfflineRegionsScreen()),
      ),
      GoRoute(
        path: '/profile/trips',
        pageBuilder: (context, state) =>
            _slide(state, const PlannedTripsScreen()),
      ),

      // ── Appearance ──
      GoRoute(
        path: '/appearance',
        pageBuilder: (context, state) =>
            _slide(state, const AppearanceScreen()),
      ),
      GoRoute(
        path: '/appearance/custom',
        pageBuilder: (context, state) =>
            _slide(state, const CustomPaletteScreen()),
      ),

      // ── Accessible buses ──
      GoRoute(
        path: '/accessible-buses',
        pageBuilder: (context, state) =>
            _slide(state, const AccessibleBusesScreen()),
      ),

      // ── Debug ──
      GoRoute(
        path: '/debug/showcase',
        pageBuilder: (context, state) =>
            _slide(state, const ComponentShowcaseScreen()),
      ),
    ],
  );
});

// ── Transition helpers ──

/// Tabs: fast fade 150ms with custom easing
CustomTransitionPage<void> _fadeTab(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!TransitAnimations.shouldAnimate(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: TransitAnimations.transitEaseOut,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

/// Splash → Home: slow fade 400ms
CustomTransitionPage<void> _fadeSlow(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!TransitAnimations.shouldAnimate(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: TransitAnimations.transitEaseOut,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

/// Detail screens: slide + fade combined, custom easing
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!TransitAnimations.shouldAnimate(context)) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: TransitAnimations.transitEaseOut,
      );
      final slideTween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: slideTween.animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// Modals/sheets: slide up + fade, custom easing
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!TransitAnimations.shouldAnimate(context)) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: TransitAnimations.transitEaseOut,
      );
      final slideTween = Tween(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: slideTween.animate(curve),
          child: child,
        ),
      );
    },
  );
}
