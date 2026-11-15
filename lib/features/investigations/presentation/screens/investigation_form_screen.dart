import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/features/investigations/presentation/investigations_providers.dart';
import 'package:municipality/features/investigations/presentation/widgets/investigation_labels.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website InvestigationModal: the field investigation record of a report.
/// Saving a draft of a VERIFIED report opens the investigation; finalizing
/// resolves the report.
class InvestigationFormScreen extends ConsumerWidget {
  const InvestigationFormScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(reportDetailsProvider(reportId));
    final existing = ref.watch(reportInvestigationProvider(reportId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.investigationRecordTitle)),
      body: switch ((report, existing)) {
        (AsyncValue(value: final Report r), AsyncData(:final value)) =>
          _InvestigationForm(report: r, existing: value),
        (AsyncError(), _) || (_, AsyncError()) => Center(
            child: LoadErrorView(onRetry: () {
              ref
                ..invalidate(reportDetailsProvider(reportId))
                ..invalidate(investigationsProvider);
            }),
          ),
        _ => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Skeleton(height: 80),
              SizedBox(height: 16),
              Skeleton(height: 56),
              SizedBox(height: 16),
              Skeleton(height: 140),
            ],
          ),
      },
    );
  }
}

class _InvestigationForm extends ConsumerStatefulWidget {
  const _InvestigationForm({required this.report, required this.existing});

  final Report report;
  final Investigation? existing;

  @override
  ConsumerState<_InvestigationForm> createState() => _InvestigationFormState();
}

class _InvestigationFormState extends ConsumerState<_InvestigationForm> {
  static const _defaultSamples =
      'Water/swab sample sent to North Lebanon Central Laboratory';

  final _formKey = GlobalKey<FormState>();
  late final _findings =
      TextEditingController(text: widget.existing?.findings ?? '');
  late final _actions =
      TextEditingController(text: widget.existing?.actionsTaken ?? '');
  late final _recommendations =
      TextEditingController(text: widget.existing?.recommendations ?? '');
  late final _samples = TextEditingController(
      text: widget.existing?.samplesCollected ?? _defaultSamples);
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late InvestigationResult _result =
      widget.existing?.result ?? InvestigationResult.resolved;
  late InvestigationStatus _status =
      widget.existing?.status == InvestigationStatus.pending
          ? InvestigationStatus.pending
          : InvestigationStatus.inProgress;

  bool _saving = false;
  String? _error;

  Report get _report => widget.report;

  bool get _isLocked =>
      _report.status == ReportStatus.resolved ||
      _report.status == ReportStatus.closed;

  bool get _canFinalize =>
      _report.status == ReportStatus.verified ||
      _report.status == ReportStatus.inInvestigation;

  @override
  void dispose() {
    for (final c in [_findings, _actions, _recommendations, _samples, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  InvestigationDraft get _draft => InvestigationDraft(
        findings: _findings.text.trim(),
        actionsTaken: _actions.text.trim(),
        recommendations: _recommendations.text.trim(),
        result: _result,
        samplesCollected: _samples.text.trim(),
        notes: _notes.text.trim(),
        status: _status,
      );

  Future<void> _save() {
    final l10n = context.l10n;
    return _run(() async {
      await ref
          .read(investigationActionsProvider.notifier)
          .save(_report, _draft, existing: widget.existing);
      return _isLocked
          ? l10n.investigationUpdated(_report.reportNumber)
          : l10n.draftSaved(_report.reportNumber);
    });
  }

  Future<void> _finalize() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finalizeConfirmTitle),
        content: Text(l10n.finalizeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.finalizeShort),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref
          .read(investigationActionsProvider.notifier)
          .finalize(_report, _draft);
      return l10n.inspectionFinalized(_report.reportNumber);
    });
  }

  /// Validates, runs [action], shows its message and returns to the report.
  Future<void> _run(Future<String> Function() action) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      showAppSnackBar(await action());
      if (!mounted) return;
      context.canPop()
          ? context.pop()
          : context.go(AppRoutes.reportDetails(_report.id));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorMessage(e, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    InputDecoration field(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
          hintMaxLines: 3,
          alignLabelWithHint: true,
        );

    return Form(
      key: _formKey,
      // Not a lazy ListView: off-screen fields must stay mounted to validate.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.relatedReport(_report.reportNumber),
                style: textTheme.labelLarge?.copyWith(
                    color: AppColors.teal300, fontWeight: FontWeight.w700)),
            Text(_report.title,
                style:
                    textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.fact_check_outlined,
              color: AppColors.teal300,
              title: l10n.oneWayInspectionTitle,
              body: l10n.oneWayInspectionBody,
            ),
            if (_isLocked) ...[
              const SizedBox(height: 8),
              _Notice(
                icon: Icons.lock_outline,
                color: const Color(0xFF34D399),
                body: l10n.inspectionLocked(
                    l10n.statusLabel(_report.status.apiValue)),
              ),
            ],
            const SizedBox(height: 16),
            ErrorBanner(message: _error),
            DropdownButtonFormField<InvestigationResult>(
              initialValue: _result,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: '${l10n.investigationResult} *',
                prefixIcon: const Icon(Icons.rule),
              ),
              items: [
                for (final r in InvestigationResult.values)
                  DropdownMenuItem(value: r, child: Text(r.label(l10n))),
              ],
              onChanged:
                  _saving ? null : (value) => setState(() => _result = value!),
            ),
            if (!_isLocked) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<InvestigationStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '${l10n.lifecycleStatus} *',
                  prefixIcon: const Icon(Icons.timelapse),
                ),
                // Completing happens only through "Finalize".
                items: [
                  for (final s in const [
                    InvestigationStatus.inProgress,
                    InvestigationStatus.pending,
                  ])
                    DropdownMenuItem(value: s, child: Text(s.label(l10n))),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _status = value!),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _findings,
              enabled: !_saving,
              minLines: 3,
              maxLines: 8,
              decoration:
                  field('${l10n.fieldFindings} *', hint: l10n.findingsHint),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? l10n.errFindingsRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actions,
              enabled: !_saving,
              minLines: 3,
              maxLines: 8,
              decoration: field('${l10n.containmentActions} *',
                  hint: l10n.actionsHint),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.errActionsRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recommendations,
              enabled: !_saving,
              minLines: 2,
              maxLines: 6,
              decoration:
                  field(l10n.officialDirective, hint: l10n.directiveHint),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _samples,
              enabled: !_saving,
              decoration: field(l10n.samplesLabel, hint: l10n.samplesHint)
                  .copyWith(prefixIcon: const Icon(Icons.science_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              enabled: !_saving,
              minLines: 2,
              maxLines: 4,
              decoration: field(l10n.notesLabel),
            ),
            const SizedBox(height: 20),
            if (_canFinalize) ...[
              PrimaryButton(
                label: l10n.finalizeAndResolve,
                icon: Icons.verified_outlined,
                loading: _saving,
                loadingLabel: l10n.saving,
                onPressed: _finalize,
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isLocked ? l10n.saveChanges : l10n.saveProgress),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.body,
    this.title,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!,
                      style: textTheme.labelLarge?.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                Text(body,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.slate300, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
