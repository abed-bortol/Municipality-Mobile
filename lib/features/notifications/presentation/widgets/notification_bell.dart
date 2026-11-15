import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/notifications/presentation/notifications_controller.dart';
import 'package:municipality/l10n/l10n.dart';

/// App bar bell with the unread count (website Navbar). Watching it keeps
/// the notifications polling.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      tooltip: unread > 0
          ? '${l10n.notifications} (${l10n.unreadCount(unread)})'
          : l10n.notifications,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: AppColors.rose400,
        textColor: AppColors.slate950,
        child: Icon(
            unread > 0 ? Icons.notifications_active : Icons.notifications_none),
      ),
    );
  }
}
