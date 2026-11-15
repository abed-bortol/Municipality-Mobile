import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/audit/domain/audit_log.dart';
import 'package:municipality/features/audit/presentation/audit_logs_screen.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/categories/data/categories_repository.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:municipality/features/categories/presentation/categories_admin_providers.dart';
import 'package:municipality/features/categories/presentation/screens/categories_screen.dart';
import 'package:municipality/features/users/data/users_repository.dart';
import 'package:municipality/features/users/presentation/users_admin_providers.dart';
import 'package:municipality/l10n/l10n.dart';

class FakeUsersRepository extends UsersRepository {
  FakeUsersRepository() : super(Dio());

  final calls = <String>[];

  @override
  Future<List<User>> getUsers() async {
    calls.add('get');
    return const [];
  }

  @override
  Future<User> updateRole(
    String id,
    UserRole role, {
    String badgeNumber = '',
    String title = '',
  }) async {
    calls.add('role:$id:${role.apiValue}:$badgeNumber:$title');
    return User(id: id, role: role);
  }
}

class FakeCategoriesRepository extends CategoriesRepository {
  FakeCategoriesRepository(this.stored) : super(Dio());

  List<HazardCategory> stored;
  final calls = <String>[];

  @override
  Future<List<HazardCategory>> getCategories({
    bool includeInactive = false,
  }) async {
    calls.add('get:$includeInactive');
    return stored;
  }

  @override
  Future<HazardCategory> createCategory({
    required String name,
    required double baseWeight,
    String? description,
    String? icon,
  }) async {
    calls.add('create:$name:${baseWeight.round()}');
    return HazardCategory(id: 'new', name: name, baseWeight: baseWeight);
  }

  @override
  Future<HazardCategory> updateCategory(
    String id, {
    double? baseWeight,
    String? description,
    String? icon,
    bool? isActive,
  }) async {
    calls.add('update:$id:${baseWeight?.round()}:$isActive');
    final c = stored.firstWhere((c) => c.id == id);
    return c.copyWith(
      baseWeight: baseWeight ?? c.baseWeight,
      isActive: isActive ?? c.isActive,
    );
  }
}

Widget _app(List<Override> overrides, Widget home) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  ),
);

void main() {
  test('admin screens are administrators only', () {
    for (final path in [
      AppRoutes.users,
      AppRoutes.categories,
      AppRoutes.systemSettings,
      AppRoutes.auditLogs,
    ]) {
      expect(AppRoutes.canAccess(path, UserRole.healthOfficer), isFalse);
      expect(AppRoutes.canAccess(path, UserRole.administrator), isTrue);
    }
  });

  test('users filter by role and name, email or translated district', () {
    const users = [
      User(id: '1', name: 'Samer', email: 's@x.lb', district: 'Al-Mina'),
      User(
        id: '2',
        name: 'Lina',
        email: 'lina@x.lb',
        role: UserRole.healthOfficer,
      ),
    ];
    expect(filterUsers(users, role: UserRole.healthOfficer).single.id, '2');
    expect(filterUsers(users, query: 'LINA@').single.id, '2');
    expect(
      filterUsers(
        users,
        query: 'port',
        districtLabel: (d) => d == 'Al-Mina' ? 'Mina Port area' : d,
      ).single.id,
      '1',
    );
  });

  test('demoting to citizen drops the badge and title', () async {
    final repo = FakeUsersRepository();
    final container = ProviderContainer(
      overrides: [usersRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final actions = container.read(userAdminActionsProvider.notifier);

    await actions.updateRole(
      const User(id: 'u1'),
      UserRole.citizen,
      badgeNumber: 'TRP-OFF-1',
      title: 'Inspector',
    );
    await actions.updateRole(
      const User(id: 'u1'),
      UserRole.healthOfficer,
      badgeNumber: ' TRP-OFF-2 ',
    );
    expect(repo.calls, [
      'role:u1:CITIZEN::',
      'role:u1:HEALTH_OFFICER:TRP-OFF-2:',
    ]);
  });

  test('weight tiers match the website', () {
    expect(WeightTier.of(14), WeightTier.high);
    expect(WeightTier.of(10), WeightTier.standard);
    expect(WeightTier.of(9), WeightTier.normal);
  });

  test('audit search covers user, action label, resource and details', () {
    const logs = [
      AuditLog(id: '1', userName: 'Rana', action: 'USER_LOGIN'),
      AuditLog(
        id: '2',
        action: 'UPDATE_REPORT_STATUS',
        resource: 'Report #TRP-9',
        details: 'SUBMITTED -> VERIFIED',
      ),
    ];
    expect(filterAuditLogs(logs, '').length, 2);
    expect(filterAuditLogs(logs, 'rana').single.id, '1');
    expect(filterAuditLogs(logs, 'trp-9').single.id, '2');
    expect(
      filterAuditLogs(
        logs,
        'transition',
        actionLabel: (a) =>
            a == 'UPDATE_REPORT_STATUS' ? 'Status Transition' : a,
      ).single.id,
      '2',
    );
  });

  test('AuditLog.fromJson reads the server document', () {
    final log = AuditLog.fromJson({
      '_id': 'a1',
      'userName': 'Admin',
      'userRole': 'ADMINISTRATOR',
      'action': 'CREATE_USER',
      'resource': 'User x@y.lb',
      'ipAddress': '10.0.0.1',
      'createdAt': '2026-05-01T10:00:00.000Z',
    });
    expect(log.id, 'a1');
    expect(log.action, 'CREATE_USER');
    expect(log.createdAt, DateTime.utc(2026, 5, 1, 10));
  });

  testWidgets('categories: add validates, weight steps and toggles', (
    tester,
  ) async {
    // Tall enough to show the form and the category card together.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeCategoriesRepository(const [
      HazardCategory(
        id: 'c1',
        name: 'Food Safety',
        code: 'FOOD_SAFETY',
        baseWeight: 10,
      ),
    ]);
    await tester.pumpWidget(
      _app([
        categoriesRepositoryProvider.overrideWithValue(repo),
      ], const CategoriesScreen()),
    );
    await tester.pumpAndSettle();

    expect(repo.calls, ['get:true']);
    expect(find.text('Standard Tier'), findsOneWidget);
    expect(find.text('10 pts'), findsOneWidget);

    await tester.tap(find.text('Add Category'));
    await tester.pumpAndSettle();
    expect(find.text('Category name is required.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category Name *'),
      'Radiation',
    );
    await tester.tap(find.text('Add Category'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('create:Radiation:10'));
    expect(
      find.text('New category "Radiation" added to database!'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byTooltip('Increase weight'));
    await tester.tap(find.byTooltip('Increase weight'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('update:c1:11:null'));

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('update:c1:null:false'));
  });
}
