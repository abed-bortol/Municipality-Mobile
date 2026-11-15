import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/coming_soon.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/auth/presentation/screens/auth_screen.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_screen.dart';
import 'package:municipality/features/more/presentation/more_screen.dart';
import 'package:municipality/features/shell/presentation/app_shell.dart';
import 'package:municipality/features/splash/presentation/app_startup_controller.dart';
import 'package:municipality/features/splash/presentation/splash_screen.dart';
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
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fadePage(state, AppShell(navigationShell: shell)),
        // Must follow ShellTab order.
        branches: [
          _tab(AppRoutes.dashboard, (_) => const DashboardScreen()),
          _tab(AppRoutes.reports,
              (s) => ComingSoonScreen(title: s.navReports)),
          _tab(AppRoutes.map, (s) => ComingSoonScreen(title: s.tripoliMap)),
          _tab(AppRoutes.alerts,
              (s) => ComingSoonScreen(title: s.surveillanceAlerts)),
          _tab(AppRoutes.notices,
              (s) => ComingSoonScreen(title: s.publicPortal)),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => const MoreScreen(),
              routes: [
                _comingSoon(AppRoutes.investigations, (s) => s.investigations),
                _comingSoon(AppRoutes.clusters, (s) => s.clusterDetection),
                _comingSoon(AppRoutes.analytics, (s) => s.epidemiologyCharts),
                _comingSoon(AppRoutes.exportDossier, (s) => s.exportDossier),
                _comingSoon(AppRoutes.users, (s) => s.usersOfficers),
                _comingSoon(AppRoutes.categories, (s) => s.reportCategories),
                _comingSoon(AppRoutes.systemSettings, (s) => s.systemSettings),
                _comingSoon(AppRoutes.auditLogs, (s) => s.auditTrail),
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

StatefulShellBranch _tab(String path, Widget Function(AppStrings) screen) =>
    StatefulShellBranch(routes: [
      GoRoute(
        path: path,
        builder: (context, state) => screen(AppStrings.of(context)),
      ),
    ]);

/// Placeholder for screens of upcoming phases (path is relative to /more).
GoRoute _comingSoon(String fullPath, String Function(AppStrings) title) =>
    GoRoute(
      path: fullPath.substring('${AppRoutes.more}/'.length),
      builder: (context, state) =>
          ComingSoonScreen(title: title(AppStrings.of(context))),
    );

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
