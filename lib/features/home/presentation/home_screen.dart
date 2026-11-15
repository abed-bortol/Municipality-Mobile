import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/brand_logo.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/home/presentation/widgets/profile_card.dart';

/// Temporary landing screen after sign-in. It will be replaced by the
/// role-based dashboards (citizen / officer / admin) as they are ported.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        // Same brand block as the website Navbar: logo tile + title + country chip.
        title: Row(
          children: [
            const BrandLogo(size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                s.appTitle,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF042F2E), // teal-950
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xCC115E59)), // teal-800/80
              ),
              child: Text(
                s.isAr ? s.country : s.country.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.teal300,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.signOut,
            icon: const Icon(Icons.logout, color: AppColors.rose400),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [ProfileCard(user: user)],
            ),
    );
  }
}
