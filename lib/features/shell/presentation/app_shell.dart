import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';

/// Main scaffold after sign-in: bottom navigation with role-based tabs
/// (the website's Sidebar). Each tab keeps its own navigation stack.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.role,
      _ => UserRole.citizen,
    };
    final tabs = ShellTab.forRole(role);
    final current = ShellTab.values[navigationShell.currentIndex];
    final selected = tabs.indexOf(current);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) {
          final tab = tabs[i];
          navigationShell.goBranch(
            tab.index,
            // Tapping the active tab again pops back to its root.
            initialLocation: tab == current,
          );
        },
        destinations: [
          for (final tab in tabs) _destination(tab, role, l10n),
        ],
      ),
    );
  }

  NavigationDestination _destination(ShellTab tab, UserRole role, AppLocalizations l10n) {
    final (icon, selectedIcon, label) = switch (tab) {
      ShellTab.dashboard => (
          Icons.dashboard_outlined,
          Icons.dashboard,
          l10n.navHome,
        ),
      ShellTab.reports => (
          Icons.description_outlined,
          Icons.description,
          role == UserRole.citizen ? l10n.navMyReports : l10n.navReports,
        ),
      ShellTab.map => (Icons.map_outlined, Icons.map, l10n.navMap),
      ShellTab.alerts => (
          Icons.notifications_active_outlined,
          Icons.notifications_active,
          l10n.navAlerts,
        ),
      ShellTab.notices => (Icons.campaign_outlined, Icons.campaign, l10n.navNotices),
      ShellTab.more => role == UserRole.citizen
          ? (Icons.person_outline, Icons.person, l10n.navAccount)
          : (Icons.menu, Icons.menu_open, l10n.navMore),
    };

    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }
}
