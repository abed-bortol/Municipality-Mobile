import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/features/auth/domain/user.dart';

void main() {
  group('AppRoutes.canAccess (website Sidebar permissions)', () {
    test('citizens are kept out of staff and admin screens', () {
      for (final route in [
        AppRoutes.map,
        AppRoutes.alerts,
        AppRoutes.investigations,
        AppRoutes.users,
      ]) {
        expect(AppRoutes.canAccess(route, UserRole.citizen), isFalse,
            reason: route);
      }
      expect(AppRoutes.canAccess(AppRoutes.reports, UserRole.citizen), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.notices, UserRole.citizen), isTrue);
    });

    test('officers get operations but not administration', () {
      const role = UserRole.healthOfficer;
      expect(AppRoutes.canAccess(AppRoutes.map, role), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.investigations, role), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.auditLogs, role), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.categories, role), isFalse);
    });

    test('administrators can open everything, including nested paths', () {
      expect(AppRoutes.canAccess(AppRoutes.users, UserRole.administrator),
          isTrue);
      expect(
          AppRoutes.canAccess(
              '${AppRoutes.alerts}/abc', UserRole.administrator),
          isTrue);
    });
  });

  test('bottom bar tabs per role', () {
    expect(ShellTab.forRole(UserRole.citizen), [
      ShellTab.dashboard,
      ShellTab.reports,
      ShellTab.notices,
      ShellTab.more,
    ]);
    expect(ShellTab.forRole(UserRole.healthOfficer), hasLength(5));
  });
}
