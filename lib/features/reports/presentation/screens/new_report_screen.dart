import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/categories/data/categories_repository.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:municipality/features/reports/domain/new_report_request.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/risk_estimate.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/presentation/widgets/risk_breakdown_card.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website ReportFormModal as a screen, with the live risk estimate.
/// The location is the city centre until the map picker (map phase).
class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  static const _maxAffected = 500;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _imageUrl = TextEditingController();
  final _remarks = TextEditingController();
  final _affectedText = TextEditingController(text: '1');

  HazardCategory? _category;
  RiskLevel _severity = RiskLevel.medium;
  late String _district = _initialDistrict();
  int _affected = 1;
  bool _submitting = false;
  bool _dirty = false;
  String? _error;

  String _initialDistrict() {
    final auth = ref.read(authControllerProvider).value;
    final home = auth is Authenticated ? auth.user.district : null;
    return tripoliDistricts.contains(home) ? home! : tripoliDistricts.first;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _address,
      _imageUrl,
      _remarks,
      _affectedText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAffected(int value) {
    final clamped = value.clamp(1, _maxAffected);
    setState(() {
      _affected = clamped;
      _dirty = true;
    });
    if (_affectedText.text != '$clamped') _affectedText.text = '$clamped';
  }

  Future<void> _submit(List<HazardCategory> categories) async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final category = _category ?? categories.firstOrNull;
    if (category == null) {
      setState(() => _error = l10n.errCategoryRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(reportActionsProvider.notifier)
          .create(
            NewReportRequest(
              category: ReportCategory(
                name: category.name,
                code: category.code,
              ),
              title: _title.text.trim(),
              description: _description.text.trim(),
              incidentDate: DateTime.now().toUtc(),
              location: ReportLocation(
                address: _address.text.trim(),
                district: _district,
                lat: tripoliCenter.lat,
                lng: tripoliCenter.lng,
              ),
              affectedCount: _affected,
              initialSeverity: _severity,
              imageUrl: _imageUrl.text.trim().isEmpty
                  ? null
                  : _imageUrl.text.trim(),
              additionalComments: _remarks.text.trim(),
            ),
          );
      showAppSnackBar(
        l10n.reportCreated(
          created.reportNumber,
          created.riskScore.round(),
          l10n.riskLabel(created.riskLevel.apiValue),
        ),
      );
      if (mounted) context.go(AppRoutes.reportDetails(created.id));
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = apiErrorMessage(e, l10n);
        });
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.discardReportTitle),
            content: Text(l10n.discardReportBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.discard),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(activeCategoriesProvider);
    final list = categories.value ?? const <HazardCategory>[];
    final category = _category ?? list.firstOrNull;

    return PopScope(
      canPop: !_dirty || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.submitIncident)),
        body: switch (categories) {
          AsyncError() when !categories.hasValue => Center(
            child: LoadErrorView(
              onRetry: () => ref.invalidate(activeCategoriesProvider),
            ),
          ),
          AsyncValue(hasValue: false) => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Skeleton(height: 56),
              SizedBox(height: 16),
              Skeleton(height: 56),
              SizedBox(height: 16),
              Skeleton(height: 120),
            ],
          ),
          _ => Form(
            key: _formKey,
            onChanged: () {
              if (!_dirty) setState(() => _dirty = true);
            },
            // Not a lazy ListView: fields scrolled out of view must stay
            // mounted, or Form.validate() would skip them.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.submitReportTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.submitReportSubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate400),
                  ),
                  const SizedBox(height: 16),
                  ErrorBanner(message: _error),
                  DropdownButtonFormField<HazardCategory>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${l10n.category} *',
                      prefixIcon: const Icon(Icons.category_outlined),
                      helperText: (category?.description.isEmpty ?? true)
                          ? null
                          : category!.description,
                      helperMaxLines: 3,
                    ),
                    items: [
                      for (final c in list)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            l10n.categoryName(c.name),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.errCategoryRequired : null,
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 16),
                  _Label('${l10n.initialSeverity} *'),
                  const SizedBox(height: 6),
                  SegmentedButton<RiskLevel>(
                    showSelectedIcon: false,
                    segments: [
                      for (final level in RiskLevel.values)
                        ButtonSegment(
                          value: level,
                          label: Text(
                            l10n.riskLabel(level.apiValue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    selected: {_severity},
                    onSelectionChanged: _submitting
                        ? null
                        : (selection) => setState(() {
                            _severity = selection.first;
                            _dirty = true;
                          }),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? RiskBadge.colorOf(
                                _severity,
                              ).withValues(alpha: 0.25)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    enabled: !_submitting,
                    maxLength: 150,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '${l10n.incidentTitle} *',
                      hintText: l10n.incidentTitleHint,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.errTitleRequired
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: '${l10n.detailedDescription} *',
                      hintText: l10n.descriptionHint,
                      hintMaxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value ?? '').trim().length < 15
                        ? l10n.errDescriptionShort
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _district,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${l10n.tripoliDistrict} *',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      for (final d in tripoliDistricts)
                        DropdownMenuItem(
                          value: d,
                          child: Text(l10n.districtName(d)),
                        ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _district = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _address,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '${l10n.streetAddress} *',
                      hintText: l10n.addressHint,
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.errAddressRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _Label(l10n.affectedPeopleLabel),
                  const SizedBox(height: 6),
                  _AffectedField(
                    controller: _affectedText,
                    value: _affected,
                    max: _maxAffected,
                    enabled: !_submitting,
                    onChanged: _setAffected,
                  ),
                  const SizedBox(height: 16),
                  _LiveEstimate(
                    categoryName: category?.name ?? '',
                    severity: _severity,
                    affected: _affected,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrl,
                    enabled: !_submitting,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.evidencePhoto,
                      hintText: 'https://example.com/photo-proof.jpg',
                      prefixIcon: const Icon(Icons.photo_camera_outlined),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return null;
                      final uri = Uri.tryParse(text);
                      final ok =
                          uri != null &&
                          (uri.scheme == 'http' || uri.scheme == 'https') &&
                          uri.host.isNotEmpty;
                      return ok ? null : l10n.errUrlInvalid;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarks,
                    enabled: !_submitting,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: l10n.additionalRemarks,
                      hintText: l10n.remarksHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.submitReport,
                    loadingLabel: l10n.submittingReport,
                    icon: Icons.send,
                    loading: _submitting,
                    onPressed: () => _submit(list),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AppColors.slate300,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Number field with -/+ buttons (1..max).
class _AffectedField extends StatelessWidget {
  const _AffectedField({
    required this.controller,
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: l10n.decrease,
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.groups_outlined),
              semanticCounterText: l10n.affectedPeopleLabel,
            ),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: l10n.increase,
          onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Live score from the ported risk engine, recomputed on every change.
class _LiveEstimate extends ConsumerWidget {
  const _LiveEstimate({
    required this.categoryName,
    required this.severity,
    required this.affected,
  });

  final String categoryName;
  final RiskLevel severity;
  final int affected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final estimate = estimateRisk(
      categoryName: categoryName,
      severity: severity,
      affectedCount: affected,
      lat: tripoliCenter.lat,
      lng: tripoliCenter.lng,
      nearby: ref.watch(reportsProvider).value?.reports ?? const [],
    );

    return SectionCard(
      title: l10n.realTimeRiskScore,
      subtitle: l10n.riskEstimateHint,
      icon: Icons.speed,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.scoreOutOf(estimate.score),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: RiskBadge.colorOf(estimate.level),
            ),
          ),
          RiskBadge(level: estimate.level),
        ],
      ),
      child: RiskFactorBars(factors: estimate.factors, level: estimate.level),
    );
  }
}
