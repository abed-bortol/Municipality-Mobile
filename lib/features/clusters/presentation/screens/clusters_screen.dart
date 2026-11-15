import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/clusters/presentation/clusters_providers.dart';
import 'package:municipality/features/clusters/presentation/widgets/cluster_labels.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/map/presentation/screens/map_screen.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website ClusterMonitor: run the detection engine and manage the
/// detected clusters (staff only).
class ClustersScreen extends ConsumerStatefulWidget {
  const ClustersScreen({super.key});

  @override
  ConsumerState<ClustersScreen> createState() => _ClustersScreenState();
}

class _ClustersScreenState extends ConsumerState<ClustersScreen> {
  bool _scanning = false;

  Future<void> _scan() async {
    final l10n = context.l10n;
    setState(() => _scanning = true);
    try {
      final found = await ref.read(clusterActionsProvider.notifier).detect();
      showAppSnackBar(l10n.scanComplete(found.length));
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final clusters = ref.watch(activeClustersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clusterDetection)),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(activeClustersProvider.future)
            .then((_) {}, onError: (_) {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: panelDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.epiSurveillance.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.teal300,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.clusterEngineTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.clusterEngineDesc,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar),
                    label: Text(
                      _scanning ? l10n.scanningGrid : l10n.runClusterScan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            switch (clusters) {
              AsyncValue(hasValue: true, :final value?) when value.isEmpty =>
                EmptyState(
                  icon: Icons.shield_outlined,
                  message: l10n.noActiveClusters,
                  hint: l10n.noClustersBody,
                ),
              AsyncValue(hasValue: true, :final value?) => Column(
                children: [
                  for (final c in value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClusterCard(cluster: c),
                    ),
                ],
              ),
              AsyncError() => LoadErrorView(
                onRetry: () => ref.invalidate(activeClustersProvider),
              ),
              _ => const Column(
                children: [
                  Skeleton(height: 180),
                  SizedBox(height: 12),
                  Skeleton(height: 180),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _ClusterCard extends ConsumerStatefulWidget {
  const _ClusterCard({required this.cluster});

  final Cluster cluster;

  @override
  ConsumerState<_ClusterCard> createState() => _ClusterCardState();
}

class _ClusterCardState extends ConsumerState<_ClusterCard> {
  bool _busy = false;

  Future<void> _setStatus(ClusterStatus status) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(clusterActionsProvider.notifier)
          .updateStatus(widget.cluster, status);
      showAppSnackBar(
        l10n.clusterStatusUpdated(
          widget.cluster.clusterCode,
          status.label(l10n),
        ),
      );
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final c = widget.cluster;
    final reports = ref.watch(reportsProvider).value?.reports ?? const [];
    final ids = {for (final r in reports) r.reportNumber: r.id};
    final color = RiskBadge.colorOf(c.riskLevel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration.copyWith(
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.coronavirus_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.clusterCode,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              RiskBadge(level: c.riskLevel),
              PopupMenuButton<ClusterStatus>(
                enabled: !_busy,
                tooltip: l10n.changeClusterStatus,
                initialValue: c.status,
                onSelected: (s) {
                  if (s != c.status) _setStatus(s);
                },
                itemBuilder: (_) => [
                  for (final s in ClusterStatus.values)
                    PopupMenuItem(value: s, child: Text(s.label(l10n))),
                ],
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(label: c.status.label(l10n), color: c.status.color),
              Pill(
                label: l10n.categoryName(c.categoryName),
                color: AppColors.teal400,
              ),
              Pill(
                label: l10n.districtName(c.district),
                color: AppColors.cyan500,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.radiusMeters(c.radiusMeters.round())} · '
            '${l10n.incidentsCount(c.reportCount)} · '
            '${l10n.affectedCitizens(c.totalAffected)}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
          ),
          if (c.reportNumbers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.correlatedIncidents,
              style: textTheme.labelMedium?.copyWith(color: AppColors.slate400),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final number in c.reportNumbers.take(6))
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('#$number'),
                    onPressed: ids[number] == null
                        ? null
                        : () =>
                              context.go(AppRoutes.reportDetails(ids[number]!)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (c.detectedAt != null)
                      context.formatDateTime(c.detectedAt!),
                    l10n.timeWindow(c.timeWindowHours),
                  ].join(' · '),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
                ),
              ),
              if (c.lat != 0 && c.lng != 0)
                TextButton.icon(
                  onPressed: () =>
                      showOnMap(context, ref, LatLng(c.lat, c.lng)),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.viewOnMap),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
