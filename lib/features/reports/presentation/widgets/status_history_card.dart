import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/widgets/report_status_badge.dart';
import 'package:municipality/l10n/l10n.dart';

/// Audit trail of status changes, oldest first, as a vertical timeline.
class StatusHistoryCard extends StatelessWidget {
  const StatusHistoryCard({super.key, required this.history});

  final List<StatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.slate400);

    return SectionCard(
      title: l10n.auditTrailTitle,
      icon: Icons.history,
      child: history.isEmpty
          ? EmptyState(icon: Icons.history_toggle_off, message: l10n.noHistory)
          : Column(
              children: [
                for (final (i, entry) in history.indexed)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Rail(
                          color: ReportStatusBadge.colorOf(
                              _status(entry.newStatus)),
                          isLast: i == history.length - 1,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.statusLabel(entry.newStatus),
                                    style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  [
                                    if (entry.changedBy.isNotEmpty)
                                      entry.changedBy,
                                    if (entry.role.isNotEmpty)
                                      l10n.roleLabel(entry.role),
                                    if (entry.timestamp != null)
                                      context.formatDateTime(entry.timestamp!),
                                  ].join(' • '),
                                  style: muted,
                                ),
                                if (entry.comment.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(entry.comment,
                                      style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.slate300)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static ReportStatus _status(String api) => ReportStatus.values.firstWhere(
        (s) => s.apiValue == api,
        orElse: () => ReportStatus.submitted,
      );
}

class _Rail extends StatelessWidget {
  const _Rail({required this.color, required this.isLast});

  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(width: 2, color: AppColors.slate700),
            ),
        ],
      ),
    );
  }
}
