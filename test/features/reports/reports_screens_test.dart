import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/categories/data/categories_repository.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/presentation/screens/new_report_screen.dart';
import 'package:municipality/features/reports/presentation/screens/reports_screen.dart';
import 'package:municipality/l10n/l10n.dart';

class _SignedIn extends AuthController {
  _SignedIn(this.user);

  final User user;

  @override
  Future<AuthState> build() async => AuthState.authenticated(user);
}

Widget _app(Widget home, {required UserRole role, List<Report> reports = const []}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
            () => _SignedIn(User(id: 'u1', name: 'Samer', role: role))),
        reportsProvider.overrideWith((_) async => ReportsPage(
              reports: reports,
              total: reports.length,
              page: 1,
              totalPages: 1,
            )),
        activeCategoriesProvider.overrideWith((_) async => const [
              HazardCategory(id: 'c1', name: 'Water Contamination', code: 'WAT'),
            ]),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    );

/// The form's ListView (text fields have scrollables of their own).
final _formScroll = find.byType(Scrollable).first;

void main() {
  final reports = [
    const Report(
      id: '1',
      reportNumber: 'TRP-1',
      title: 'Brown tap water',
      riskScore: 30,
      location: ReportLocation(district: 'Al-Mina'),
    ),
    const Report(
      id: '2',
      reportNumber: 'TRP-2',
      title: 'Garbage pile',
      riskScore: 80,
      riskLevel: RiskLevel.critical,
      location: ReportLocation(district: 'Al-Tal'),
    ),
  ];

  testWidgets('staff list sorts by risk and filters by search', (tester) async {
    await tester.pumpWidget(_app(const ReportsScreen(),
        role: UserRole.healthOfficer, reports: reports));
    await tester.pumpAndSettle();

    expect(find.text('Report Triage & Review'), findsOneWidget);
    expect(find.text('Showing 2 of 2 incidents'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('TRP-2')).dy,
      lessThan(tester.getTopLeft(find.text('TRP-1')).dy),
    );

    await tester.enterText(find.byType(TextField), 'brown');
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 of 2 incidents'), findsOneWidget);
    expect(find.text('TRP-2'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No matching public health reports found.'),
        findsOneWidget);
  });

  testWidgets('submission form validates required fields', (tester) async {
    await tester.pumpWidget(_app(const NewReportScreen(), role: UserRole.citizen));
    await tester.pumpAndSettle();

    // Live estimate is shown before anything is typed.
    await tester.scrollUntilVisible(
        find.text('Real-Time Intelligent Risk Engine Calculation'), 300,
        scrollable: _formScroll);
    expect(find.text('Real-Time Intelligent Risk Engine Calculation'),
        findsOneWidget);

    await tester.scrollUntilVisible(find.text('Submit Report'), 300,
        scrollable: _formScroll);
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    // Back to the top, where the first invalid fields are.
    await tester.fling(_formScroll, const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    expect(find.text('Please provide an incident title.'), findsOneWidget);
    expect(
        find.text(
            'Please provide a detailed description (minimum 15 characters).',
            skipOffstage: false),
        findsOneWidget);
  });
}
