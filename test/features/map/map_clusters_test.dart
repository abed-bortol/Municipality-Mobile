import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/clusters/data/clusters_repository.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/clusters/presentation/clusters_providers.dart';
import 'package:municipality/features/clusters/presentation/screens/clusters_screen.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/map/domain/district_areas.dart';
import 'package:municipality/features/map/domain/map_filter.dart';
import 'package:municipality/features/map/presentation/screens/location_picker_screen.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

class FakeClustersRepository implements ClustersRepository {
  FakeClustersRepository(this.clusters);

  List<Cluster> clusters;
  final calls = <String>[];

  @override
  Future<List<Cluster>> getClusters() async {
    calls.add('get');
    return clusters;
  }

  @override
  Future<List<Cluster>> detect() async {
    calls.add('detect');
    return clusters;
  }

  @override
  Future<Cluster> updateStatus(String id, ClusterStatus status) async {
    calls.add('status:$id:${status.apiValue}');
    return clusters.firstWhere((c) => c.id == id).copyWith(status: status);
  }
}

Report _report(
  String id, {
  RiskLevel risk = RiskLevel.low,
  ReportStatus status = ReportStatus.submitted,
  String category = 'Food Safety',
  String district = 'Al-Mina',
  double lat = 34.45,
  int affected = 1,
}) => Report(
  id: id,
  reportNumber: 'TRP-$id',
  riskLevel: risk,
  status: status,
  category: ReportCategory(name: category),
  affectedCount: affected,
  location: ReportLocation(district: district, lat: lat, lng: 35.82),
);

const _cluster = Cluster(
  id: 'c1',
  clusterCode: 'CLU-2026-001',
  categoryName: 'Food Safety',
  district: 'Al-Mina',
  lat: 34.45,
  lng: 35.82,
  radiusMeters: 800,
  reportNumbers: ['TRP-1', 'TRP-2'],
  reportCount: 2,
  totalAffected: 9,
  riskLevel: RiskLevel.high,
);

void main() {
  group('estimateDistrict', () {
    test('picks the nearest district centre', () {
      expect(estimateDistrict(34.4518, 35.8198), 'Al-Mina');
      expect(estimateDistrict(34.4440, 35.8505), 'Bab Al-Tabbaneh');
      expect(estimateDistrict(34.4300, 35.8330), 'Dam w Farez');
    });

    test('far points use the website fallbacks', () {
      expect(estimateDistrict(34.55, 35.90), 'Beddawi');
      expect(estimateDistrict(34.44, 35.70), 'Al-Mina');
      expect(estimateDistrict(34.30, 35.85), 'Abu Samra');
    });

    test('every outlined district is a known district', () {
      for (final area in districtAreas.values) {
        expect(area.outline.length, greaterThanOrEqualTo(4));
      }
      expect(
        districtAreas.keys,
        everyElement(
          isIn(const [
            'Al-Mina',
            'Al-Tal',
            'Bab Al-Tabbaneh',
            'Jabal Mohsen',
            'Abu Samra',
            'Al-Qobbeh',
            'Dam w Farez',
            'Beddawi',
            'Zahrieh',
          ]),
        ),
      );
    });
  });

  test('coordinates are rounded to 5 decimals', () {
    expect(roundCoordinate(34.4367123456), 34.43671);
  });

  group('MapFilter', () {
    final reports = [
      _report('1', risk: RiskLevel.critical),
      _report('2', status: ReportStatus.resolved),
      _report('3', category: 'Air Pollution'),
      _report('4', lat: 0), // no coordinates
    ];

    test('hides reports without coordinates', () {
      expect(const MapFilter().apply(reports).map((r) => r.id), [
        '1',
        '2',
        '3',
      ]);
    });

    test('combines risk, status and category', () {
      expect(
        const MapFilter(
          riskLevel: RiskLevel.critical,
        ).apply(reports).map((r) => r.id),
        ['1'],
      );
      expect(
        const MapFilter(status: ReportStatus.resolved).apply(reports).single.id,
        '2',
      );
      const both = MapFilter(
        category: 'Air Pollution',
        riskLevel: RiskLevel.low,
      );
      expect(both.apply(reports).single.id, '3');
      expect(both.activeCount, 2);
    });
  });

  test('district profile counts reports, risk, affected and alerts', () {
    final profile = districtProfile(
      'Al-Mina',
      [
        _report('1', risk: RiskLevel.critical, affected: 4),
        _report(
          '2',
          risk: RiskLevel.high,
          affected: 2,
          category: 'Air Pollution',
        ),
        _report('3', affected: 1),
        _report('4', district: 'Al-Tal', affected: 50),
      ],
      const [
        Alert(id: 'a1', area: 'al-mina'),
        Alert(id: 'a2', area: 'Al-Mina', status: AlertStatus.resolved),
        Alert(id: 'a3', area: 'Al-Tal'),
      ],
    );
    expect(profile.reports, 3);
    expect(profile.criticalOrHigh, 2);
    expect(profile.affected, 7);
    expect(profile.activeAlerts, 1);
    expect(profile.topCategories, [('Food Safety', 2), ('Air Pollution', 1)]);
  });

  test('map and cluster monitor are staff only', () {
    for (final path in [AppRoutes.map, AppRoutes.clusters]) {
      expect(AppRoutes.canAccess(path, UserRole.citizen), isFalse);
      expect(AppRoutes.canAccess(path, UserRole.healthOfficer), isTrue);
    }
  });

  test('cluster status change refreshes the cluster list', () async {
    final repo = FakeClustersRepository([_cluster]);
    final container = ProviderContainer(
      overrides: [clustersRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(activeClustersProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(activeClustersProvider.future);
    await container
        .read(clusterActionsProvider.notifier)
        .updateStatus(_cluster, ClusterStatus.contained);
    await container.read(activeClustersProvider.future);
    expect(repo.calls, ['get', 'status:c1:CONTAINED', 'get']);
  });

  testWidgets('cluster monitor scans and lists clusters', (tester) async {
    final repo = FakeClustersRepository([_cluster]);
    final reports = [_report('1'), _report('2')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clustersRepositoryProvider.overrideWithValue(repo),
          reportsProvider.overrideWith(
            (_) async => ReportsPage(
              reports: reports,
              total: reports.length,
              page: 1,
              totalPages: 1,
            ),
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ClustersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CLU-2026-001'), findsOneWidget);
    expect(find.text('#TRP-1'), findsOneWidget);
    expect(
      find.text('Radius ~800m · 2 Incidents · ~9 citizens'),
      findsOneWidget,
    );

    await tester.tap(find.text('Run Live Cluster Scan'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('detect'));
    expect(
      find.text(
        'Cluster scan complete! 1 active public health clusters '
        'monitored across Tripoli.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cluster monitor shows the empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clustersRepositoryProvider.overrideWithValue(
            FakeClustersRepository(const []),
          ),
          reportsProvider.overrideWith(
            (_) async => const ReportsPage(
              reports: [],
              total: 0,
              page: 1,
              totalPages: 1,
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ClustersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No active clusters detected'), findsOneWidget);
  });
}
