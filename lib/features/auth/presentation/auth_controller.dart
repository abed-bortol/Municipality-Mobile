import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/features/auth/data/auth_repository_impl.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/profile_update.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// App-wide session state (the website's AuthContext).
///
/// `build()` restores the saved session, so the provider is loading while the
/// splash screen is shown. [signIn] / [register] throw [ApiException] for the
/// form to display; they never put the whole app back into a loading state.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final cached = await repo.getCachedUser();
    if (cached == null) return const AuthState.unauthenticated();

    // Re-validate: role or account status may have changed since last time.
    // Unlike the website, being offline keeps the cached user signed in;
    // only an explicit 401/403 from the server signs them out.
    try {
      return AuthState.authenticated(await repo.fetchCurrentUser());
    } on ApiException catch (e) {
      if (e is ServerException && e.isAuthError) {
        await repo.signOut();
        return const AuthState.unauthenticated();
      }
      return AuthState.authenticated(cached);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> register(RegisterRequest request) async {
    final user = await ref.read(authRepositoryProvider).register(request);
    state = AsyncData(AuthState.authenticated(user));
  }

  /// Throws [ApiException]; on success every screen sees the new details.
  Future<void> updateProfile(ProfileUpdate update) async {
    final user = await ref.read(authRepositoryProvider).updateProfile(update);
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// Called by the HTTP layer when the server rejects the token.
  Future<void> onSessionExpired() async {
    if (state.value is! Authenticated) return;
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(AuthState.unauthenticated(sessionExpired: true));
  }
}
