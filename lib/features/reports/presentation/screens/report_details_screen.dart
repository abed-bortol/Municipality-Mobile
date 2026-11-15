import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/presentation/widgets/report_status_badge.dart';
import 'package:municipality/features/reports/presentation/widgets/report_workflow_card.dart';
import 'package:municipality/features/reports/presentation/widgets/risk_breakdown_card.dart';
import 'package:municipality/features/reports/presentation/widgets/status_history_card.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website ReportDetailsModal as a full screen: incident facts, the staff
/// workflow, the risk score breakdown and the audit trail.
class ReportDetailsScreen extends ConsumerWidget {
  const ReportDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(reportDetailsProvider(id));
    final report = details.value;
    final isStaff = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.role != UserRole.citizen,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(title: Text(report?.reportNumber ?? '')),
      body: switch (details) {
        AsyncValue(hasValue: true) => RefreshIndicator(
            onRefresh: () => ref
                .refresh(reportDetailsProvider(id).future)
                .then((_) {}, onError: (_) {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(report: report!),
                const SizedBox(height: 12),
                _Facts(report: report),
                const SizedBox(height: 12),
                _Description(report: report),
                if (isStaff) ...[
                  const SizedBox(height: 12),
                  ReportWorkflowCard(report: report),
                ],
                const SizedBox(height: 12),
                RiskBreakdownCard(report: report),
                const SizedBox(height: 12),
                StatusHistoryCard(history: report.statusHistory),
                const SizedBox(height: 12),
                Text(
                  context.l10n.coordinates(
                    report.location.lat.toStringAsFixed(5),
                    report.location.lng.toStringAsFixed(5),
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
        AsyncError() => Center(
            child: LoadErrorView(
                onRetry: () => ref.invalidate(reportDetailsProvider(id))),
          ),
        _ => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Skeleton(height: 120, radius: 16),
              SizedBox(height: 12),
              Skeleton(height: 150, radius: 16),
              SizedBox(height: 12),
              Skeleton(height: 200, radius: 16),
            ],
          ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final date = report.incidentDate ?? report.createdAt;

    return DecoratedBox(
      decoration: panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ReportStatusBadge(status: report.status),
                RiskBadge(level: report.riskLevel),
                Pill(
                  label: l10n.categoryName(report.category.name),
                  color: AppColors.teal300,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: Text(report.title,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(l10n.reportedOn(context.formatDateTime(date)),
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.slate400)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TwoColumnGrid(
      spacing: 8,
      children: [
        _Fact(
          icon: Icons.place_outlined,
          label: l10n.districtArea,
          value: l10n.districtName(report.location.district),
        ),
        _Fact(
          icon: Icons.groups_outlined,
          label: l10n.estimatedAffected,
          value: l10n.peopleCount(report.affectedCount),
        ),
        _Fact(
          icon: Icons.badge_outlined,
          label: l10n.assignedOfficer,
          value: report.assignedOfficer?.name ?? l10n.unassigned,
        ),
        _Fact(
          icon: Icons.person_outline,
          label: l10n.reporter,
          value: report.citizen.name.isEmpty ? '–' : report.citizen.name,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: DecoratedBox(
        decoration: panelDecoration,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.teal400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label,
                        style: textTheme.labelSmall
                            ?.copyWith(color: AppColors.slate400)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(value,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final body =
        textTheme.bodyMedium?.copyWith(color: AppColors.slate300, height: 1.5);
    final label = textTheme.labelMedium
        ?.copyWith(color: AppColors.slate400, fontWeight: FontWeight.w600);
    final imageUrl = report.imageUrl;

    return SectionCard(
      title: l10n.descriptionLabel,
      icon: Icons.notes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(report.description, style: body),
          if (report.location.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.streetAddress, style: label),
            const SizedBox(height: 2),
            Text(report.location.address, style: body),
          ],
          if (report.additionalComments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.additionalRemarks, style: label),
            const SizedBox(height: 2),
            Text(report.additionalComments, style: body),
          ],
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            Text(l10n.evidencePhotoTitle, style: label),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                semanticLabel: l10n.evidencePhotoTitle,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Skeleton(height: 180),
                errorBuilder: (context, _, _) => Container(
                  height: 80,
                  color: AppColors.slate800,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.slate500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
