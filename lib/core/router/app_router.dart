import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/auth/presentation/screens/auth_screen.dart';
import 'package:municipality/features/home/presentation/home_screen.dart';
import 'package:municipality/features/splash/presentation/app_startup_controller.dart';
import 'package:municipality/features/splash/presentation/splash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const home = '/home';
}

/// Navigation is driven by state, like the website's
/// `if (!isAuthenticated) return <LoginPage />` in App.tsx:
/// splash until startup is done, then sign-in or home depending on the
/// session. Signing in/out and session expiry redirect automatically.
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

      final signedIn = ref.read(authControllerProvider).value is Authenticated;
      if (!signedIn) {
        return location == AppRoutes.signIn ? null : AppRoutes.signIn;
      }
      if (location == AppRoutes.signIn || location == AppRoutes.splash) {
        return AppRoutes.home;
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
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

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
