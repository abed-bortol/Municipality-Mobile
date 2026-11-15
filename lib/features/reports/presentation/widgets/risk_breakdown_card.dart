import 'package:flutter/material.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/l10n/l10n.dart';

/// The five factors of the risk engine (0-100 in total), with the server's
/// justifications.
class RiskBreakdownCard extends StatelessWidget {
  const RiskBreakdownCard({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final explanations = report.riskFactors.explanations;

    return SectionCard(
      title: l10n.riskBreakdown,
      icon: Icons.analytics_outlined,
      trailing: Text(
        l10n.scoreOutOf(report.riskScore.round()),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: RiskBadge.colorOf(report.riskLevel),
            ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiskFactorBars(factors: report.riskFactors, level: report.riskLevel),
          if (explanations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.evaluatorJustifications,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final e in explanations)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $e',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate300)),
              ),
          ],
        ],
      ),
    );
  }
}

/// One bar per factor, filled relative to its maximum. Also used for the
/// live estimate on the submission form.
class RiskFactorBars extends StatelessWidget {
  const RiskFactorBars({super.key, required this.factors, required this.level});

  final RiskFactors factors;
  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final color = RiskBadge.colorOf(level);
    final rows = [
      (l10n.severityScoreLabel, factors.severityScore, 25),
      (l10n.affectedPopLabel, factors.affectedPeopleScore, 25),
      (l10n.recencyWeightLabel, factors.recentReportsScore, 15),
      (l10n.geoClusterLabel, factors.geographicClusterScore, 20),
      (l10n.categoryPriorityLabel, factors.categoryScore, 15),
    ];

    return Column(
      children: [
        for (final (label, score, max) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.slate300)),
                      ),
                      Text('+${score.round()}',
                          style: textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Text(l10n.maxPoints(max),
                          style: textTheme.labelSmall
                              ?.copyWith(color: AppColors.slate500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score / max).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      color: color,
                      backgroundColor: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
