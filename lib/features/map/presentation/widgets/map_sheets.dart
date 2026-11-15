import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/clusters/presentation/widgets/cluster_labels.dart';
import 'package:municipality/features/map/domain/map_filter.dart';
import 'package:municipality/features/map/presentation/map_providers.dart';
import 'package:municipality/features/map/presentation/widgets/base_map_tiles.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/widgets/report_status_badge.dart';
import 'package:municipality/l10n/l10n.dart';

typedef MapLayers = ({MapStyle style, bool showClusters, bool showDistricts});

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: builder(context),
        ),
      ),
    );

Widget _title(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
  ),
);

/// Base map and layer toggles; returns the new choice.
Future<MapLayers?> showMapLayersSheet(
  BuildContext context, {
  required MapStyle style,
  required bool showClusters,
  required bool showDistricts,
  required int clusterCount,
}) {
  var current = (
    style: style,
    showClusters: showClusters,
    showDistricts: showDistricts,
  );
  return _sheet(
    context,
    (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = context.l10n;
        void update(MapLayers value) {
          setState(() => current = value);
          Navigator.pop(context, value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(context, l10n.mapLayers),
            Text(
              l10n.mapStyle,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.slate300),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in MapStyle.values)
                  ChoiceChip(
                    label: Text(s.label(l10n)),
                    selected: current.style == s,
                    onSelected: (_) => update((
                      style: s,
                      showClusters: current.showClusters,
                      showDistricts: current.showDistricts,
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.clustersLayer(clusterCount)),
              value: current.showClusters,
              onChanged: (v) => update((
                style: current.style,
                showClusters: v,
                showDistricts: current.showDistricts,
              )),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.districtsLayer),
              value: current.showDistricts,
              onChanged: (v) => update((
                style: current.style,
                showClusters: current.showClusters,
                showDistricts: v,
              )),
            ),
          ],
        );
      },
    ),
  );
}

/// Risk / status / category filters; applied live.
Future<void> showMapFilterSheet(BuildContext context, List<Report> reports) {
  final categories = {for (final r in reports) r.category.name}..remove('');
  return _sheet(context, (context) => _MapFilterForm(categories: categories));
}

class _MapFilterForm extends ConsumerWidget {
  const _MapFilterForm({required this.categories});

  final Set<String> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(mapFilterControllerProvider);
    final controller = ref.read(mapFilterControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(context, l10n.filters),
        DropdownButtonFormField<RiskLevel?>(
          initialValue: filter.riskLevel,
          decoration: InputDecoration(labelText: l10n.riskLevel),
          items: [
            DropdownMenuItem(child: Text(l10n.allRisks)),
            for (final level in RiskLevel.values)
              DropdownMenuItem(
                value: level,
                child: Text(l10n.riskLabel(level.apiValue)),
              ),
          ],
          onChanged: controller.setRiskLevel,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ReportStatus?>(
          initialValue: filter.status,
          decoration: InputDecoration(labelText: l10n.status),
          items: [
            DropdownMenuItem(child: Text(l10n.allStatuses)),
            for (final status in ReportStatus.values)
              DropdownMenuItem(
                value: status,
                child: Text(l10n.statusLabel(status.apiValue)),
              ),
          ],
          onChanged: controller.setStatus,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: categories.contains(filter.category)
              ? filter.category
              : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.category),
          items: [
            DropdownMenuItem(child: Text(l10n.allCategories)),
            for (final name in categories)
              DropdownMenuItem(
                value: name,
                child: Text(
                  l10n.categoryName(name),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: controller.setCategory,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: filter.activeCount == 0
                  ? null
                  : () {
                      controller.clear();
                      Navigator.pop(context);
                    },
              child: Text(l10n.clearFilters),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.showResults),
            ),
          ],
        ),
      ],
    );
  }
}

/// Website marker popup: number, title, risk and "Inspect & Manage".
Future<void> showReportPreviewSheet(BuildContext context, Report report) {
  return _sheet(context, (context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '#${report.reportNumber}',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.teal300,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            RiskBadge(level: report.riskLevel),
            const SizedBox(width: 6),
            ReportStatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          report.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.categoryName(report.category.name)} · '
          '${l10n.districtName(report.location.district)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.riskScore(report.riskScore.round())} · '
          '${l10n.affectedPeople(report.affectedCount)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.go(AppRoutes.reportDetails(report.id));
          },
          icon: const Icon(Icons.manage_search),
          label: Text(l10n.inspectManage),
        ),
      ],
    );
  });
}

/// Website cluster popup.
Future<void> showClusterSheet(
  BuildContext context,
  Cluster cluster,
  List<Report> reports,
) {
  return _sheet(context, (context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final ids = {for (final r in reports) r.reportNumber: r.id};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.activeSurveillanceCluster.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.rose300,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                cluster.clusterCode,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            RiskBadge(level: cluster.riskLevel),
            const SizedBox(width: 6),
            Pill(
              label: cluster.status.label(l10n),
              color: cluster.status.color,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.categoryName(cluster.categoryName)} · '
          '${l10n.districtName(cluster.district)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.loggedCases(cluster.reportCount)} · '
          '${l10n.affectedCitizens(cluster.totalAffected)} · '
          '${l10n.radiusMeters(cluster.radiusMeters.round())}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
        ),
        if (cluster.reportNumbers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final number in cluster.reportNumbers)
                ActionChip(
                  label: Text('#$number'),
                  onPressed: ids[number] == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          context.go(AppRoutes.reportDetails(ids[number]!));
                        },
                ),
            ],
          ),
        ],
      ],
    );
  });
}

/// Website "District Public Health Profile" panel.
Future<void> showDistrictProfileSheet(
  BuildContext context, {
  required String district,
  required List<Report> reports,
  required List<Alert> alerts,
}) {
  final profile = districtProfile(district, reports, alerts);
  return _sheet(context, (context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.districtProfile.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.teal300,
            fontWeight: FontWeight.w800,
          ),
        ),
        _title(context, l10n.districtName(district)),
        TwoColumnGrid(
          children: [
            MetricCard(
              label: l10n.totalReports,
              value: '${profile.reports}',
              icon: Icons.description_outlined,
              color: AppColors.teal400,
            ),
            MetricCard(
              label: l10n.criticalHighRisk,
              value: '${profile.criticalOrHigh}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.rose400,
            ),
            MetricCard(
              label: l10n.estimatedAffected,
              value: '${profile.affected}',
              icon: Icons.groups_outlined,
              color: const Color(0xFFFB923C),
            ),
            MetricCard(
              label: l10n.activeAlerts,
              value: '${profile.activeAlerts}',
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFFFBBF24),
            ),
          ],
        ),
        if (profile.topCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.topCategories,
            style: textTheme.labelLarge?.copyWith(color: AppColors.slate300),
          ),
          const SizedBox(height: 6),
          for (final (name, count) in profile.topCategories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.categoryName(name))),
                  Text(
                    '$count',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  });
}
