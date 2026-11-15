import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/users/domain/officer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_repository.g.dart';

@Riverpod(keepAlive: true)
UsersRepository usersRepository(Ref ref) =>
    UsersRepository(ref.watch(dioProvider));

/// Health officers for assignment (staff only).
@riverpod
Future<List<Officer>> officers(Ref ref) =>
    ref.watch(usersRepositoryProvider).getOfficers();

/// `/api/users` (server/src/routes/user.routes.js).
class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<Officer>> getOfficers() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/officers');
    return jsonList(res.data, 'users').map(Officer.fromJson).toList();
  });

  /// Every account, newest first (administrators only).
  Future<List<User>> getUsers() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>('/users');
    return jsonList(res.data, 'users').map(User.fromJson).toList();
  });

  /// The server always creates a citizen; roles are granted afterwards.
  Future<User> createCitizen({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String? district,
  }) => apiCall(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'district': ?district,
      },
    );
    return User.fromJson(jsonObject(res.data, 'user'));
  });

  /// Empty [badgeNumber] / [title] let the server keep or generate them.
  Future<User> updateRole(
    String id,
    UserRole role, {
    String badgeNumber = '',
    String title = '',
  }) => apiCall(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/users/$id/role',
      data: {'role': role.apiValue, 'badgeNumber': badgeNumber, 'title': title},
    );
    return User.fromJson(jsonObject(res.data, 'user'));
  });
}
