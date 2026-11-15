import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/features/auth/domain/user.dart';

part 'auth_state.freezed.dart';

/// Session state. While the stored session is being restored the
/// controller's `AsyncValue` is loading, so there is no "unknown" case here.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.authenticated(User user) = Authenticated;

  /// [sessionExpired] is true when the server rejected the token, so the UI
  /// can explain why the user was signed out.
  const factory AuthState.unauthenticated({
    @Default(false) bool sessionExpired,
  }) = Unauthenticated;
}
