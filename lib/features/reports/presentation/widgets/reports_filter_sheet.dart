import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/categories/data/categories_repository.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

/// Bottom sheet with the website's four filter dropdowns. Changes apply
/// immediately; the list behind updates live.
Future<void> showReportsFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _FilterSheet(),
    );

/// Score bands shown next to each risk level, as on the website.
const _riskRanges = {
  RiskLevel.critical: '76-100',
  RiskLevel.high: '51-75',
  RiskLevel.medium: '26-50',
  RiskLevel.low: '0-25',
};

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(reportsFilterControllerProvider);
    final controller = ref.read(reportsFilterControllerProvider.notifier);
    final categories = ref.watch(activeCategoriesProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.filters,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _Dropdown<String>(
              label: l10n.category,
              allLabel: l10n.allCategories,
              value: filter.category,
              items: {for (final c in categories) c.name: l10n.categoryName(c.name)},
              onChanged: controller.setCategory,
            ),
            _Dropdown<String>(
              label: l10n.district,
              allLabel: l10n.allDistricts,
              value: filter.district,
              items: {for (final d in tripoliDistricts) d: l10n.districtName(d)},
              onChanged: controller.setDistrict,
            ),
            _Dropdown<RiskLevel>(
              label: l10n.riskLevel,
              allLabel: l10n.allRisks,
              value: filter.riskLevel,
              items: {
                for (final MapEntry(key: level, value: range)
                    in _riskRanges.entries)
                  level: '${l10n.riskLabel(level.apiValue)} ($range)',
              },
              onChanged: controller.setRiskLevel,
            ),
            _Dropdown<ReportStatus>(
              label: l10n.status,
              allLabel: l10n.allStatuses,
              value: filter.status,
              items: {
                for (final s in ReportStatus.values)
                  s: l10n.statusLabel(s.apiValue),
              },
              onChanged: controller.setStatus,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        filter.activeCount > 0 ? controller.clearFilters : null,
                    child: Text(l10n.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.showResults),
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

/// Dropdown with an "All ..." entry that maps to null.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T?>(
        // Rebuild when cleared from outside.
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(value: null, child: Text(allLabel)),
          for (final MapEntry(:key, value: text) in items.entries)
            DropdownMenuItem(
              value: key,
              child: Text(text, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
