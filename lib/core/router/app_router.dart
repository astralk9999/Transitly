import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'error_builder.dart';
import 'redirect_guards.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/map_visible_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../features/auth/signin_screen.dart';
import '../../features/auth/auth_callback_screen.dart';
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
import '../../features/driver/driver_live_screen.dart';
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
import '../../features/management/route_editor_screen.dart';
import '../../features/management/admin_route_wizard.dart';
import '../../features/management/route_schedules_editor_screen.dart';
import '../../features/management/route_stops_editor_screen.dart';
import '../../features/management/community_management_screen.dart';
import '../../features/management/zones_management_screen.dart';
import '../../features/management/routes_management_screen.dart';
import '../../features/management/stops_management_screen.dart';
import '../../features/management/unified_inbox_screen.dart';
import '../../features/operator_admin/operator_dashboard_screen.dart';
import '../../features/operator_admin/invitation_codes_screen.dart';
import '../../features/operator_admin/drivers_screen.dart';
import '../../features/home/screens/place_search_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/accessibility_settings_screen.dart';
import '../../features/profile/achievements_screen.dart';
import '../../features/offline/offline_regions_screen.dart';
import '../../features/profile/offline_data_screen.dart';
import '../../features/profile/planned_trips_screen.dart';
import '../../features/profile/reputation_screen.dart';
import '../../features/admin/admin_geo_alerts_screen.dart';
import '../../features/admin/admin_requests_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/admin/admin_user_detail_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/nearby_buses/nearby_buses_screen.dart';
import '../../features/admin/admin_operators_screen.dart';
import '../../features/admin/route_moderation_screen.dart';
import '../../features/appearance/appearance_screen.dart';
import '../../features/appearance/custom_palette_screen.dart';
import '../../features/route_detail/route_detail_screen.dart';
import '../../features/route_detail/user_route_detail_screen.dart';
import '../../features/community/community_routes_screen.dart';
import '../../features/my_routes/my_routes_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stop_detail/stop_detail_screen.dart';
import '../../features/stop_detail/community_stop_detail_screen.dart';
import '../../features/create_route/create_route_wizard.dart';
import '../../features/suggestions/suggest_route_screen.dart';
import '../../features/suggestions/suggestion_contribute_screen.dart';
import '../../features/suggestions/suggestion_detail_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/route_planner/route_plan_results_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/privacy/privacy_screen.dart';
import '../../features/widgets_config/widgets_config_screen.dart';
import '../../features/widgets_config/widget_next_bus_config_screen.dart';
import '../../features/widgets_config/widget_my_line_config_screen.dart';
import '../../features/widgets_config/widget_nfc_balance_config_screen.dart';

/// Initial location of the app router. Overridable in tests to bypass the
/// splash screen (which holds a real `Future.delayed(3s)` timer).
final routerInitialLocationProvider = Provider<String>((ref) {
  final path = _widgetLaunchPath;
  if (path != null) {
    _widgetLaunchPath = null;
    return path;
  }
  return '/splash';
});

String? _widgetLaunchPath;

void setWidgetLaunchPath(String? path) {
  _widgetLaunchPath = path;
}

final routerProvider = Provider<GoRouter>((ref) {
  // refreshListenable: cuando cambia el estado de auth (p.ej. al volver del
  // login OAuth por deep link), go_router re-evalúa el `redirect` y navega
  // SOLO una vez. Sin esto, las pantallas navegaban a mano y, con OAuth, el
  // deep link + esa navegación coincidían → "Duplicate GlobalKey" (HomeShell
  // montado dos veces) y la pantalla de error.
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => authRefresh.value++);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: ref.watch(routerInitialLocationProvider),
    refreshListenable: authRefresh,
    errorBuilder: notFoundErrorBuilder,
    redirect: (context, state) {
      // Marca si el mapa es la pantalla visible superior, para suprimir el
      // fondo shader ahí (evita el conflicto GPU shader+FlutterMap). Se
      // difiere para no mutar un provider durante el routing.
      final isMap = state.matchedLocation == '/home/mapa';
      Future.microtask(() {
        final n = ref.read(mapVisibleProvider.notifier);
        if (n.state != isMap) n.state = isMap;
      });
      return authRedirect(ref, state);
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
      // Retorno del login OAuth (deep link transitly://login-callback). Sin
      // esta ruta go_router daba 404 al volver del navegador de Google.
      GoRoute(
        path: '/login-callback',
        pageBuilder: (context, state) =>
            _fadeSlow(state, const AuthCallbackScreen()),
      ),
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
        redirect: (context, state) => routeDetailRedirect(ref, state),
        pageBuilder: (context, state) => _slide(
          state,
          RouteDetailScreen(routeId: state.pathParameters['routeId']!),
        ),
      ),
      GoRoute(
        path: '/stop/:stopId',
        redirect: (context, state) => stopDetailRedirect(ref, state),
        pageBuilder: (context, state) => _slide(
          state,
          StopDetailScreen(stopId: state.pathParameters['stopId']!),
        ),
      ),
      // ── Driver screens ──
      // Modo conductor SIMPLE (iniciar ruta + posición en vivo). El dashboard
      // y el editor antiguos quedan en el código pero sin acceso desde la UI.
      // Ver docs/DESACTIVADO.md.
      GoRoute(
        path: '/driver/dashboard',
        pageBuilder: (context, state) =>
            _slide(state, const DriverLiveScreen()),
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

      // ── Create Route Wizard ──
      GoRoute(
        path: '/create-route',
        pageBuilder: (context, state) =>
            _slide(state, const CreateRouteWizard()),
      ),
      GoRoute(
        path: '/create-route/:routeId',
        pageBuilder: (context, state) => _slide(
          state,
          CreateRouteWizard(
            routeId: state.pathParameters['routeId'],
          ),
        ),
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

      // ── Community (user-created routes) ──
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) =>
            _slide(state, const CommunityRoutesScreen()),
      ),
      GoRoute(
        path: '/community/route/:routeId',
        pageBuilder: (context, state) => _slide(
          state,
          UserRouteDetailScreen(
              routeId: state.pathParameters['routeId']!),
        ),
      ),
      GoRoute(
        path: '/community/stop/:stopId',
        pageBuilder: (context, state) => _slide(
          state,
          CommunityStopDetailScreen(
              stopId: state.pathParameters['stopId']!),
        ),
      ),

      // ── My Routes ──
      GoRoute(
        path: '/my-routes',
        pageBuilder: (context, state) =>
            _slide(state, const MyRoutesScreen()),
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
            _slide(state, const UnifiedInboxScreen()),
      ),
      GoRoute(
        path: '/management/inbox-legacy',
        pageBuilder: (context, state) =>
            _slide(state, const ManagerInboxScreen()),
      ),
      GoRoute(
        path: '/management/routes',
        pageBuilder: (context, state) =>
            _slide(state, const RoutesManagementScreen()),
      ),
      GoRoute(
        path: '/management/stops',
        pageBuilder: (context, state) =>
            _slide(state, const StopsManagementScreen()),
      ),
      GoRoute(
        path: '/management/community',
        pageBuilder: (context, state) =>
            _slide(state, const CommunityManagementScreen()),
      ),
      GoRoute(
        path: '/management/zones',
        pageBuilder: (context, state) =>
            _slide(state, const ZonesManagementScreen()),
      ),
      GoRoute(
        path: '/management/routes/new',
        pageBuilder: (context, state) => _slide(
          state,
          AdminRouteWizard(
            initialOperatorId: state.uri.queryParameters['operator'],
          ),
        ),
      ),
      // Editor simple (formulario) para edición rápida de campos básicos.
      GoRoute(
        path: '/management/routes/new-simple',
        pageBuilder: (context, state) => _slide(
          state,
          RouteEditorScreen(
            initialOperatorId: state.uri.queryParameters['operator'],
          ),
        ),
      ),
      // Edición de línea oficial con el wizard (datos + paradas en mapa +
      // horarios), igual que el de comunidad. El form simple sigue en
      // /management/routes/:id/simple por si se necesita edición rápida.
      GoRoute(
        path: '/management/routes/:id',
        pageBuilder: (context, state) => _slide(
          state,
          AdminRouteWizard(routeId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/management/routes/:id/simple',
        pageBuilder: (context, state) => _slide(
          state,
          RouteEditorScreen(routeId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/management/routes/:id/stops',
        pageBuilder: (context, state) => _slide(
          state,
          RouteStopsEditorScreen(routeId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/management/routes/:id/schedules',
        pageBuilder: (context, state) => _slide(
          state,
          RouteSchedulesEditorScreen(routeId: state.pathParameters['id']!),
        ),
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
        path: '/admin/users/:userId',
        pageBuilder: (context, state) => _slide(
          state,
          AdminUserDetailScreen(userId: state.pathParameters['userId']!),
        ),
      ),
      GoRoute(
        path: '/admin/operators',
        pageBuilder: (context, state) =>
            _slide(state, const AdminOperatorsScreen()),
      ),
      GoRoute(
        path: '/admin/routes',
        pageBuilder: (context, state) =>
            _slide(state, const RouteModerationScreen()),
      ),
      GoRoute(
        path: '/admin/requests',
        pageBuilder: (context, state) =>
            _slide(state, const AdminRequestsScreen()),
      ),
      GoRoute(
        path: '/admin/geo-alerts',
        pageBuilder: (context, state) =>
            _slide(state, const AdminGeoAlertsScreen()),
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
        path: '/profile/privacy',
        pageBuilder: (context, state) =>
            _slide(state, const PrivacyScreen()),
      ),
      GoRoute(
        path: '/legal/terms',
        pageBuilder: (context, state) =>
            _slide(state, const LegalScreen(doc: LegalDoc.terms)),
      ),
      GoRoute(
        path: '/legal/privacy',
        pageBuilder: (context, state) =>
            _slide(state, const LegalScreen(doc: LegalDoc.privacy)),
      ),
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

      // ── Nearby buses ──
      GoRoute(
        path: '/nearby-buses',
        pageBuilder: (context, state) =>
            _slide(state, const NearbyBusesScreen()),
      ),

      // ── Notifications ──
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _slide(state, const NotificationsScreen()),
      ),

      // ── Widgets config ──
      // /profile/widgets es la entrada desde Perfil. Antes apuntaba a
      // WidgetsSettingsScreen (TextFields simples sin preview ni
      // personalización). Ahora ambos paths apuntan a la pantalla
      // "Centro de widgets" rediseñada con mockup + selectores.
      GoRoute(
        path: '/profile/widgets',
        pageBuilder: (context, state) =>
            _slide(state, const WidgetsConfigScreen()),
      ),
      GoRoute(
        path: '/widgets-config',
        pageBuilder: (context, state) =>
            _slide(state, const WidgetsConfigScreen()),
      ),
      GoRoute(
        path: '/widgets-config/next-bus',
        pageBuilder: (context, state) =>
            _slide(state, const WidgetNextBusConfigScreen()),
      ),
      GoRoute(
        path: '/widgets-config/my-line',
        pageBuilder: (context, state) =>
            _slide(state, const WidgetMyLineConfigScreen()),
      ),
      GoRoute(
        path: '/widgets-config/nfc-balance',
        pageBuilder: (context, state) =>
            _slide(state, const WidgetNfcBalanceConfigScreen()),
      ),

      // ── Debug ──
      if (!kReleaseMode)
        GoRoute(
          path: '/debug/showcase',
          pageBuilder: (context, state) =>
              _slide(state, const ComponentShowcaseScreen()),
        ),

      // ── Place search ──
      GoRoute(
        path: '/search/places',
        pageBuilder: (context, state) =>
            _slide(state, const PlaceSearchScreen()),
      ),

      // ── Route planner ──
      GoRoute(
        path: '/route-plan',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slide(
            state,
            RoutePlanResultsScreen(
              fromStopId: extra['fromStopId'] as String?,
              toStopId: extra['toStopId'] as String,
              useMyLocation: extra['useMyLocation'] as bool? ?? false,
            ),
          );
        },
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

/// En web/escritorio centra el contenido (como la pestaña de Inicio) para que
/// las pantallas no se estiren a lo ancho de un monitor. En móvil no afecta.
Widget _webConstrain(Widget child) =>
    kIsWeb ? ContentConstraints(maxWidth: 900, child: child) : child;

/// Detail screens: slide + fade combined, custom easing
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: _webConstrain(child),
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
    child: _webConstrain(child),
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
