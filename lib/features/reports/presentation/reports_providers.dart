import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/reports/data/reports_repository_impl.dart';
import 'package:municipality/features/reports/domain/new_report_request.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/report_workflow.dart';
import 'package:municipality/features/reports/domain/reports_filter.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_providers.g.dart';

/// Reports visible to the user, newest first: all of them for staff, only
/// their own for citizens (server-side). Shared by the dashboards and the
/// reports list; same 500 cap as the website's DataContext.
@riverpod
Future<ReportsPage> reports(Ref ref) =>
    ref.watch(reportsRepositoryProvider).getReports(limit: 500);

@riverpod
Future<Report> reportDetails(Ref ref, String id) =>
    ref.watch(reportsRepositoryProvider).getReport(id);

/// Search / filters / sort of the reports tab. Staff triage by risk,
/// citizens see their latest reports first.
@riverpod
class ReportsFilterController extends _$ReportsFilterController {
  @override
  ReportsFilter build() {
    // Resets with the session (auth only changes on sign-in / sign-out).
    final role = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.role,
      _ => UserRole.citizen,
    };
    return ReportsFilter(
      sort: role == UserRole.citizen ? ReportSort.date : ReportSort.risk,
    );
  }

  void setSearch(String search) => state = state.copyWith(search: search);
  void setSort(ReportSort sort) => state = state.copyWith(sort: sort);
  void setCategory(String? value) => state = state.copyWith(category: value);
  void setDistrict(String? value) => state = state.copyWith(district: value);
  void setRiskLevel(RiskLevel? value) =>
      state = state.copyWith(riskLevel: value);
  void setStatus(ReportStatus? value) => state = state.copyWith(status: value);

  void clearFilters() => state = state.copyWith(
        category: null,
        district: null,
        riskLevel: null,
        status: null,
      );
}

/// Report changes made by the user. Each one refreshes the lists, the
/// report's details and the dashboard counters. All methods throw
/// `ApiException`.
@Riverpod(keepAlive: true)
class ReportActions extends _$ReportActions {
  @override
  void build() {}

  Future<Report> create(NewReportRequest request) =>
      _run(() => ref.read(reportsRepositoryProvider).createReport(request));

  Future<Report> advance(Report report, {String comment = ''}) {
    final next = report.status.nextStep;
    if (next == null) throw StateError('${report.status} is terminal');
    return _run(() => ref.read(reportsRepositoryProvider).updateStatus(
          report.id,
          next,
          comment: comment.isEmpty ? next.defaultComment : comment,
        ));
  }

  Future<Report> reject(Report report, String reason) =>
      _run(() => ref.read(reportsRepositoryProvider).updateStatus(
            report.id,
            ReportStatus.rejected,
            comment: rejectionComment(reason),
          ));

  Future<Report> assign(Report report, String officerId) => _run(
      () => ref.read(reportsRepositoryProvider).assignOfficer(report.id, officerId));

  Future<Report> _run(Future<Report> Function() call) async {
    final report = await call();
    ref
      ..invalidate(reportsProvider)
      ..invalidate(reportDetailsProvider(report.id))
      ..invalidate(dashboardStatsProvider);
    return report;
  }
}
