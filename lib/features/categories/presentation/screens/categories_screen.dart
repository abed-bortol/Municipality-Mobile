import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:municipality/features/categories/presentation/categories_admin_providers.dart';
import 'package:municipality/l10n/l10n.dart';

const _amber = Color(0xFFFBBF24);

/// Website AdminCategoryManagement: add categories and tune the risk
/// engine's base weights (administrators only).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(allCategoriesProvider);
    final active = categories.value?.where((c) => c.isActive).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCategories),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(allCategoriesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(allCategoriesProvider.future)
            .then((_) {}, onError: (_) {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.categoriesManagementTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.categoriesManagementDesc,
              style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.activeCategoriesCount(active),
              style: textTheme.labelMedium?.copyWith(color: AppColors.slate300),
            ),
            const SizedBox(height: 16),
            const _AddCategoryForm(),
            const SizedBox(height: 16),
            ...switch (categories) {
              AsyncValue(:final value?) => [
                for (final c in value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryCard(category: c),
                  ),
              ],
              AsyncError() => [
                LoadErrorView(
                  onRetry: () => ref.invalidate(allCategoriesProvider),
                ),
              ],
              _ => [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Skeleton(height: 110),
                  ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

class _AddCategoryForm extends ConsumerStatefulWidget {
  const _AddCategoryForm();

  @override
  ConsumerState<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends ConsumerState<_AddCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _weight = TextEditingController(text: '10');
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(categoryAdminActionsProvider.notifier)
          .create(
            name: _name.text,
            baseWeight: int.parse(_weight.text),
            description: _description.text,
          );
      showAppSnackBar(l10n.categoryAdded(created.name));
      _name.clear();
      _description.clear();
      _weight.text = '10';
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.addNewCategory,
      icon: Icons.add_circle_outline,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '${l10n.categoryNameLabel} *',
                hintText: l10n.categoryNameHint,
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? l10n.errCategoryNameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(labelText: l10n.baseRiskWeight),
              validator: (v) {
                final w = int.tryParse(v ?? '');
                return w == null ||
                        w < minCategoryWeight ||
                        w > maxCategoryWeight
                    ? l10n.errWeightRange
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              enabled: !_saving,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: l10n.categoryDescHint,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(l10n.addCategoryBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerStatefulWidget {
  const _CategoryCard({required this.category});

  final HazardCategory category;

  @override
  ConsumerState<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends ConsumerState<_CategoryCard> {
  bool _busy = false;

  Future<void> _run(
    Future<HazardCategory> Function(CategoryAdminActions actions) action,
    String Function(HazardCategory updated) success,
  ) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final updated = await action(
        ref.read(categoryAdminActionsProvider.notifier),
      );
      showAppSnackBar(success(updated));
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
    final c = widget.category;
    final weight = c.baseWeight.round();
    final name = l10n.categoryName(c.name);
    final (tierLabel, tierColor) = switch (WeightTier.of(weight)) {
      WeightTier.high => (l10n.tierHigh, AppColors.rose400),
      WeightTier.standard => (l10n.tierStandard, _amber),
      WeightTier.normal => (l10n.tierNormal, AppColors.teal400),
    };

    void setWeight(int value) => _run(
      (a) => a.setWeight(c, value),
      (u) => l10n.weightUpdated(l10n.categoryName(u.name)),
    );

    return Opacity(
      opacity: c.isActive ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: panelDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        c.code,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.teal400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!c.isActive)
                  Pill(label: l10n.categoryInactive, color: AppColors.slate400)
                else
                  Pill(label: tierLabel, color: tierColor),
              ],
            ),
            if (c.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                c.description,
                style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: l10n.decreaseWeight,
                  onPressed: _busy || weight <= minCategoryWeight
                      ? null
                      : () => setWeight(weight - 1),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    l10n.weightPoints(weight),
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.increaseWeight,
                  onPressed: _busy || weight >= maxCategoryWeight
                      ? null
                      : () => setWeight(weight + 1),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            // Not a SwitchListTile: its ink would hide behind the card.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.categoryAvailable,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate300,
                    ),
                  ),
                ),
                Switch(
                  value: c.isActive,
                  onChanged: _busy
                      ? null
                      : (value) => _run(
                          (a) => a.setActive(c, value),
                          (u) => value
                              ? l10n.categoryEnabled(name)
                              : l10n.categoryDisabled(name),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
