import 'package:municipality/features/reports/domain/new_report_request.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';

/// All methods throw `ApiException` on failure.
abstract interface class ReportsRepository {
  Future<ReportsPage> getReports({
    ReportsQuery query = const ReportsQuery(),
    int page = 1,
    int limit = 20,
  });

  Future<Report> getReport(String id);

  Future<Report> createReport(NewReportRequest request);

  /// Staff only.
  Future<Report> updateStatus(
    String id,
    ReportStatus status, {
    String comment = '',
  });

  /// Staff only.
  Future<Report> assignOfficer(String id, String officerId);

  /// Administrators only. Returns how many open reports were re-scored.
  Future<int> reassessRisks();
}
