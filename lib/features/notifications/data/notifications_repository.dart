import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/notifications/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_repository.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(dioProvider));

/// `/api/notifications` (server/src/routes/notification.routes.js).
class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  /// The signed-in user's notifications, newest first.
  Future<List<AppNotification>> getMine() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/notifications');
        return jsonList(res.data, 'notifications')
            .map(AppNotification.fromJson)
            .toList();
      });

  Future<void> markAsRead(String id) =>
      apiCall(() => _dio.put<void>('/notifications/$id/read'));

  Future<void> markAllAsRead() =>
      apiCall(() => _dio.put<void>('/notifications/read-all'));
}
