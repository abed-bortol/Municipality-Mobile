import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/widgets/report_status_badge.dart';
import 'package:municipality/l10n/l10n.dart';

/// One report in a list: number, title, category/district, date and badges.
/// Opens the report details. [showRiskScore] adds the staff-only score.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.showRiskScore = false,
  });

  final Report report;
  final bool showRiskScore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.slate400);
    final createdAt = report.createdAt;

    return Material(
      color: AppColors.slate800.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.slate700.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.reportDetails(report.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    report.reportNumber,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.teal300,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  if (createdAt != null)
                    Text(context.formatDate(createdAt), style: muted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.categoryName(report.category.name)} · '
                '${l10n.districtName(report.location.district)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ReportStatusBadge(status: report.status),
                  RiskBadge(level: report.riskLevel),
                  if (showRiskScore) ...[
                    Text(
                      l10n.riskScore(report.riskScore.round()),
                      style: muted,
                    ),
                    if (report.affectedCount > 0)
                      Text(
                        l10n.affectedPeople(report.affectedCount),
                        style: muted,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
