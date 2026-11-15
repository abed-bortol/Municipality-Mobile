import 'package:municipality/features/auth/domain/user.dart';

/// Tabs of the main shell, in `StatefulShellRoute` branch order.
/// Which ones a user sees depends on the role (see [ShellTab.forRole]).
enum ShellTab {
  dashboard(AppRoutes.dashboard),
  reports(AppRoutes.reports),
  map(AppRoutes.map),
  alerts(AppRoutes.alerts),
  notices(AppRoutes.notices),
  more(AppRoutes.more);

  const ShellTab(this.path);

  final String path;

  /// Bottom bar per role, mirroring the website Sidebar (3-5 tabs; the rest
  /// of the sidebar lives under "More").
  static List<ShellTab> forRole(UserRole role) => switch (role) {
        UserRole.citizen => const [dashboard, reports, notices, more],
        UserRole.healthOfficer ||
        UserRole.administrator =>
          const [dashboard, reports, map, alerts, more],
      };
}

abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const notifications = '/notifications';

  // Shell tabs
  static const dashboard = '/dashboard';
  static const reports = '/reports';
  static const map = '/map';
  static const alerts = '/alerts';
  static const notices = '/notices';
  static const more = '/more';

  // Under "Reports"
  static const newReport = '/reports/new';
  static String reportDetails(String id) => '/reports/$id';
  static String reportInvestigation(String id) =>
      '/reports/$id/investigation';

  // Under "More"
  static const profile = '/more/profile';
  static const investigations = '/more/investigations';
  static const clusters = '/more/clusters';
  static const analytics = '/more/analytics';
  static const exportDossier = '/more/export';
  static const users = '/more/users';
  static const categories = '/more/categories';
  static const systemSettings = '/more/settings';
  static const auditLogs = '/more/audit';

  static const _staffOnly = [
    map,
    alerts,
    investigations,
    clusters,
    analytics,
    exportDossier,
  ];
  static const _adminOnly = [users, categories, systemSettings, auditLogs];

  /// Same role permissions as the website Sidebar; the server enforces
  /// them too, this only keeps users out of screens they can't use.
  static bool canAccess(String location, UserRole role) {
    bool under(String route) =>
        location == route || location.startsWith('$route/');

    if (_adminOnly.any(under)) return role == UserRole.administrator;
    if (_staffOnly.any(under) || _investigationForm.hasMatch(location)) {
      return role != UserRole.citizen;
    }
    return true;
  }

  /// `/reports/:id/investigation` (the report itself is open to citizens).
  static final _investigationForm =
      RegExp(r'^/reports/[^/]+/investigation$');
}
