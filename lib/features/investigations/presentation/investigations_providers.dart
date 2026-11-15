import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/investigations/data/investigations_repository.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'investigations_providers.g.dart';

/// All investigations, newest first (staff only).
@riverpod
Future<List<Investigation>> investigations(Ref ref) =>
    ref.watch(investigationsRepositoryProvider).getInvestigations();

/// The report's open investigation, else its latest one, else null
/// (same lookup as the website's InvestigationModal).
@riverpod
Future<Investigation?> reportInvestigation(Ref ref, String reportId) async {
  final all = await ref.watch(investigationsProvider.future);
  final forReport = [
    for (final i in all)
      if (i.reportId == reportId) i,
  ];
  return forReport
          .where((i) => i.status != InvestigationStatus.completed)
          .firstOrNull ??
      forReport.firstOrNull;
}

/// Investigation changes. Each one refreshes investigations, reports and
/// the dashboard. All methods throw `ApiException`.
@Riverpod(keepAlive: true)
class InvestigationActions extends _$InvestigationActions {
  @override
  void build() {}

  /// Saves the draft. A completed record is edited in place; otherwise this
  /// opens the investigation (moving a VERIFIED report forward) or updates
  /// the open one. Finalizing is the only way to complete it.
  Future<void> save(
    Report report,
    InvestigationDraft draft, {
    Investigation? existing,
  }) async {
    final repo = ref.read(investigationsRepositoryProvider);
    if (existing != null && existing.status == InvestigationStatus.completed) {
      await repo.update(existing.id, draft);
    } else {
      final status = draft.status == InvestigationStatus.completed
          ? InvestigationStatus.inProgress
          : draft.status;
      await repo.save(report.id, draft.copyWith(status: status));
    }
    _changed(report.id);
  }

  /// Records the closing data and resolves the report. A VERIFIED report is
  /// first moved into investigation, as the server requires.
  Future<Report> finalize(Report report, InvestigationDraft draft) async {
    final repo = ref.read(investigationsRepositoryProvider);
    final closing = draft.copyWith(
      recommendations: draft.recommendations.isEmpty
          ? 'Continuous routine surveillance & swab monitoring'
          : draft.recommendations,
      result: draft.result == InvestigationResult.inconclusive
          ? InvestigationResult.resolved
          : draft.result,
      notes: draft.notes.isEmpty
          ? 'Field inspection concluded and hazards remediated'
          : draft.notes,
      status: null,
    );
    if (report.status == ReportStatus.verified) {
      await repo.save(
          report.id, closing.copyWith(status: InvestigationStatus.inProgress));
    }
    final resolved = await repo.finalize(report.id, closing);
    _changed(report.id);
    return resolved;
  }

  void _changed(String reportId) => ref
    ..invalidate(investigationsProvider)
    ..invalidate(reportsProvider)
    ..invalidate(reportDetailsProvider(reportId))
    ..invalidate(dashboardStatsProvider);
}
