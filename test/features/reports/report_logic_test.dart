import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/report_workflow.dart';
import 'package:municipality/features/reports/domain/reports_filter.dart';
import 'package:municipality/features/reports/domain/risk_estimate.dart';

Report _report(
  String id, {
  String category = 'Water Contamination',
  String district = 'Al-Mina',
  ReportStatus status = ReportStatus.submitted,
  RiskLevel risk = RiskLevel.low,
  double score = 0,
  int affected = 1,
  DateTime? createdAt,
  double lat = 34.4367,
  double lng = 35.8497,
}) =>
    Report(
      id: id,
      reportNumber: 'TRP-$id',
      title: 'Report $id',
      category: ReportCategory(name: category),
      location: ReportLocation(district: district, lat: lat, lng: lng),
      status: status,
      riskLevel: risk,
      riskScore: score,
      affectedCount: affected,
      createdAt: createdAt,
    );

void main() {
  group('estimateRisk (port of riskEngine.ts)', () {
    test('adds up the five factors', () {
      final now = DateTime(2026, 11, 15, 12);
      final estimate = estimateRisk(
        categoryName: 'Water Contamination',
        severity: RiskLevel.critical,
        affectedCount: 60,
        lat: 34.4367,
        lng: 35.8497,
        incidentDate: now,
        now: now,
        // Three same-category reports nearby, one far away, one other category.
        nearby: [
          _report('1'),
          _report('2'),
          _report('3'),
          _report('4', lat: 34.6, lng: 36.0),
          _report('5', category: 'Air Pollution'),
        ],
      );

      expect(estimate.factors.severityScore, 25);
      expect(estimate.factors.affectedPeopleScore, 25);
      expect(estimate.factors.recentReportsScore, 15);
      expect(estimate.factors.categoryScore, 15);
      expect(estimate.factors.geographicClusterScore, 14);
      expect(estimate.score, 94);
      expect(estimate.level, RiskLevel.critical);
    });

    test('baseline without nearby reports', () {
      final estimate = estimateRisk(
        categoryName: 'Other',
        severity: RiskLevel.low,
        affectedCount: 1,
        lat: 34.4,
        lng: 35.8,
      );
      // 4 + 5 + 15 + 6 + 4
      expect(estimate.score, 34);
      expect(estimate.level, RiskLevel.medium);
    });

    test('score bands', () {
      expect(riskLevelForScore(25), RiskLevel.low);
      expect(riskLevelForScore(26), RiskLevel.medium);
      expect(riskLevelForScore(51), RiskLevel.high);
      expect(riskLevelForScore(76), RiskLevel.critical);
    });
  });

  group('ReportWorkflow', () {
    test('moves forward one stage at a time', () {
      expect(ReportStatus.submitted.nextStep, ReportStatus.underReview);
      expect(ReportStatus.verified.nextStep, ReportStatus.inInvestigation);
      expect(ReportStatus.resolved.nextStep, ReportStatus.closed);
      expect(ReportStatus.closed.nextStep, isNull);
      expect(ReportStatus.rejected.nextStep, isNull);
    });

    test('rejection only before resolution, no assignment when terminal', () {
      expect(ReportStatus.inInvestigation.canReject, isTrue);
      expect(ReportStatus.resolved.canReject, isFalse);
      expect(ReportStatus.resolved.canAssign, isTrue);
      expect(ReportStatus.closed.canAssign, isFalse);
      expect(ReportStatus.rejected.canAssign, isFalse);
    });
  });

  group('ReportsFilter', () {
    final reports = [
      _report('1', score: 40, affected: 3, createdAt: DateTime(2026, 11, 1)),
      _report('2',
          district: 'Al-Tal',
          risk: RiskLevel.critical,
          score: 90,
          affected: 1,
          createdAt: DateTime(2026, 11, 3)),
      _report('3',
          category: 'Air Pollution',
          status: ReportStatus.resolved,
          score: 10,
          affected: 30,
          createdAt: DateTime(2026, 11, 2)),
    ];

    List<String> ids(ReportsFilter f, {String Function(String)? label}) =>
        f.apply(reports, districtLabel: label).map((r) => r.id).toList();

    test('sorts by risk, date or affected', () {
      expect(ids(const ReportsFilter()), ['2', '1', '3']);
      expect(ids(const ReportsFilter(sort: ReportSort.date)), ['2', '3', '1']);
      expect(
          ids(const ReportsFilter(sort: ReportSort.affected)), ['3', '1', '2']);
    });

    test('combines filters', () {
      expect(ids(const ReportsFilter(district: 'Al-Mina')), ['1', '3']);
      expect(
        ids(const ReportsFilter(
            district: 'Al-Mina', category: 'Water Contamination')),
        ['1'],
      );
      expect(ids(const ReportsFilter(riskLevel: RiskLevel.critical)), ['2']);
      expect(ids(const ReportsFilter(status: ReportStatus.resolved)), ['3']);
      expect(
        const ReportsFilter(district: 'Al-Tal', status: ReportStatus.closed)
            .activeCount,
        2,
      );
    });

    test('searches number, title and translated district', () {
      expect(ids(const ReportsFilter(search: 'trp-3')), ['3']);
      expect(
        ids(const ReportsFilter(search: 'التل'),
            label: (d) => d == 'Al-Tal' ? 'التل' : d),
        ['2'],
      );
    });
  });
}
