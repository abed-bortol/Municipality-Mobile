import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/widgets/report_card.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website CitizenDashboard: welcome hero, personal counters and the latest
/// submissions.
class CitizenDashboard extends ConsumerWidget {
  const CitizenDashboard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reports = ref.watch(dashboardReportsProvider);
    final page = reports.value;
    final list = page?.reports ?? const <Report>[];
    final total = page?.total ?? 0;

    String count(bool Function(Report) test) =>
        page == null ? '–' : '${list.where(test).length}';

    return RefreshIndicator(
      // Failures are shown in place, so the spinner just stops.
      onRefresh: () => ref
          .refresh(dashboardReportsProvider.future)
          .then((_) {}, onError: (_) {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(user: user, total: total),
          const SizedBox(height: 16),
          MetricCard(
            label: l10n.mySubmittedReports,
            value: page == null ? '–' : '$total',
            icon: Icons.description_outlined,
            color: AppColors.teal400,
          ),
          const SizedBox(height: 12),
          TwoColumnGrid(
            children: [
              MetricCard(
                label: l10n.underActiveInspection,
                value: count(
                  (r) =>
                      r.status == ReportStatus.inInvestigation ||
                      r.status == ReportStatus.verified,
                ),
                icon: Icons.search,
                color: const Color(0xFFFBBF24),
              ),
              MetricCard(
                label: l10n.resolvedRemediated,
                value: count(
                  (r) =>
                      r.status == ReportStatus.resolved ||
                      r.status == ReportStatus.closed,
                ),
                icon: Icons.verified_outlined,
                color: const Color(0xFF34D399),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.myRecentReports,
            icon: Icons.history,
            trailing: total > 0
                ? TextButton(
                    onPressed: () => context.go(AppRoutes.reports),
                    child: Text(l10n.viewAll(total)),
                  )
                : null,
            child: switch (reports) {
              AsyncValue(hasValue: true) when list.isEmpty => EmptyState(
                icon: Icons.inbox_outlined,
                message: l10n.noReportsYet,
                action: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.newReport),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.reportIssueCta),
                ),
              ),
              AsyncValue(hasValue: true) => Column(
                children: [
                  for (final r in list.take(4)) ...[
                    ReportCard(report: r),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              AsyncError() => LoadErrorView(
                onRetry: () => ref.invalidate(dashboardReportsProvider),
              ),
              _ => const _ListSkeleton(),
            },
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.user, required this.total});

  final User user;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal800.withValues(alpha: 0.6)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.teal950,
            AppColors.slate800.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.teal500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.teal500.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              l10n.citizenPortalBadge,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.teal300,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              l10n.welcomeBack(user.name),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.citizenHeroBody,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.slate300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.submitIncident,
            icon: Icons.add_circle_outline,
            onPressed: () => context.go(AppRoutes.newReport),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.go(AppRoutes.reports),
              icon: const Icon(Icons.track_changes, size: 20),
              label: Text(l10n.trackMySubmissions(total)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Skeleton(height: 96),
      SizedBox(height: 8),
      Skeleton(height: 96),
      SizedBox(height: 8),
      Skeleton(height: 96),
    ],
  );
}
