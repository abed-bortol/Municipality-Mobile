import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/features/analytics/presentation/analytics_screen.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/l10n/l10n.dart';

Future<void> _pump(WidgetTester tester, DashboardStats stats) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dashboardStatsProvider.overrideWith((_) async => stats)],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AnalyticsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('analytics is staff only', () {
    expect(AppRoutes.canAccess(AppRoutes.analytics, UserRole.citizen), isFalse);
    expect(
      AppRoutes.canAccess(AppRoutes.analytics, UserRole.administrator),
      isTrue,
    );
  });

  testWidgets('shows rates and distributions', (tester) async {
    await _pump(
      tester,
      DashboardStats(
        totalReports: 12,
        resolutionRate: 42,
        resolvedCount: 5,
        criticalCount: 3,
        underInvestigationCount: 2,
        categoryData: [
          for (var i = 0; i < 9; i++) NamedCount(name: 'Cat $i', count: 9 - i),
        ],
        riskData: const [
          RiskCount(level: 'CRITICAL', count: 3),
          RiskCount(level: 'LOW', count: 9),
        ],
        districtData: const [DistrictCount(district: 'Al-Mina', count: 7)],
        statusData: const [StatusCount(status: 'IN_INVESTIGATION', count: 2)],
      ),
    );

    expect(find.text('42%'), findsOneWidget);
    expect(find.text('5 closed/resolved'), findsOneWidget);
    expect(find.text('Cat 6'), findsOneWidget);
    expect(find.text('Cat 7'), findsNothing); // top 7 only
    await tester.scrollUntilVisible(
      find.text('Critical: 3'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Critical: 3'), findsOneWidget);
    expect(find.text('Low: 9'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Al-Mina'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Investigation Lifecycle Status Distribution'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Metric card label plus the status bar.
    expect(find.text('In Investigation'), findsWidgets);
  });

  testWidgets('empty database shows the placeholder', (tester) async {
    await _pump(tester, const DashboardStats());
    expect(find.text('No Incident Data Recorded Yet'), findsOneWidget);
    expect(find.text('Risk Level Distribution'), findsNothing);
  });
}
