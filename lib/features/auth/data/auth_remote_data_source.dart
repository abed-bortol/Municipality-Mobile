import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/auth/domain/profile_update.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    AuthRemoteDataSource(ref.watch(dioProvider));

typedef AuthSession = ({String token, User user});

/// `/api/auth/*` endpoints (server/src/routes/auth.routes.js).
/// Responses look like `{ success, message, data: { user, token } }`.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSession> login({required String email, required String password}) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email.trim(), 'password': password},
        );
        return _session(res.data);
      });

  Future<AuthSession> register(RegisterRequest request) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: request.toJson(),
        );
        return _session(res.data);
      });

  Future<User> me() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/auth/me');
        return User.fromJson(_data(res.data)['user'] as Map<String, dynamic>);
      });

  /// `PUT /users/me` answers `{ success, user }` (not under `data`).
  Future<User> updateProfile(ProfileUpdate update) => _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/users/me',
          data: update.toJson(),
        );
        final user = res.data?['user'];
        if (user is! Map<String, dynamic>) {
          throw const UnexpectedResponseException();
        }
        return User.fromJson(user);
      });

  static AuthSession _session(Map<String, dynamic>? body) {
    final data = _data(body);
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map<String, dynamic>) {
      throw const UnexpectedResponseException();
    }
    return (token: token, user: User.fromJson(user));
  }

  static Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const UnexpectedResponseException();
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
