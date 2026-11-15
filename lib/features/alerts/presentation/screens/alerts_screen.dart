import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/utils/date_format.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/alerts/presentation/alerts_providers.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:municipality/l10n/l10n.dart';

const _amber = Color(0xFFFBBF24);

/// Website AlertsFeed: surveillance alerts with status filter and the
/// acknowledge / resolve / inspect actions (staff only).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  /// Null shows every alert.
  AlertStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alerts = ref.watch(alertsProvider);
    final all = alerts.value ?? const <Alert>[];
    final shown = [
      for (final a in all)
        if (_filter == null || a.status == _filter) a,
    ];
    int count(AlertStatus s) => all.where((a) => a.status == s).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.surveillanceAlerts),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(alertsProvider.future).then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverList.list(children: [
                Text(l10n.alertsFeedTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(l10n.alertsFeedSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate400)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(l10n.allAlertsCount(all.length), null,
                          AppColors.teal600),
                      _chip(l10n.activeAlertsCount(count(AlertStatus.active)),
                          AlertStatus.active, AppColors.rose400),
                      _chip(l10n.alertStatusAcknowledged,
                          AlertStatus.acknowledged, _amber),
                      _chip(l10n.alertStatusResolved, AlertStatus.resolved,
                          AppColors.teal600),
                    ],
                  ),
                ),
              ]),
            ),
            switch (alerts) {
              AsyncValue(hasValue: true) when shown.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.notifications_off_outlined,
                    message: l10n.noAlertsForFilter,
                  ),
                ),
              AsyncValue(hasValue: true) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AlertCard(alert: shown[i]),
                  ),
                ),
              AsyncError() => SliverToBoxAdapter(
                  child: LoadErrorView(
                      onRetry: () => ref.invalidate(alertsProvider)),
                ),
              _ => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const Skeleton(height: 150),
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, AlertStatus? status, Color color) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == status,
          onSelected: (_) => setState(() => _filter = status),
          selectedColor: color.withValues(alpha: 0.35),
          showCheckmark: false,
        ),
      );
}

class _AlertCard extends ConsumerStatefulWidget {
  const _AlertCard({required this.alert});

  final Alert alert;

  @override
  ConsumerState<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends ConsumerState<_AlertCard> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(AlertActions actions) action,
    String success,
  ) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action(ref.read(alertActionsProvider.notifier));
      showAppSnackBar(success);
    } catch (e) {
      showAppSnackBar(apiErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acknowledge() {
    final name = switch (ref.read(authControllerProvider).value) {
      Authenticated(:final user) => user.name,
      _ => '',
    };
    return _run((a) => a.acknowledge(widget.alert),
        context.l10n.alertAcknowledgedBy(name));
  }

  Future<void> _resolve() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resolveAlertTitle),
        content: Text(l10n.resolveAlertBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resolve),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run((a) => a.resolve(widget.alert), l10n.alertResolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final alert = widget.alert;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.slate400);

    final (Color border, Color statusColor, String statusLabel) =
        switch (alert.status) {
      AlertStatus.active => (
          AppColors.rose400.withValues(alpha: 0.5),
          AppColors.rose400,
          l10n.alertStatusActive,
        ),
      AlertStatus.acknowledged => (
          _amber.withValues(alpha: 0.35),
          _amber,
          l10n.alertStatusAcknowledged,
        ),
      AlertStatus.resolved => (
          AppColors.slate700,
          AppColors.teal300,
          l10n.alertStatusResolved,
        ),
    };
    final reportId = alert.relatedReportId;

    return Opacity(
      opacity: alert.status == AlertStatus.resolved ? 0.8 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              if (alert.status == AlertStatus.active)
                const Color(0xFF4C0519).withValues(alpha: 0.4)
              else
                AppColors.slate800.withValues(alpha: 0.4),
              AppColors.slate800.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Pill(label: alert.alertCode, color: AppColors.slate300),
                RiskBadge(level: alert.riskLevel),
                Pill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(alert.title,
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(alert.description,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate300, height: 1.45)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Meta(
                    icon: Icons.place_outlined,
                    text: l10n.districtName(alert.area),
                    style: muted),
                _Meta(
                    icon: Icons.badge_outlined,
                    text: alert.assignedOfficer ?? l10n.unassigned,
                    style: muted),
                if (alert.createdAt != null)
                  _Meta(
                      icon: Icons.schedule,
                      text: context.formatDateTime(alert.createdAt!),
                      style: muted),
              ],
            ),
            if (alert.status != AlertStatus.resolved || reportId != null) ...[
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (alert.status == AlertStatus.active)
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _acknowledge,
                      icon: const Icon(Icons.task_alt, size: 18),
                      label: Text(l10n.acknowledge),
                    ),
                  if (alert.status != AlertStatus.resolved)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _resolve,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(l10n.resolve),
                    ),
                  if (reportId != null)
                    TextButton.icon(
                      onPressed: () =>
                          context.go(AppRoutes.reportDetails(reportId)),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(l10n.inspect),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal400),
          const SizedBox(width: 4),
          Text(text, style: style),
        ],
      );
}
