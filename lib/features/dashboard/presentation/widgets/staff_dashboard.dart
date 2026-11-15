import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/widgets/report_card.dart';
import 'package:municipality/l10n/l10n.dart';

const _amber = Color(0xFFFBBF24);
const _orange = Color(0xFFFB923C);
const _emerald = Color(0xFF34D399);

/// Website OfficerDashboard (also used for administrators): city metrics,
/// map shortcut, detected clusters, quick actions and the triage queue.
class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Failures are shown per section, so the spinner just stops.
    Future<void> refresh() => Future.wait([
      ref.refresh(dashboardStatsProvider.future),
      ref.refresh(reportsProvider.future),
      ref.refresh(activeClustersProvider.future),
    ]).then((_) {}, onError: (_) {});

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Metrics(),
          SizedBox(height: 16),
          _MapCard(),
          SizedBox(height: 16),
          _Clusters(),
          SizedBox(height: 16),
          _QuickActions(),
          SizedBox(height: 16),
          _TriageQueue(),
        ],
      ),
    );
  }
}

class _Metrics extends ConsumerWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(dashboardStatsProvider)) {
      AsyncValue(:final DashboardStats value) => _grid(context.l10n, value),
      AsyncError() => DecoratedBox(
        decoration: panelDecoration,
        child: LoadErrorView(
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
      ),
      _ => TwoColumnGrid(
        children: [
          for (var i = 0; i < 6; i++) const Skeleton(height: 112, radius: 16),
        ],
      ),
    };
  }

  Widget _grid(AppLocalizations l10n, DashboardStats s) => TwoColumnGrid(
    children: [
      MetricCard(
        label: l10n.totalReports,
        value: '${s.totalReports}',
        caption: l10n.cityJurisdiction,
        icon: Icons.description_outlined,
        color: AppColors.teal400,
      ),
      MetricCard(
        label: l10n.reportsToday,
        value: '${s.reportsToday}',
        caption: l10n.thisWeek(s.reportsThisWeek),
        icon: Icons.today_outlined,
        color: const Color(0xFF22D3EE),
      ),
      MetricCard(
        label: l10n.criticalRisk,
        value: '${s.criticalCount}',
        caption: l10n.immediateDispatch,
        icon: Icons.warning_amber_rounded,
        color: AppColors.rose400,
      ),
      MetricCard(
        label: l10n.highRisk,
        value: '${s.highCount}',
        caption: l10n.priorityInspection,
        icon: Icons.priority_high_rounded,
        color: _orange,
      ),
      MetricCard(
        label: l10n.underInspection,
        value: '${s.underInvestigationCount}',
        caption: l10n.activeFieldTeams,
        icon: Icons.biotech_outlined,
        color: _amber,
      ),
      MetricCard(
        label: l10n.resolutionRate,
        value: '${s.resolutionRate}%',
        caption: l10n.remediatedCount(s.resolvedCount),
        icon: Icons.task_alt,
        color: _emerald,
      ),
    ],
  );
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.liveTripoliView,
      subtitle: l10n.liveMapHint,
      icon: Icons.map_outlined,
      child: Material(
        color: AppColors.slate950,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.teal800.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(AppRoutes.map),
          child: SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _GridPainter()),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fullscreen, color: AppColors.teal300),
                    const SizedBox(width: 8),
                    Text(
                      l10n.fullScreenMap,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.teal300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint map-like grid behind the map shortcut.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.teal800.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final dot = Paint()..color = AppColors.rose400.withValues(alpha: 0.5);
    for (final (dx, dy, r) in const [
      (0.22, 0.35, 6.0),
      (0.7, 0.3, 9.0),
      (0.82, 0.72, 5.0),
      (0.35, 0.75, 7.0),
    ]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * dy), r, dot);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _Clusters extends ConsumerWidget {
  const _Clusters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clusters = ref.watch(activeClustersProvider);

    return SectionCard(
      title: l10n.detectedClusters,
      icon: Icons.bubble_chart_outlined,
      trailing: IconButton(
        tooltip: l10n.clusterDetection,
        onPressed: () => context.go(AppRoutes.clusters),
        icon: const Icon(Icons.arrow_forward),
      ),
      child: switch (clusters) {
        AsyncValue(value: final List<Cluster> list) when list.isEmpty =>
          EmptyState(
            icon: Icons.shield_outlined,
            message: l10n.noActiveClusters,
            hint: l10n.systemScansAutomatically,
          ),
        AsyncValue(value: final List<Cluster> list) => Column(
          children: [
            for (final c in list.take(3)) ...[
              _ClusterTile(cluster: c),
              const SizedBox(height: 8),
            ],
          ],
        ),
        AsyncError() => LoadErrorView(
          onRetry: () => ref.invalidate(activeClustersProvider),
        ),
        _ => const Column(
          children: [
            Skeleton(height: 64),
            SizedBox(height: 8),
            Skeleton(height: 64),
          ],
        ),
      },
    );
  }
}

class _ClusterTile extends StatelessWidget {
  const _ClusterTile({required this.cluster});

  final Cluster cluster;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final color = RiskBadge.colorOf(cluster.riskLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cluster.clusterCode,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              RiskBadge(level: cluster.riskLevel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.categoryName(cluster.categoryName)} · '
            '${l10n.districtName(cluster.district)}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.affectedCitizens(cluster.totalAffected),
            style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.officerQuickActions,
      icon: Icons.bolt_outlined,
      child: TwoColumnGrid(
        spacing: 8,
        children: [
          _QuickAction(
            icon: Icons.fact_check_outlined,
            title: l10n.reportTriage,
            subtitle: l10n.reviewQueue,
            route: AppRoutes.reports,
            color: AppColors.teal400,
          ),
          _QuickAction(
            icon: Icons.biotech_outlined,
            title: l10n.investigations,
            subtitle: l10n.labLogs,
            route: AppRoutes.investigations,
            color: _amber,
          ),
          _QuickAction(
            icon: Icons.notifications_active_outlined,
            title: l10n.activeAlerts,
            subtitle: l10n.dispatches,
            route: AppRoutes.alerts,
            color: AppColors.rose400,
          ),
          _QuickAction(
            icon: Icons.print_outlined,
            title: l10n.exportDossier,
            subtitle: l10n.printableBrief,
            route: AppRoutes.exportDossier,
            color: const Color(0xFF818CF8),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.slate900.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.slate700.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriageQueue extends ConsumerWidget {
  const _TriageQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reports = ref.watch(reportsProvider);

    return SectionCard(
      title: l10n.priorityQueue,
      subtitle: l10n.awaitingTriage,
      icon: Icons.low_priority,
      child: switch (reports) {
        AsyncValue(:final value?) => _queue(
          context,
          priorityTriageQueue(value.reports),
        ),
        AsyncError() => LoadErrorView(
          onRetry: () => ref.invalidate(reportsProvider),
        ),
        _ => const Column(
          children: [
            Skeleton(height: 110),
            SizedBox(height: 8),
            Skeleton(height: 110),
          ],
        ),
      },
    );
  }

  Widget _queue(BuildContext context, List<Report> queue) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (queue.isEmpty)
          EmptyState(icon: Icons.inbox_outlined, message: l10n.triageQueueClear)
        else
          for (final r in queue) ...[
            ReportCard(report: r, showRiskScore: true),
            const SizedBox(height: 8),
          ],
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.reports),
          icon: const Icon(Icons.list_alt),
          label: Text(l10n.manageAllReports),
        ),
      ],
    );
  }
}
