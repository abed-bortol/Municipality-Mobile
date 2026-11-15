import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/reports/domain/reports_filter.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/features/reports/presentation/widgets/report_card.dart';
import 'package:municipality/features/reports/presentation/widgets/reports_filter_sheet.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website ReportsManagement: searchable, filterable, sortable list.
/// Staff see every report ("Report Triage"), citizens their own.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final _search = TextEditingController(
    text: ref.read(reportsFilterControllerProvider).search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final isStaff = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.role != UserRole.citizen,
      _ => false,
    };
    final filter = ref.watch(reportsFilterControllerProvider);
    final controller = ref.read(reportsFilterControllerProvider.notifier);
    final reports = ref.watch(reportsProvider);
    final all = reports.value?.reports;
    final shown = all == null
        ? null
        : filter.apply(all, districtLabel: l10n.districtName);

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? l10n.reportTriage : l10n.myReports),
        actions: [
          IconButton(
            tooltip: l10n.filters,
            onPressed: () => showReportsFilterSheet(context),
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              backgroundColor: AppColors.teal500,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.newReport),
        backgroundColor: AppColors.teal600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.submitIncident),
      ),
      body: RefreshIndicator(
        // Failures are shown in place, so the spinner just stops.
        onRefresh: () =>
            ref.refresh(reportsProvider.future).then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList.list(children: [
                TextField(
                  controller: _search,
                  onChanged: controller.setSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchReportsHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.cancel,
                            onPressed: () {
                              _search.clear();
                              controller.setSearch('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                _SortChips(selected: filter.sort, onSelected: controller.setSort),
                if (shown != null && all != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.showingReports(shown.length, all.length),
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.slate400),
                  ),
                ],
                const SizedBox(height: 10),
              ]),
            ),
            switch (reports) {
              AsyncValue(hasValue: true) when shown!.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.search_off,
                    message: l10n.noMatchingReports,
                    action: filter.activeCount > 0 || filter.search.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              _search.clear();
                              controller
                                ..setSearch('')
                                ..clearFilters();
                            },
                            child: Text(l10n.clearFilters),
                          )
                        : null,
                  ),
                ),
              AsyncValue(hasValue: true) => SliverPadding(
                  // Room for the floating button.
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: shown!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        ReportCard(report: shown[i], showRiskScore: isStaff),
                  ),
                ),
              AsyncError() => SliverToBoxAdapter(
                  child: LoadErrorView(
                      onRetry: () => ref.invalidate(reportsProvider)),
                ),
              _ => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, _) => const Skeleton(height: 110),
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  final ReportSort selected;
  final ValueChanged<ReportSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      ReportSort.risk: l10n.sortHighestRisk,
      ReportSort.date: l10n.sortMostRecent,
      ReportSort.affected: l10n.sortMostAffected,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(l10n.sortBy,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.slate400)),
          for (final MapEntry(key: sort, value: label) in labels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: sort == selected,
                onSelected: (_) => onSelected(sort),
                selectedColor: AppColors.teal600,
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}
