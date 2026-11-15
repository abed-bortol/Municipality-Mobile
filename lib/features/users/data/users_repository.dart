import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
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
}
