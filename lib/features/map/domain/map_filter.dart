import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/reports/domain/report.dart';

part 'map_filter.freezed.dart';

/// Map filters (website TripoliMap: risk, status, category).
@freezed
abstract class MapFilter with _$MapFilter {
  const MapFilter._();

  const factory MapFilter({
    RiskLevel? riskLevel,
    ReportStatus? status,
    String? category,
  }) = _MapFilter;

  int get activeCount =>
      [riskLevel, status, category].where((v) => v != null).length;

  /// Reports that match and have coordinates.
  List<Report> apply(List<Report> reports) => [
    for (final r in reports)
      if (r.location.lat != 0 &&
          r.location.lng != 0 &&
          (riskLevel == null || r.riskLevel == riskLevel) &&
          (status == null || r.status == status) &&
          (category == null || r.category.name == category))
        r,
  ];
}

/// Website "District Public Health Profile" panel.
typedef DistrictProfile = ({
  int reports,
  int criticalOrHigh,
  int affected,
  int activeAlerts,
  List<(String category, int count)> topCategories,
});

DistrictProfile districtProfile(
  String district,
  List<Report> reports,
  List<Alert> alerts,
) {
  final inDistrict = [
    for (final r in reports)
      if (r.location.district == district) r,
  ];
  final byCategory = <String, int>{};
  for (final r in inDistrict) {
    byCategory.update(r.category.name, (n) => n + 1, ifAbsent: () => 1);
  }
  final top = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return (
    reports: inDistrict.length,
    criticalOrHigh: inDistrict.where((r) => r.riskLevel.isUrgent).length,
    affected: inDistrict.fold(0, (sum, r) => sum + r.affectedCount),
    activeAlerts: alerts
        .where(
          (a) =>
              a.status == AlertStatus.active &&
              a.area.toLowerCase() == district.toLowerCase(),
        )
        .length,
    topCategories: [for (final e in top.take(4)) (e.key, e.value)],
  );
}
