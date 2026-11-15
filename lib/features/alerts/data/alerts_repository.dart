import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alerts_repository.g.dart';

@Riverpod(keepAlive: true)
AlertsRepository alertsRepository(Ref ref) =>
    AlertsRepository(ref.watch(dioProvider));

/// `/api/alerts` (server/src/routes/alert.routes.js). Staff only.
class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  /// Newest first.
  Future<List<Alert>> getAlerts() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/alerts');
        return jsonList(res.data, 'alerts').map(Alert.fromJson).toList();
      });

  /// Only ACTIVE alerts can be acknowledged.
  Future<void> acknowledge(String id) =>
      apiCall(() => _dio.put<void>('/alerts/$id/ack'));

  Future<void> resolve(String id) =>
      apiCall(() => _dio.put<void>('/alerts/$id/resolve'));
}
