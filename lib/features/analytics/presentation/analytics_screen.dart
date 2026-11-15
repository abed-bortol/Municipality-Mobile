import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/analytics/presentation/widgets/charts.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website AnalyticsCharts colours.
const _riskColors = {
  'CRITICAL': Color(0xFFE11D48),
  'HIGH': Color(0xFFEA580C),
  'MEDIUM': Color(0xFFD97706),
  'LOW': Color(0xFF059669),
};
const _categoryColor = AppColors.teal600;
const _districtColor = Color(0xFF3B82F6);
const _statusColor = Color(0xFF8B5CF6);

/// Website AnalyticsCharts: key rates plus category, risk, district and
/// status distributions from `/dashboard/statistics` (staff only).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.epidemiologyCharts),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(dashboardStatsProvider.future)
            .then((_) {}, onError: (_) {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: switch (stats) {
            AsyncValue(:final value?) => _content(context, value),
            AsyncError() => [
              LoadErrorView(
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ],
            _ => const [
              TwoColumnGrid(
                children: [
                  Skeleton(height: 110),
                  Skeleton(height: 110),
                  Skeleton(height: 110),
                  Skeleton(height: 110),
                ],
              ),
              SizedBox(height: 16),
              Skeleton(height: 260),
              SizedBox(height: 16),
              Skeleton(height: 260),
            ],
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, DashboardStats stats) {
    final l10n = context.l10n;

    return [
      TwoColumnGrid(
        children: [
          MetricCard(
            label: l10n.totalRegisteredReports,
            value: '${stats.totalReports}',
            icon: Icons.description_outlined,
            color: AppColors.teal400,
            caption: l10n.cityJurisdiction,
          ),
          MetricCard(
            label: l10n.resolutionContainmentRate,
            value: '${stats.resolutionRate}%',
            icon: Icons.task_alt,
            color: AppColors.teal300,
            caption: l10n.resolvedClosedCount(stats.resolvedCount),
          ),
          MetricCard(
            label: l10n.criticalRisk,
            value: '${stats.criticalCount}',
            icon: Icons.warning_amber_rounded,
            color: AppColors.rose400,
            caption: l10n.criticalScoreHint,
          ),
          MetricCard(
            label: l10n.underInspection,
            value: '${stats.underInvestigationCount}',
            icon: Icons.biotech_outlined,
            color: const Color(0xFFFBBF24),
            caption: l10n.activeFieldTeams,
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (stats.totalReports == 0)
        Container(
          decoration: panelDecoration,
          child: EmptyState(
            icon: Icons.bar_chart,
            message: l10n.noIncidentDataTitle,
            hint: l10n.noIncidentDataBody,
          ),
        )
      else ...[
        SectionCard(
          title: l10n.incidentDistributionByCategory,
          subtitle: l10n.topReportedHazards,
          icon: Icons.bar_chart,
          child: BarList(
            entries: [
              for (final c in stats.categoryData.take(7))
                (
                  label: l10n.categoryName(c.name),
                  count: c.count,
                  color: _categoryColor,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.riskLevelDistribution,
          subtitle: l10n.algorithmicAssessment,
          icon: Icons.shield_outlined,
          child: DonutChart(
            entries: [
              for (final r in stats.riskData)
                (
                  label: l10n.riskLabel(r.level),
                  count: r.count,
                  color: _riskColors[r.level] ?? _categoryColor,
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      SectionCard(
        title: l10n.incidentsByTripoliDistrict,
        subtitle: l10n.geographicSpread,
        icon: Icons.place_outlined,
        child: BarList(
          entries: [
            for (final d in stats.districtData.take(8))
              (
                label: l10n.districtName(d.district),
                count: d.count,
                color: _districtColor,
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: l10n.investigationLifecycleStatus,
        subtitle: l10n.pipeline,
        icon: Icons.check_circle_outline,
        child: BarList(
          entries: [
            for (final s in stats.statusData)
              (
                label: l10n.statusLabel(s.status),
                count: s.count,
                color: _statusColor,
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}
