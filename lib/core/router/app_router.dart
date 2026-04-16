import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/contributions/my_contributions_screen.dart';
import '../../features/debug/component_showcase_screen.dart';
import '../../features/driver/active_route_screen.dart';
import '../../features/driver/ai_schedule_import.dart';
import '../../features/driver/driver_history_screen.dart';
import '../../features/driver/driver_stats_screen.dart';
import '../../features/driver/route_editor/live_route_recorder.dart';
import '../../features/driver/route_editor/manual_route_editor.dart';
import '../../features/driver/route_editor/post_recording_editor.dart';
import '../../features/driver/route_editor/schedule_editor.dart';
import '../../features/driver/start_route_screen.dart';
import '../../features/feedback/feedback_detail_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/home/tabs/card_tab.dart';
import '../../features/home/tabs/home_tab.dart';
import '../../features/home/tabs/map_tab.dart';
import '../../features/home/tabs/profile_tab.dart';
import '../../features/home/tabs/search_tab.dart';
import '../../features/management/manager_inbox_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/accessibility_settings_screen.dart';
import '../../features/profile/achievements_screen.dart';
import '../../features/profile/filter_presets_screen.dart';
import '../../features/profile/offline_data_screen.dart';
import '../../features/profile/planned_trips_screen.dart';
import '../../features/route_detail/route_detail_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stop_detail/stop_detail_screen.dart';
import '../../features/suggestions/suggest_route_screen.dart';
import '../../features/suggestions/suggestion_contribute_screen.dart';
import '../../features/error/not_found_screen.dart';
import '../../features/suggestions/suggestion_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeSlow(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlow(state, const OnboardingScreen()),
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
        pageBuilder: (context, state) => _slide(
          state,
          RouteDetailScreen(routeId: state.pathParameters['routeId']!),
        ),
      ),
      GoRoute(
        path: '/stop/:stopId',
        pageBuilder: (context, state) => _slide(
          state,
          StopDetailScreen(stopId: state.pathParameters['stopId']!),
        ),
      ),
      GoRoute(
        path: '/search/results',
        pageBuilder: (context, state) =>
            _slide(state, const SearchResultsScreen()),
      ),

      // ── Driver screens ──
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
        pageBuilder: (context, state) =>
            _slide(state, const PostRecordingEditor()),
      ),
      GoRoute(
        path: '/driver/editor/schedule',
        pageBuilder: (context, state) =>
            _slide(state, const ScheduleEditor()),
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

      // ── Feedback (static paths before parameterized) ──
      GoRoute(
        path: '/feedback/detail',
        pageBuilder: (context, state) =>
            _slide(state, const FeedbackDetailScreen()),
      ),
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

      // ── Contributions ──
      GoRoute(
        path: '/contributions',
        pageBuilder: (context, state) =>
            _slide(state, const MyContributionsScreen()),
      ),

      // ── Profile sub-screens ──
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
        path: '/profile/trips',
        pageBuilder: (context, state) =>
            _slide(state, const PlannedTripsScreen()),
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

/// Tabs: fast fade 150ms
CustomTransitionPage<void> _fadeTab(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Splash → Home: slow fade 400ms
CustomTransitionPage<void> _fadeSlow(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
