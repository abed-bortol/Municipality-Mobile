import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/widgets/brand_app_bar.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/dashboard/presentation/widgets/citizen_dashboard.dart';
import 'package:municipality/features/dashboard/presentation/widgets/staff_dashboard.dart';
import 'package:municipality/features/notifications/presentation/widgets/notification_bell.dart';

/// Role-based home tab, like the website's Dashboard route: citizens get the
/// public health portal, officers and administrators the operations view.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: const BrandAppBar(actions: [NotificationBell()]),
      body: switch (user) {
        null => const SizedBox(),
        User(role: UserRole.citizen) => CitizenDashboard(user: user),
        _ => const StaffDashboard(),
      },
    );
  }
}
