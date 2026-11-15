import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/more/presentation/widgets/profile_card.dart';
import 'package:municipality/features/settings/presentation/locale_controller.dart';

/// "More" tab for staff / "Account" tab for citizens: profile, the sidebar
/// sections that don't fit in the bottom bar, preferences and sign-out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };
    if (user == null) return const SizedBox.shrink();

    final isStaff = user.role != UserRole.citizen;
    final isAdmin = user.role == UserRole.administrator;

    return Scaffold(
      appBar: AppBar(title: Text(isStaff ? s.navMore : s.account)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ProfileCard(user: user),
          ),
          if (isStaff) ...[
            _SectionHeader(s.operations),
            _NavTile(Icons.biotech_outlined, s.investigations,
                AppRoutes.investigations),
            _NavTile(Icons.hub_outlined, s.clusterDetection, AppRoutes.clusters),
            _NavTile(Icons.bar_chart_outlined, s.epidemiologyCharts,
                AppRoutes.analytics),
            _NavTile(Icons.picture_as_pdf_outlined, s.exportDossier,
                AppRoutes.exportDossier),
          ],
          if (isAdmin) ...[
            _SectionHeader(s.administration),
            _NavTile(Icons.group_outlined, s.usersOfficers, AppRoutes.users),
            _NavTile(Icons.category_outlined, s.reportCategories,
                AppRoutes.categories),
            _NavTile(Icons.tune_outlined, s.systemSettings,
                AppRoutes.systemSettings),
            _NavTile(Icons.history_outlined, s.auditTrail, AppRoutes.auditLogs),
          ],
          _SectionHeader(s.preferences),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.language),
            trailing: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'ar', label: Text('ع')),
              ],
              selected: {s.languageCode},
              onSelectionChanged: (v) => ref
                  .read(localeControllerProvider.notifier)
                  .setLanguage(v.first),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.rose400),
            title: Text(s.signOut,
                style: const TextStyle(color: AppColors.rose400)),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final s = AppStrings.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: Text(s.signOutConfirmTitle),
        content: Text(s.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rose400),
            child: Text(s.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).signOut();
    showAppSnackBar(s.signedOut);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile(this.icon, this.title, this.route);

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
      onTap: () => context.go(route),
    );
  }
}
