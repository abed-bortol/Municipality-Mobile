import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/report.dart';

part 'reports_query.freezed.dart';

/// Filters supported by `GET /reports` (report.service.js getReportsFromDB).
/// Citizens only ever receive their own reports (enforced server-side).
@freezed
abstract class ReportsQuery with _$ReportsQuery {
  const ReportsQuery._();

  const factory ReportsQuery({
    ReportStatus? status,
    RiskLevel? riskLevel,
    String? district,
    String? category,
  }) = _ReportsQuery;

  bool get hasFilters =>
      status != null || riskLevel != null || district != null || category != null;

  Map<String, dynamic> toQueryParameters() => {
        if (status != null) 'status': status!.apiValue,
        if (riskLevel != null) 'riskLevel': riskLevel!.apiValue,
        if (district != null) 'district': district,
        if (category != null) 'category': category,
      };
}

/// One page of `GET /reports`.
@freezed
abstract class ReportsPage with _$ReportsPage {
  const ReportsPage._();

  const factory ReportsPage({
    required List<Report> reports,
    required int total,
    required int page,
    required int totalPages,
  }) = _ReportsPage;

  bool get hasMore => page < totalPages;
}
