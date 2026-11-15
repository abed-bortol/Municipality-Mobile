import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/brand_app_bar.dart';
import 'package:municipality/core/widgets/metric_card.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:municipality/l10n/l10n.dart';

/// Website PublicPortal: community hero, city-wide counters, health
/// advisories and emergency numbers.
class PublicPortalScreen extends ConsumerWidget {
  const PublicPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: const BrandAppBar(actions: [NotificationBell()]),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(dashboardStatsProvider.future)
            .then((_) {}, onError: (_) {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Hero(),
            const SizedBox(height: 16),
            const _PublicStats(),
            const SizedBox(height: 16),
            _Advisory(
              icon: Icons.water_drop_outlined,
              color: AppColors.teal400,
              title: l10n.waterDirectiveTitle,
              intro: l10n.waterDirectiveIntro,
              tips: [l10n.waterTip1, l10n.waterTip2, l10n.waterTip3],
            ),
            const SizedBox(height: 12),
            _Advisory(
              icon: Icons.warning_amber_rounded,
              color: AppColors.rose400,
              title: l10n.foodAlertTitle,
              intro: l10n.foodAlertIntro,
              tips: [l10n.foodTip1, l10n.foodTip2, l10n.foodTip3],
            ),
            const SizedBox(height: 12),
            const _Hotlines(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.teal500.withValues(alpha: 0.3)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slate900, AppColors.teal950, AppColors.slate900],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal500.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: AppColors.teal500.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monitor_heart_outlined,
                    size: 16, color: AppColors.teal400),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l10n.portalBadge,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                          color: AppColors.teal300,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(l10n.portalTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900, height: 1.3)),
          ),
          const SizedBox(height: 10),
          Text(l10n.portalBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.slate300, height: 1.5)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.submitIncident,
            icon: Icons.add_circle_outline,
            onPressed: () => context.go(AppRoutes.newReport),
          ),
        ],
      ),
    );
  }
}

/// Public counters from `/dashboard/statistics`. The website's hard-coded
/// officer count is replaced by this week's reports.
class _PublicStats extends ConsumerWidget {
  const _PublicStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(dashboardStatsProvider).value;

    if (stats == null) {
      return TwoColumnGrid(children: [
        for (var i = 0; i < 4; i++) const Skeleton(height: 112, radius: 16),
      ]);
    }
    return TwoColumnGrid(children: [
      MetricCard(
        label: l10n.loggedIncidents,
        value: '${stats.totalReports}',
        caption: l10n.cityJurisdiction,
        icon: Icons.description_outlined,
        color: AppColors.teal400,
      ),
      MetricCard(
        label: l10n.remediatedResolved,
        value: '${stats.resolvedCount}',
        caption: l10n.successRate(stats.resolutionRate),
        icon: Icons.task_alt,
        color: const Color(0xFF34D399),
      ),
      MetricCard(
        label: l10n.reportsToday,
        value: '${stats.reportsToday}',
        caption: l10n.thisWeek(stats.reportsThisWeek),
        icon: Icons.today_outlined,
        color: const Color(0xFF22D3EE),
      ),
      MetricCard(
        label: l10n.monitoringSectors,
        value: '${tripoliDistricts.length}',
        caption: l10n.districtsCovered,
        icon: Icons.map_outlined,
        color: const Color(0xFFFBBF24),
      ),
    ]);
  }
}

class _Advisory extends StatelessWidget {
  const _Advisory({
    required this.icon,
    required this.color,
    required this.title,
    required this.intro,
    required this.tips,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String intro;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title,
                        style: textTheme.titleSmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(intro,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate300, height: 1.45)),
            const SizedBox(height: 6),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: textTheme.bodySmall?.copyWith(color: color)),
                    Expanded(
                      child: Text(tip,
                          style: textTheme.bodySmall?.copyWith(
                              color: AppColors.slate400, height: 1.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Emergency numbers; tap copies the number to dial it.
class _Hotlines extends StatelessWidget {
  const _Hotlines();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lines = [
      (l10n.directorateHotline, '06-440120'),
      (l10n.civilDefense, '125'),
      (l10n.redCross, '140'),
    ];

    return SectionCard(
      title: l10n.emergencyContacts,
      icon: Icons.phone_in_talk_outlined,
      child: Column(
        children: [
          for (final (name, number) in lines)
            Semantics(
              onTapHint: l10n.copyNumber,
              child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phone numbers read left-to-right in Arabic too.
                  Text(number,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.teal300,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 18, color: AppColors.slate400),
                ],
              ),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: number));
                showAppSnackBar(l10n.numberCopied(number));
              },
            ),
            ),
        ],
      ),
    );
  }
}
