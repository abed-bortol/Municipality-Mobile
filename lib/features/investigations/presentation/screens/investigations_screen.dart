import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/features/investigations/presentation/investigations_providers.dart';
import 'package:municipality/features/investigations/presentation/widgets/investigation_labels.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website InvestigationsView: field investigation dossiers filtered by
/// result, with shortcuts to finalize and to the linked report.
class InvestigationsScreen extends ConsumerStatefulWidget {
  const InvestigationsScreen({super.key});

  @override
  ConsumerState<InvestigationsScreen> createState() =>
      _InvestigationsScreenState();
}

class _InvestigationsScreenState extends ConsumerState<InvestigationsScreen> {
  /// Null shows every result.
  InvestigationResult? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final investigations = ref.watch(investigationsProvider);
    final all = investigations.value ?? const <Investigation>[];
    final shown = [
      for (final i in all)
        if (_filter == null || i.result == _filter) i,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.investigations)),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(investigationsProvider.future)
            .then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverList.list(children: [
                Text(l10n.investigationsTitle,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(l10n.investigationsDesc,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.slate400)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _chip(l10n.allResultsCount(all.length), null),
                    for (final r in InvestigationResult.values)
                      _chip(r.label(l10n), r),
                  ]),
                ),
              ]),
            ),
            switch (investigations) {
              AsyncValue(hasValue: true) when shown.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.biotech_outlined,
                    message: l10n.noInvestigationsTitle,
                    hint: l10n.noInvestigationsBody,
                  ),
                ),
              AsyncValue(hasValue: true) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _InvestigationCard(investigation: shown[i]),
                  ),
                ),
              AsyncError() => SliverToBoxAdapter(
                  child: LoadErrorView(
                      onRetry: () => ref.invalidate(investigationsProvider)),
                ),
              _ => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, _) => const Skeleton(height: 220),
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, InvestigationResult? result) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == result,
          onSelected: (_) => setState(() => _filter = result),
          selectedColor:
              (result?.color ?? AppColors.teal600).withValues(alpha: 0.35),
          showCheckmark: false,
        ),
      );
}

class _InvestigationCard extends StatelessWidget {
  const _InvestigationCard({required this.investigation});

  final Investigation investigation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final inv = investigation;
    final heading = textTheme.labelMedium
        ?.copyWith(color: AppColors.teal300, fontWeight: FontWeight.w700);
    final body =
        textTheme.bodySmall?.copyWith(color: AppColors.slate300, height: 1.45);

    Widget section(String title, String text) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: heading),
              const SizedBox(height: 2),
              Text(text, style: body),
            ],
          ),
        );

    return DecoratedBox(
      decoration: panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.investigationCode,
                          style: textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(l10n.reportRef(inv.reportNumber),
                          style: textTheme.labelSmall
                              ?.copyWith(color: AppColors.slate400)),
                    ],
                  ),
                ),
                Pill(label: inv.result.label(l10n), color: inv.result.color),
              ],
            ),
            if (inv.reportTitle != null) ...[
              const SizedBox(height: 6),
              Text(inv.reportTitle!,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
            if (inv.findings.isNotEmpty) section(l10n.fieldFindings, inv.findings),
            if (inv.actionsTaken.isNotEmpty)
              section(l10n.containmentActions, inv.actionsTaken),
            if (inv.recommendations.isNotEmpty)
              section(l10n.officialDirective, inv.recommendations),
            if (inv.samplesCollected.isNotEmpty)
              section(l10n.samplesLabel, inv.samplesCollected),
            const Divider(height: 24),
            Text(
              [
                '${l10n.fieldOfficer}: ${inv.officerName}'
                    '${inv.officerBadge.isEmpty ? '' : ' (${inv.officerBadge})'}',
                inv.status.label(l10n),
                if (inv.investigationDate != null)
                  context.formatDate(inv.investigationDate!),
              ].join(' • '),
              style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inv.reportStatus == ReportStatus.inInvestigation)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.go(AppRoutes.reportInvestigation(inv.reportId)),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(l10n.finalizeShort),
                  ),
                if (inv.reportId.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.reportDetails(inv.reportId)),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l10n.inspectLinkedIncident),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
