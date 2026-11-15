import 'package:municipality/features/auth/data/auth_local_data_source.dart';
import 'package:municipality/features/auth/data/auth_remote_data_source.dart';
import 'package:municipality/features/auth/domain/auth_repository.dart';
import 'package:municipality/features/auth/domain/profile_update.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
      remote: ref.watch(authRemoteDataSourceProvider),
      local: ref.watch(authLocalDataSourceProvider),
    );

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.local});

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  @override
  Future<User?> getCachedUser() async {
    if (await local.readToken() == null) return null;
    return local.readUser();
  }

  @override
  Future<User> fetchCurrentUser() async {
    final user = await remote.me();
    await local.saveUser(user);
    return user;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final session = await remote.login(email: email, password: password);
    await local.saveSession(token: session.token, user: session.user);
    return session.user;
  }

  @override
  Future<User> register(RegisterRequest request) async {
    final session = await remote.register(request);
    await local.saveSession(token: session.token, user: session.user);
    return session.user;
  }

  @override
  Future<User> updateProfile(ProfileUpdate update) async {
    final user = await remote.updateProfile(update);
    await local.saveUser(user);
    return user;
  }

  @override
  Future<void> signOut() => local.clear();
}
