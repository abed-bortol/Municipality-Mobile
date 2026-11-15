import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/report.dart';

part 'reports_filter.freezed.dart';

enum ReportSort { risk, date, affected }

/// Search, filters and sort of the reports list. Applied on the device to
/// the loaded reports, like the website's ReportsManagement.
@freezed
abstract class ReportsFilter with _$ReportsFilter {
  const ReportsFilter._();

  const factory ReportsFilter({
    @Default('') String search,
    String? category,
    String? district,
    RiskLevel? riskLevel,
    ReportStatus? status,
    @Default(ReportSort.risk) ReportSort sort,
  }) = _ReportsFilter;

  /// Number of active dropdown filters (search and sort excluded).
  int get activeCount => [category, district, riskLevel, status]
      .where((value) => value != null)
      .length;

  /// [districtLabel] lets the search also match translated district names.
  List<Report> apply(
    List<Report> reports, {
    String Function(String district)? districtLabel,
  }) {
    final query = search.trim().toLowerCase();

    bool matchesSearch(Report r) {
      if (query.isEmpty) return true;
      final district = r.location.district;
      return [
        r.reportNumber,
        r.title,
        r.description,
        r.citizen.name,
        district,
        if (districtLabel != null) districtLabel(district),
      ].any((field) => field.toLowerCase().contains(query));
    }

    final result = [
      for (final r in reports)
        if ((category == null || r.category.name == category) &&
            (district == null || r.location.district == district) &&
            (riskLevel == null || r.riskLevel == riskLevel) &&
            (status == null || r.status == status) &&
            matchesSearch(r))
          r,
    ];

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    result.sort(switch (sort) {
      ReportSort.risk => (a, b) => b.riskScore.compareTo(a.riskScore),
      ReportSort.affected => (a, b) => b.affectedCount.compareTo(a.affectedCount),
      ReportSort.date => (a, b) =>
          (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
    });
    return result;
  }
}
