import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/features/clusters/presentation/clusters_providers.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/reports/data/reports_repository_impl.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

/// Maximum points per risk factor in the server's riskEngine.js.
const riskFactorMaxima = (
  severity: 25,
  affected: 25,
  recency: 15,
  cluster: 20,
  category: 15,
);

/// Correlation rules in the server's clusterDetection.service.js.
const clusterRules = (radiusKm: '1.2', windowHours: 72, minReports: 3);

/// Website AdminSystemSettings. The website's sliders are never saved, so
/// the engine parameters are shown as the server actually applies them;
/// the two maintenance actions are real (administrators only).
class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  bool _recalculating = false;
  bool _scanning = false;

  Future<void> _recalculate() async {
    final l10n = context.l10n;
    setState(() => _recalculating = true);
    try {
      final count = await ref.read(reportsRepositoryProvider).reassessRisks();
      ref
        ..invalidate(reportsProvider)
        ..invalidate(dashboardStatsProvider);
      showAppSnackBar(l10n.scoresRecalculated(count));
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _recalculating = false);
    }
  }

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
    final textTheme = Theme.of(context).textTheme;
    const m = riskFactorMaxima;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.systemSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsTitle,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            l10n.settingsSubtitle,
            style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.engineReadOnlyNote,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.riskWeightsTitle,
            subtitle:
                'riskScore = severity + affected + recency + cluster + '
                'category',
            icon: Icons.tune,
            child: Column(
              children: [
                _ValueRow(l10n.weightSeverity, l10n.upToPoints(m.severity)),
                _ValueRow(l10n.weightAffected, l10n.upToPoints(m.affected)),
                _ValueRow(l10n.weightRecency, l10n.upToPoints(m.recency)),
                _ValueRow(l10n.weightCluster, l10n.upToPoints(m.cluster)),
                _ValueRow(l10n.weightCategory, l10n.upToPoints(m.category)),
                const Divider(height: 24),
                _ActionTile(
                  title: l10n.recalibrationTitle,
                  description: l10n.recalibrationDesc,
                  label: _recalculating
                      ? l10n.recalculating
                      : l10n.recalculateScores,
                  icon: Icons.refresh,
                  busy: _recalculating,
                  onPressed: _recalculate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.clusterSettingsTitle,
            subtitle: l10n.clusterSettingsDesc,
            icon: Icons.radar,
            child: Column(
              children: [
                _ValueRow(
                  l10n.correlationRadius,
                  l10n.kilometers(clusterRules.radiusKm),
                ),
                _ValueRow(
                  l10n.temporalWindow,
                  l10n.hoursValue(clusterRules.windowHours),
                ),
                _ValueRow(
                  l10n.minimumReports,
                  l10n.reportsValue(clusterRules.minReports),
                ),
                const Divider(height: 24),
                _ActionTile(
                  title: l10n.epiSurveillance,
                  description: l10n.clusterEngineDesc,
                  label: _scanning
                      ? l10n.scanningGrid
                      : l10n.runClusterScanShort,
                  icon: Icons.bolt,
                  busy: _scanning,
                  onPressed: _scan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.slate300),
            ),
          ),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.teal300,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.description,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.teal300,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(label),
        ),
      ],
    );
  }
}
