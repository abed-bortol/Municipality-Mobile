import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/new_report_request.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';

void main() {
  group('Report.fromJson', () {
    test('normalizes a server document like toReport() on the web', () {
      final report = Report.fromJson({
        '_id': 'r1',
        'reportNumber': 'TRP-2026-0001',
        'citizen': {
          'userId': {'_id': 'u1', 'name': 'Samer'},
          'name': 'Samer',
        },
        'category': {'name': 'Water Contamination', 'code': 'WAT'},
        'title': 'Brown tap water',
        'location': {'district': 'Al-Mina', 'lat': '34.45', 'lng': 35.81},
        'affectedCount': 12,
        'initialSeverity': 'HIGH',
        'status': 'IN_INVESTIGATION',
        'assignedOfficer': {
          'officerId': 'o1',
          'name': 'Dr. Lina',
          'badgeNumber': 'HO-7',
        },
        'riskScore': 81.5,
        'riskLevel': 'CRITICAL',
        'riskFactors': {
          'severityScore': 30,
          'explanations': ['High priority category'],
        },
        'statusHistory': [
          {
            'oldStatus': 'SUBMITTED',
            'newStatus': 'UNDER_REVIEW',
            'changedBy': {'_id': 'o1', 'name': 'Dr. Lina', 'role': 'HEALTH_OFFICER'},
            'timestamp': '2026-11-01T10:00:00.000Z',
          },
        ],
        'createdAt': '2026-11-01T09:00:00.000Z',
      });

      expect(report.id, 'r1');
      expect(report.citizen.userId, 'u1');
      expect(report.location.lat, 34.45);
      expect(report.status, ReportStatus.inInvestigation);
      expect(report.riskLevel, RiskLevel.critical);
      expect(report.assignedOfficer?.id, 'o1');
      expect(report.riskFactors.severityScore, 30);
      expect(report.statusHistory.single.changedBy, 'Dr. Lina');
      expect(report.statusHistory.single.role, 'HEALTH_OFFICER');
    });

    test('empty officer sub-document means unassigned', () {
      final report = Report.fromJson({
        '_id': 'r2',
        'assignedOfficer': {'name': ''},
      });
      expect(report.assignedOfficer, isNull);
      expect(report.status, ReportStatus.submitted);
      expect(report.location.district, 'Tripoli');
    });
  });

  test('ReportsQuery only sends set filters', () {
    const query = ReportsQuery(
      status: ReportStatus.underReview,
      riskLevel: RiskLevel.high,
    );
    expect(query.toQueryParameters(), {
      'status': 'UNDER_REVIEW',
      'riskLevel': 'HIGH',
    });
    expect(const ReportsQuery().hasFilters, isFalse);
  });

  test('NewReportRequest serializes nested objects', () {
    final json = const NewReportRequest(
      category: ReportCategory(name: 'Other', code: 'OTH'),
      title: 't',
      description: 'd',
      location: ReportLocation(address: 'a', district: 'Al-Tal', lat: 1, lng: 2),
      affectedCount: 3,
      initialSeverity: RiskLevel.low,
    ).toJson();

    expect(json['category'], {'name': 'Other', 'code': 'OTH'});
    expect((json['location'] as Map)['district'], 'Al-Tal');
    expect(json['initialSeverity'], 'LOW');
    expect(json.containsKey('imageUrl'), isFalse);
  });
}
