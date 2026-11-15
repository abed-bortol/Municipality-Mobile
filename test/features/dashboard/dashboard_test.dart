import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/dashboard/presentation/widgets/citizen_dashboard.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:municipality/l10n/l10n.dart';

Report _report(
  String id,
  ReportStatus status, {
  RiskLevel risk = RiskLevel.low,
  double score = 0,
}) =>
    Report(
      id: id,
      reportNumber: 'TRP-$id',
      title: 'Report $id',
      status: status,
      riskLevel: risk,
      riskScore: score,
    );

void main() {
  group('priorityTriageQueue', () {
    test('keeps new or critical open reports, highest score first', () {
      final queue = priorityTriageQueue([
        _report('a', ReportStatus.submitted, score: 20),
        _report('b', ReportStatus.underReview, score: 60),
        _report('c', ReportStatus.inInvestigation,
            risk: RiskLevel.critical, score: 90),
        _report('d', ReportStatus.inInvestigation, score: 99),
        _report('e', ReportStatus.resolved,
            risk: RiskLevel.critical, score: 95),
      ]);

      expect(queue.map((r) => r.id), ['c', 'b', 'a']);
    });

    test('takes at most five', () {
      final queue = priorityTriageQueue([
        for (var i = 0; i < 8; i++) _report('$i', ReportStatus.submitted),
      ]);
      expect(queue, hasLength(5));
    });
  });

  testWidgets('citizen dashboard shows counters and recent reports',
      (tester) async {
    final reports = [
      _report('1', ReportStatus.submitted),
      _report('2', ReportStatus.inInvestigation),
      _report('3', ReportStatus.verified),
      _report('4', ReportStatus.resolved),
      _report('5', ReportStatus.closed),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardReportsProvider.overrideWith((_) async => ReportsPage(
              reports: reports,
              total: reports.length,
              page: 1,
              totalPages: 1,
            )),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: CitizenDashboard(user: User(id: 'u1', name: 'Samer')),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Samer'), findsOneWidget);
    expect(find.text('Track My Submissions (5)'), findsOneWidget);
    // Under inspection (in investigation + verified) and resolved (+ closed).
    expect(find.text('2'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('TRP-4'), 200);
    expect(find.text('TRP-4'), findsOneWidget);
    expect(find.text('TRP-5'), findsNothing); // only the latest four
  });
}
