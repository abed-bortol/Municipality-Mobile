import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/audit/data/audit_repository.dart';
import 'package:municipality/features/audit/domain/audit_log.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website AuditLogsView search: user, action, resource or details.
List<AuditLog> filterAuditLogs(
  List<AuditLog> logs,
  String query, {
  String Function(String action)? actionLabel,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return logs;
  bool has(String s) => s.toLowerCase().contains(q);
  return [
    for (final l in logs)
      if (has(l.userName) ||
          has(l.action) ||
          has(actionLabel?.call(l.action) ?? '') ||
          has(l.resource) ||
          has(l.details))
        l,
  ];
}

/// Website AuditLogsView (administrators only).
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final logs = ref.watch(auditLogsProvider);
    final all = logs.value ?? const <AuditLog>[];
    final shown = filterAuditLogs(
      all,
      _search.text,
      actionLabel: l10n.auditActionLabel,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditTrail),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(auditLogsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(auditLogsProvider.future).then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverList.list(
                children: [
                  Text(
                    l10n.auditLogsTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.auditLogsDesc,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.searchAudit,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  if (logs.hasValue) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.auditEntriesCount(shown.length, all.length),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            switch (logs) {
              AsyncValue(hasValue: true) when shown.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.history,
                    message: l10n.noAuditEntries,
                  ),
                ),
              AsyncValue(hasValue: true) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _AuditEntry(log: shown[i]),
                ),
              ),
              AsyncError() => SliverToBoxAdapter(
                child: LoadErrorView(
                  onRetry: () => ref.invalidate(auditLogsProvider),
                ),
              ),
              _ => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, _) => const Skeleton(height: 90),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _AuditEntry extends StatelessWidget {
  const _AuditEntry({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(
                label: l10n.auditActionLabel(log.action),
                color: AppColors.slate300,
              ),
              const Spacer(),
              if (log.createdAt != null)
                Text(
                  context.formatDateTime(log.createdAt!.toLocal()),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.resource,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.teal300,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (log.details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              log.details,
              style: textTheme.bodySmall?.copyWith(color: AppColors.slate300),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${log.userName} · ${l10n.roleLabel(log.userRole)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ),
              if (log.ipAddress.isNotEmpty)
                Text(
                  l10n.ipAddress(log.ipAddress),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.slate500,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
