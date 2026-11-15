import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/features/auth/data/auth_repository_impl.dart';
import 'package:municipality/features/auth/domain/auth_repository.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';

const _user = User(id: '1', name: 'Samer', email: 'samer@tripoli.lb');

class FakeAuthRepository implements AuthRepository {
  User? cachedUser;
  Object? fetchError;
  Object? signInError;
  bool signedOut = false;

  @override
  Future<User?> getCachedUser() async => cachedUser;

  @override
  Future<User> fetchCurrentUser() async {
    if (fetchError != null) throw fetchError!;
    return cachedUser!.copyWith(name: 'Fresh');
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
    return _user;
  }

  @override
  Future<User> register(RegisterRequest request) async => _user;

  @override
  Future<void> signOut() async => signedOut = true;
}

void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<AuthState> restored() => container.read(authControllerProvider.future);

  group('restore session', () {
    test('no saved session -> unauthenticated', () async {
      expect(await restored(), const AuthState.unauthenticated());
    });

    test('saved session is re-validated with the server', () async {
      repo.cachedUser = _user;
      expect(await restored(),
          AuthState.authenticated(_user.copyWith(name: 'Fresh')));
    });

    test('offline keeps the cached user signed in', () async {
      repo
        ..cachedUser = _user
        ..fetchError = const NetworkException('offline');
      expect(await restored(), const AuthState.authenticated(_user));
      expect(repo.signedOut, isFalse);
    });

    test('rejected token signs out', () async {
      repo
        ..cachedUser = _user
        ..fetchError =
            const ServerException(statusCode: 401, message: 'Invalid token');
      expect(await restored(), const AuthState.unauthenticated());
      expect(repo.signedOut, isTrue);
    });
  });

  test('signIn success -> authenticated', () async {
    await restored();
    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'samer@tripoli.lb', password: 'secret');
    expect(container.read(authControllerProvider).value,
        const AuthState.authenticated(_user));
  });

  test('signIn failure is thrown to the form, state unchanged', () async {
    await restored();
    repo.signInError =
        const ServerException(statusCode: 401, message: 'Invalid credentials');

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .signIn(email: 'x@y.z', password: 'bad'),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(authControllerProvider).value,
        const AuthState.unauthenticated());
  });

  test('session expiry signs out with the expired flag', () async {
    repo.cachedUser = _user;
    await restored();
    await container.read(authControllerProvider.notifier).onSessionExpired();

    expect(container.read(authControllerProvider).value,
        const AuthState.unauthenticated(sessionExpired: true));
    expect(repo.signedOut, isTrue);
  });
}
