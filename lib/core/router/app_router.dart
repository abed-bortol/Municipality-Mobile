import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:municipality/features/analytics/presentation/analytics_screen.dart';
import 'package:municipality/features/audit/presentation/audit_logs_screen.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/auth/presentation/screens/auth_screen.dart';
import 'package:municipality/features/categories/presentation/screens/categories_screen.dart';
import 'package:municipality/features/clusters/presentation/screens/clusters_screen.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_screen.dart';
import 'package:municipality/features/export/presentation/export_dossier_screen.dart';
import 'package:municipality/features/investigations/presentation/screens/investigation_form_screen.dart';
import 'package:municipality/features/investigations/presentation/screens/investigations_screen.dart';
import 'package:municipality/features/map/presentation/screens/map_screen.dart';
import 'package:municipality/features/more/presentation/more_screen.dart';
import 'package:municipality/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:municipality/features/portal/presentation/public_portal_screen.dart';
import 'package:municipality/features/profile/presentation/profile_screen.dart';
import 'package:municipality/features/reports/presentation/screens/new_report_screen.dart';
import 'package:municipality/features/reports/presentation/screens/report_details_screen.dart';
import 'package:municipality/features/reports/presentation/screens/reports_screen.dart';
import 'package:municipality/features/shell/presentation/app_shell.dart';
import 'package:municipality/features/settings/presentation/system_settings_screen.dart';
import 'package:municipality/features/splash/presentation/app_startup_controller.dart';
import 'package:municipality/features/splash/presentation/splash_screen.dart';
import 'package:municipality/features/users/presentation/screens/users_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Navigation is driven by state, like the website's
/// `if (!isAuthenticated) return <LoginPage />` in App.tsx:
/// splash until startup is done, then sign-in or the role-based shell.
/// Signing in/out, session expiry and role checks redirect automatically.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Bridges Riverpod -> go_router: re-run redirects when these change.
  final refresh = ValueNotifier(0);
  void bump(_, _) => refresh.value++;
  ref
    ..listen(appStartupControllerProvider, bump)
    ..listen(authControllerProvider, bump)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!ref.read(appStartupControllerProvider)) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final auth = ref.read(authControllerProvider).value;
      if (auth is! Authenticated) {
        return location == AppRoutes.signIn ? null : AppRoutes.signIn;
      }
      if (location == AppRoutes.signIn || location == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }
      if (!AppRoutes.canAccess(location, auth.user.role)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (context, state) => _fadePage(state, const AuthScreen()),
      ),
      // Full screen, above the tabs (opened from the app bar bell).
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fadePage(state, AppShell(navigationShell: shell)),
        // Must follow ShellTab order.
        branches: [
          _tab(AppRoutes.dashboard, (_) => const DashboardScreen()),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.reports,
              builder: (context, state) => const ReportsScreen(),
              routes: [
                // 'new' must come before ':id'.
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const NewReportScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      ReportDetailsScreen(id: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'investigation',
                      builder: (context, state) => InvestigationFormScreen(
                          reportId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          _tab(AppRoutes.map, (_) => const MapScreen()),
          _tab(AppRoutes.alerts, (_) => const AlertsScreen()),
          _tab(AppRoutes.notices, (_) => const PublicPortalScreen()),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: _relativeToMore(AppRoutes.investigations),
                  builder: (context, state) => const InvestigationsScreen(),
                ),
                GoRoute(
                  path: _relativeToMore(AppRoutes.clusters),
                  builder: (context, state) => const ClustersScreen(),
                ),
                GoRoute(
                  path: _relativeToMore(AppRoutes.analytics),
                  builder: (context, state) => const AnalyticsScreen(),
                ),
                _moreRoute(
                    AppRoutes.exportDossier, (_) => const ExportDossierScreen()),
                _moreRoute(AppRoutes.profile, (_) => const ProfileScreen()),
                _moreRoute(AppRoutes.users, (_) => const UsersScreen()),
                _moreRoute(AppRoutes.categories, (_) => const CategoriesScreen()),
                _moreRoute(
                    AppRoutes.systemSettings, (_) => const SystemSettingsScreen()),
                _moreRoute(AppRoutes.auditLogs, (_) => const AuditLogsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

StatefulShellBranch _tab(String path, Widget Function(AppLocalizations) screen) =>
    StatefulShellBranch(routes: [
      GoRoute(
        path: path,
        builder: (context, state) => screen(context.l10n),
      ),
    ]);

/// A screen under the More tab ([fullPath] is the absolute route).
GoRoute _moreRoute(String fullPath, WidgetBuilder screen) => GoRoute(
      path: _relativeToMore(fullPath),
      builder: (context, state) => screen(context),
    );

String _relativeToMore(String fullPath) =>
    fullPath.substring('${AppRoutes.more}/'.length);

/// Top-level screens swap with a short cross-fade (none if the user turned
/// animations off).
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, _, child) =>
          MediaQuery.disableAnimationsOf(context)
              ? child
              : FadeTransition(
                  opacity:
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: child,
                ),
    );
