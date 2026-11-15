import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/notifications/domain/app_notification.dart';
import 'package:municipality/features/notifications/presentation/notifications_controller.dart';
import 'package:municipality/l10n/l10n.dart';

/// Full list of the website Navbar's notification dropdown. Tapping an
/// unread notification marks it as read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifications = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: controller.markAllAsRead,
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: switch (notifications) {
          AsyncValue(value: final List<AppNotification> list)
              when list.isEmpty =>
            ListView(children: [
              const SizedBox(height: 80),
              EmptyState(
                icon: Icons.notifications_none,
                message: l10n.noNotifications,
              ),
            ]),
          AsyncValue(value: final List<AppNotification> list) =>
            ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationTile(
                notification: list[i],
                onTap: () => controller.markAsRead(list[i].id),
              ),
            ),
          AsyncError() => ListView(children: [
              const SizedBox(height: 80),
              LoadErrorView(
                onRetry: () => ref.invalidate(notificationsControllerProvider),
              ),
            ]),
          _ => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const Skeleton(height: 64),
            ),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static (IconData, Color) _look(NotificationType type) => switch (type) {
        NotificationType.criticalAlert => (
            Icons.warning_amber_rounded,
            AppColors.rose400,
          ),
        NotificationType.clusterAlert => (
            Icons.bubble_chart_outlined,
            const Color(0xFFFB923C),
          ),
        NotificationType.assignment => (
            Icons.assignment_ind_outlined,
            const Color(0xFF818CF8),
          ),
        NotificationType.statusUpdate => (Icons.sync_alt, AppColors.teal400),
        NotificationType.system => (Icons.info_outline, AppColors.slate400),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = _look(notification.type);
    final unread = !notification.isRead;
    final createdAt = notification.createdAt;

    return Semantics(
      label: unread ? l10n.unreadCount(1) : null,
      child: ListTile(
        onTap: onTap,
        tileColor: unread ? AppColors.teal950.withValues(alpha: 0.45) : null,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notification.message,
                style:
                    textTheme.bodySmall?.copyWith(color: AppColors.slate300)),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(context.formatDateTime(createdAt),
                  style: textTheme.labelSmall
                      ?.copyWith(color: AppColors.slate500)),
            ],
          ],
        ),
        trailing: unread
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.teal400,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
