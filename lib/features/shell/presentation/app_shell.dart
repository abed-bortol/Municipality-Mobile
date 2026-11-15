import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/l10n/app_strings.dart';
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
    final s = AppStrings.of(context);
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
          for (final tab in tabs) _destination(tab, role, s),
        ],
      ),
    );
  }

  NavigationDestination _destination(ShellTab tab, UserRole role, AppStrings s) {
    final (icon, selectedIcon, label) = switch (tab) {
      ShellTab.dashboard => (
          Icons.dashboard_outlined,
          Icons.dashboard,
          s.navHome,
        ),
      ShellTab.reports => (
          Icons.description_outlined,
          Icons.description,
          role == UserRole.citizen ? s.navMyReports : s.navReports,
        ),
      ShellTab.map => (Icons.map_outlined, Icons.map, s.navMap),
      ShellTab.alerts => (
          Icons.notifications_active_outlined,
          Icons.notifications_active,
          s.navAlerts,
        ),
      ShellTab.notices => (Icons.campaign_outlined, Icons.campaign, s.navNotices),
      ShellTab.more => role == UserRole.citizen
          ? (Icons.person_outline, Icons.person, s.navAccount)
          : (Icons.menu, Icons.menu_open, s.navMore),
    };

    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }
}
