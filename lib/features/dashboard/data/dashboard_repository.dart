import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_repository.g.dart';

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(ref.watch(dioProvider));

/// `/api/dashboard` (server/src/routes/dashboard.routes.js).
class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> getStats() => apiCall(() async {
        final res =
            await _dio.get<Map<String, dynamic>>('/dashboard/statistics');
        return DashboardStats.fromJson(jsonObject(res.data, 'data'));
      });
}
