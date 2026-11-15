import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/report_workflow.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/presentation/widgets/report_status_badge.dart';
import 'package:municipality/features/users/data/users_repository.dart';
import 'package:municipality/features/users/domain/officer.dart';
import 'package:municipality/l10n/l10n.dart';

/// Staff controls from the website's ReportDetailsModal: stage stepper, the
/// one forward action, rejection and officer assignment.
class ReportWorkflowCard extends ConsumerStatefulWidget {
  const ReportWorkflowCard({super.key, required this.report});

  final Report report;

  @override
  ConsumerState<ReportWorkflowCard> createState() =>
      _ReportWorkflowCardState();
}

class _ReportWorkflowCardState extends ConsumerState<ReportWorkflowCard> {
  bool _busy = false;
  String? _officerId;

  Report get _report => widget.report;

  Future<void> _run(
    Future<Report> Function(ReportActions actions) action,
    String Function(Report updated) success,
  ) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final updated = await action(ref.read(reportActionsProvider.notifier));
      showAppSnackBar(success(updated));
      if (mounted) setState(() => _officerId = null);
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance(ReportStatus next, String actionLabel) async {
    final l10n = context.l10n;
    final comment = await _askText(
      title: actionLabel,
      label: l10n.statusComment,
      required: false,
    );
    if (comment == null) return;
    await _run(
      (a) => a.advance(_report, comment: comment),
      (r) => l10n.statusMoved(r.reportNumber, l10n.statusLabel(next.apiValue)),
    );
  }

  Future<void> _reject() async {
    final l10n = context.l10n;
    final reason = await _askText(
      title: l10n.rejectReport,
      label: l10n.rejectionReason,
      hint: l10n.rejectionReasonHint,
      required: true,
      destructive: true,
    );
    if (reason == null) return;
    await _run(
      (a) => a.reject(_report, reason),
      (r) => l10n.reportRejectedToast(r.reportNumber),
    );
  }

  static bool _opensInvestigation(ReportStatus status) =>
      status == ReportStatus.verified ||
      status == ReportStatus.inInvestigation;

  /// Null when cancelled.
  Future<String?> _askText({
    required String title,
    required String label,
    String? hint,
    required bool required,
    bool destructive = false,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => _TextPromptDialog(
          title: title,
          label: label,
          hint: hint,
          required: required,
          destructive: destructive,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final status = _report.status;
    final next = status.nextStep;

    final (String? hint, String? actionLabel) = switch (status) {
      ReportStatus.submitted => (l10n.nextHintSubmitted, l10n.proceedToReview),
      ReportStatus.underReview => (l10n.nextHintUnderReview, l10n.proceedToVerify),
      ReportStatus.verified =>
        (l10n.nextHintVerified, l10n.proceedToInvestigation),
      ReportStatus.inInvestigation =>
        (l10n.nextHintInInvestigation, l10n.finalizeInspection),
      ReportStatus.resolved => (l10n.nextHintResolved, l10n.closeIncidentFinal),
      _ => (null, null),
    };

    return SectionCard(
      title: l10n.workflowTitle,
      subtitle: l10n.cannotRevert,
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Stepper(status: status),
          const SizedBox(height: 12),
          if (status == ReportStatus.closed)
            _Notice(
              icon: Icons.lock_outline,
              color: AppColors.teal400,
              text: l10n.caseFinalizedClosed,
            )
          else if (status == ReportStatus.rejected)
            _Notice(
              icon: Icons.block,
              color: AppColors.rose400,
              text: '${l10n.reportRejectedTitle}\n${l10n.reportRejectedBody}',
            )
          else ...[
            Text(l10n.nextAction,
                style: textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (hint != null)
              Text(hint,
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.slate400, height: 1.4)),
            const SizedBox(height: 10),
            if (next != null && actionLabel != null)
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : _opensInvestigation(status)
                        // Launching / finalizing goes through the
                        // investigation record, like the website.
                        ? () => context
                            .go(AppRoutes.reportInvestigation(_report.id))
                        : () => _advance(next, actionLabel),
                icon: const Icon(Icons.arrow_forward),
                label: Text(actionLabel),
              ),
            if (status == ReportStatus.inInvestigation) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => context
                        .go(AppRoutes.reportInvestigation(_report.id)),
                icon: const Icon(Icons.edit_note),
                label: Text(l10n.editInspectionLog),
              ),
            ],
            if (status.canReject) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _reject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rose400,
                  side: BorderSide(
                      color: AppColors.rose400.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.block),
                label: Text(l10n.rejectReport),
              ),
            ],
          ],
          if (status.canAssign) ...[
            const Divider(height: 28),
            _AssignOfficer(
              selected: _officerId,
              enabled: !_busy,
              onSelected: (id) => setState(() => _officerId = id),
              onConfirm: (officer) => _run(
                (a) => a.assign(_report, officer.id),
                (r) => l10n.officerAssigned(officer.name, r.reportNumber),
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

/// Six stages, done ones checked, the current one highlighted.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final current = reportWorkflowSteps.indexOf(status);

    return Column(
      children: [
        for (final (i, step) in reportWorkflowSteps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  i < current
                      ? Icons.check_circle
                      : i == current
                          ? Icons.radio_button_checked
                          : Icons.lock_outline,
                  size: 18,
                  color: i < current
                      ? AppColors.teal500
                      : i == current
                          ? ReportStatusBadge.colorOf(step)
                          : AppColors.slate500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.statusLabel(step.apiValue),
                    style: textTheme.bodySmall?.copyWith(
                      color: i <= current ? Colors.white : AppColors.slate500,
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                if (i == current)
                  Text(l10n.currentStage,
                      style: textTheme.labelSmall
                          ?.copyWith(color: AppColors.teal400))
                else if (i < current)
                  Text(l10n.stageCompleted,
                      style: textTheme.labelSmall
                          ?.copyWith(color: AppColors.slate500)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _AssignOfficer extends ConsumerWidget {
  const _AssignOfficer({
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.onConfirm,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final ValueChanged<Officer> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final officers = ref.watch(officersProvider);
    final list = officers.value ?? const [];
    final chosen = list.where((o) => o.id == selected).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.assignOfficer,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (officers.hasValue && list.isEmpty)
          Text(l10n.noOfficers,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.slate400))
        else
          DropdownButtonFormField<String>(
            // Reset after a successful assignment.
            key: ValueKey(selected == null),
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(hintText: l10n.selectHealthOfficer),
            items: [
              for (final o in list)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(
                    [
                      o.name,
                      if (o.badgeNumber.isNotEmpty) o.badgeNumber,
                      if (o.district.isNotEmpty) l10n.districtName(o.district),
                    ].join(' • '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled ? onSelected : null,
          ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: enabled && chosen != null ? () => onConfirm(chosen) : null,
          child: Text(l10n.confirmAssignment),
        ),
      ],
    );
  }
}

/// Asks for a comment or reason. Pops the trimmed text, or null on cancel.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.required,
    required this.destructive,
    this.hint,
  });

  final String title;
  final String label;
  final String? hint;
  final bool required;
  final bool destructive;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _text.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _text,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            alignLabelWithHint: true,
          ),
          validator: (value) => widget.required && (value ?? '').trim().isEmpty
              ? l10n.errReasonRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.rose400,
                  foregroundColor: AppColors.slate950,
                )
              : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
