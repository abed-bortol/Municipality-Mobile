import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/alerts/data/alerts_repository.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/dashboard/data/dashboard_repository.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/notifications/presentation/notifications_controller.dart';
import 'package:municipality/l10n/l10n.dart';

class _Officer extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
      User(id: 'o1', name: 'Dr. Lina', role: UserRole.healthOfficer));
}

class _NoNotifications extends NotificationsController {
  @override
  Future<List<Never>> build() async => const [];
}

class FakeAlertsRepository implements AlertsRepository {
  final alerts = <Alert>[
    const Alert(
      id: 'a1',
      alertCode: 'ALT-001',
      title: 'Critical water report',
      area: 'Al-Mina',
      relatedReportId: 'r1',
    ),
    const Alert(
      id: 'a2',
      alertCode: 'ALT-002',
      title: 'Cluster in Al-Tal',
      area: 'Al-Tal',
      status: AlertStatus.resolved,
    ),
  ];
  final acknowledged = <String>[];

  @override
  Future<List<Alert>> getAlerts() async => List.of(alerts);

  @override
  Future<void> acknowledge(String id) async {
    acknowledged.add(id);
    final i = alerts.indexWhere((a) => a.id == id);
    alerts[i] = alerts[i].copyWith(status: AlertStatus.acknowledged);
  }

  @override
  Future<void> resolve(String id) async {}
}

class _FakeDashboard implements DashboardRepository {
  @override
  Future<DashboardStats> getStats() async => const DashboardStats();
}

void main() {
  testWidgets('filters by status and acknowledges an alert', (tester) async {
    final repo = FakeAlertsRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Officer.new),
        notificationsControllerProvider.overrideWith(_NoNotifications.new),
        alertsRepositoryProvider.overrideWithValue(repo),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboard()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AlertsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    // In the app the session is restored before any tab is shown.
    await ProviderScope.containerOf(tester.element(find.byType(AlertsScreen)))
        .read(authControllerProvider.future);

    expect(find.text('All Alerts (2)'), findsOneWidget);
    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.text('Cluster in Al-Tal'), findsOneWidget);

    await tester.tap(find.text('Active (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Cluster in Al-Tal'), findsNothing);
    expect(find.text('Inspect'), findsOneWidget);

    await tester.tap(find.text('Acknowledge'));
    await tester.pumpAndSettle();
    expect(repo.acknowledged, ['a1']);
    expect(find.text('Alert acknowledged by Dr. Lina'), findsOneWidget);
    // Reloaded: no active alerts left.
    expect(find.text('Active (0)'), findsOneWidget);
    expect(find.text('No alerts match this filter.'), findsOneWidget);
  });
}
