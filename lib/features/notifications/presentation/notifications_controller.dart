import 'dart:async';

import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/notifications/data/notifications_repository.dart';
import 'package:municipality/features/notifications/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_controller.g.dart';

/// The user's notifications, refreshed every minute while something (the
/// app bar bell) is listening, like the website's NotificationContext.
/// Empty when signed out.
@riverpod
class NotificationsController extends _$NotificationsController {
  static const pollInterval = Duration(seconds: 60);

  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(authControllerProvider).value is! Authenticated) {
      return const [];
    }
    final timer = Timer.periodic(pollInterval, (_) => refresh());
    ref.onDispose(timer.cancel);
    return ref.read(notificationsRepositoryProvider).getMine();
  }

  /// Background refresh: keeps the current list if it fails.
  Future<void> refresh() async {
    try {
      final latest = await ref.read(notificationsRepositoryProvider).getMine();
      if (ref.mounted) state = AsyncData(latest);
    } catch (_) {}
  }

  /// Optimistic; reloads from the server if the call fails.
  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null) return;
    if (current.any((n) => n.id == id && !n.isRead)) {
      state = AsyncData([
        for (final n in current) n.id == id ? n.copyWith(isRead: true) : n,
      ]);
      try {
        await ref.read(notificationsRepositoryProvider).markAsRead(id);
      } catch (_) {
        await refresh();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null || current.every((n) => n.isRead)) return;
    state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
    } catch (_) {
      await refresh();
    }
  }
}

@riverpod
int unreadNotificationCount(Ref ref) =>
    ref
        .watch(notificationsControllerProvider)
        .value
        ?.where((n) => !n.isRead)
        .length ??
    0;
