import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/auth/data/auth_repository_impl.dart';
import 'package:municipality/features/auth/domain/auth_repository.dart';
import 'package:municipality/features/auth/domain/profile_update.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/export/data/dossier_pdf.dart';
import 'package:municipality/features/export/domain/dossier.dart';
import 'package:municipality/features/profile/presentation/profile_screen.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:pdf/widgets.dart' as pw;

const _me = User(
  id: 'u1',
  name: 'Samer',
  email: 'samer@tripoli.lb',
  district: 'Al-Mina',
  role: UserRole.healthOfficer,
  badgeNumber: 'TRP-OFF-7',
);

class FakeAuthRepository implements AuthRepository {
  final updates = <ProfileUpdate>[];

  @override
  Future<User?> getCachedUser() async => _me;

  @override
  Future<User> fetchCurrentUser() async => _me;

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async => _me;

  @override
  Future<User> register(RegisterRequest request) async => _me;

  @override
  Future<User> updateProfile(ProfileUpdate update) async {
    updates.add(update);
    return _me.copyWith(name: update.name, district: update.district);
  }

  @override
  Future<void> signOut() async {}
}

Report _report(String id, RiskLevel level) => Report(
  id: id,
  reportNumber: 'TRP-$id',
  title: 'Incident $id',
  riskLevel: level,
  riskScore: level == RiskLevel.critical ? 88 : 30,
);

void main() {
  // The app gets this from GlobalMaterialLocalizations.
  setUpAll(() => initializeDateFormatting('en'));

  test('dossier lists at most 8 critical reports, in order', () {
    final data = buildDossierData(
      stats: const DashboardStats(),
      reports: [
        _report('low', RiskLevel.low),
        for (var i = 0; i < 10; i++) _report('$i', RiskLevel.critical),
      ],
      clusters: const [],
    );
    expect(data.criticalReports.map((r) => r.id), [
      for (var i = 0; i < 8; i++) '$i',
    ]);
  });

  test('dossier number is unique per minute', () {
    expect(
      dossierNumber(DateTime(2026, 3, 7, 9, 5)),
      'DOC-TRP-EPI-20260307-0905',
    );
  });

  test('dossier PDF renders every section across pages', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final bytes = await buildDossierPdf(
      data: buildDossierData(
        stats: const DashboardStats(
          totalReports: 40,
          criticalCount: 9,
          resolvedCount: 12,
          resolutionRate: 30,
        ),
        reports: [
          for (var i = 0; i < 9; i++) _report('$i', RiskLevel.critical),
        ],
        clusters: [
          for (var i = 0; i < 30; i++)
            Cluster(id: '$i', clusterCode: 'CLS-$i', district: 'Al-Tal'),
        ],
      ),
      l10n: l10n,
      preparedBy: _me,
      generatedAt: DateTime(2026, 3, 7),
      font: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
    // A valid PDF file.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('profile update body', () {
    const update = ProfileUpdate(
      name: 'Samer',
      district: 'Al-Tal',
      avatarUrl: 'https://x.lb/a.png',
    );
    expect(update.toJson(), {
      'name': 'Samer',
      'phone': '',
      'district': 'Al-Tal',
      'title': '',
      'bio': '',
      'avatarUrl': 'https://x.lb/a.png',
    });
  });

  test('profile is open to every role', () {
    expect(AppRoutes.canAccess(AppRoutes.profile, UserRole.citizen), isTrue);
  });

  testWidgets('profile form saves and updates the session', (tester) async {
    final repo = FakeAuthRepository();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    await container.read(authControllerProvider.future);
    router.push('/profile');
    await tester.pumpAndSettle();

    expect(find.text('samer@tripoli.lb'), findsOneWidget);
    expect(find.text('ID: u1 • TRP-OFF-7'), findsOneWidget);

    final name = find.widgetWithText(TextFormField, 'Full Name *');
    await tester.enterText(name, '  ');
    await tester.ensureVisible(find.text('Save Profile'));
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Please provide full name.'), findsOneWidget);
    expect(repo.updates, isEmpty);

    await tester.enterText(name, 'Samer Karami');
    await tester.ensureVisible(find.text('Save Profile'));
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(repo.updates.single.name, 'Samer Karami');
    expect(repo.updates.single.district, 'Al-Mina');
    expect(find.text('Profile updated successfully!'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing); // popped
    final state = container.read(authControllerProvider).value;
    expect(state.toString(), contains('Samer Karami'));
  });
}
