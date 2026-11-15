import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/brand_app_bar.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';

/// Role-based dashboard (citizen / authority / admin). Content arrives in
/// the dashboards phase; for now it greets the user with the right title.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };
    final title = switch (user?.role) {
      UserRole.administrator => l10n.adminDashboard,
      UserRole.healthOfficer => l10n.authorityDashboard,
      _ => l10n.citizenDashboard,
    };

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title,
              style: textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l10n.appSubtitle,
              style:
                  textTheme.bodySmall?.copyWith(color: AppColors.slate400)),
        ],
      ),
    );
  }
}
