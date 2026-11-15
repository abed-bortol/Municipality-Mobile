import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';

/// Auth operations used by the presentation layer. All methods throw
/// `ApiException` on API failures.
abstract interface class AuthRepository {
  /// The user saved on this device, or null if there is no saved token.
  Future<User?> getCachedUser();

  /// Re-validates the saved token with the server (`GET /auth/me`).
  Future<User> fetchCurrentUser();

  Future<User> signIn({required String email, required String password});

  Future<User> register(RegisterRequest request);

  Future<void> signOut();
}
