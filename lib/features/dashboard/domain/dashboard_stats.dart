import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

/// `GET /dashboard/statistics` (dashboard.service.js).
@freezed
abstract class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @Default(0) int totalReports,
    @Default(0) int reportsToday,
    @Default(0) int reportsThisWeek,
    @Default(0) int reportsThisMonth,
    @Default(0) int criticalCount,
    @Default(0) int highCount,
    @Default(0) int underInvestigationCount,
    @Default(0) int resolvedCount,
    @Default(0) int resolutionRate,
    @Default(0) int activeAlerts,
    @Default(0) int activeClusters,
    @Default(0) int totalInvestigations,
    @Default(<NamedCount>[]) List<NamedCount> categoryData,
    @Default(<StatusCount>[]) List<StatusCount> statusData,
    @Default(<DistrictCount>[]) List<DistrictCount> districtData,
    @Default(<RiskCount>[]) List<RiskCount> riskData,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

@freezed
abstract class NamedCount with _$NamedCount {
  const factory NamedCount({@Default('') String name, @Default(0) int count}) =
      _NamedCount;

  factory NamedCount.fromJson(Map<String, dynamic> json) =>
      _$NamedCountFromJson(json);
}

/// [status] is the raw API value (e.g. `IN_INVESTIGATION`).
@freezed
abstract class StatusCount with _$StatusCount {
  const factory StatusCount({@Default('') String status, @Default(0) int count}) =
      _StatusCount;

  factory StatusCount.fromJson(Map<String, dynamic> json) =>
      _$StatusCountFromJson(json);
}

@freezed
abstract class DistrictCount with _$DistrictCount {
  const factory DistrictCount({
    @Default('') String district,
    @Default(0) int count,
  }) = _DistrictCount;

  factory DistrictCount.fromJson(Map<String, dynamic> json) =>
      _$DistrictCountFromJson(json);
}

/// [level] is the raw API value (e.g. `CRITICAL`).
@freezed
abstract class RiskCount with _$RiskCount {
  const factory RiskCount({@Default('') String level, @Default(0) int count}) =
      _RiskCount;

  factory RiskCount.fromJson(Map<String, dynamic> json) =>
      _$RiskCountFromJson(json);
}
