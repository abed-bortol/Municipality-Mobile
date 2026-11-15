import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/clusters/data/clusters_repository.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/data/dashboard_repository.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/reports/data/reports_repository_impl.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// City-wide counters (staff dashboard).
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) =>
    ref.watch(dashboardRepositoryProvider).getStats();

/// Latest reports, newest first. Citizens get only their own (server-side).
/// Same page size as the website's dashboards.
@riverpod
Future<ReportsPage> dashboardReports(Ref ref) =>
    ref.watch(reportsRepositoryProvider).getReports(limit: 100);

/// Active clusters (staff only).
@riverpod
Future<List<Cluster>> activeClusters(Ref ref) =>
    ref.watch(clustersRepositoryProvider).getClusters();

/// Website OfficerDashboard: new or critical reports that are still open,
/// highest risk score first.
List<Report> priorityTriageQueue(List<Report> reports, {int take = 5}) {
  const awaiting = {ReportStatus.submitted, ReportStatus.underReview};
  const done = {ReportStatus.resolved, ReportStatus.closed};
  final queue = [
    for (final r in reports)
      if ((awaiting.contains(r.status) || r.riskLevel == RiskLevel.critical) &&
          !done.contains(r.status))
        r,
  ]..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  return queue.take(take).toList();
}
