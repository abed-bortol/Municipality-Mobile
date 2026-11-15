import 'package:municipality/features/alerts/data/alerts_repository.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alerts_providers.g.dart';

/// All alerts, newest first (staff only).
@riverpod
Future<List<Alert>> alerts(Ref ref) =>
    ref.watch(alertsRepositoryProvider).getAlerts();

/// Badge on the Alerts tab; 0 while loading or on failure.
@riverpod
int activeAlertCount(Ref ref) =>
    ref
        .watch(alertsProvider)
        .value
        ?.where((a) => a.status == AlertStatus.active)
        .length ??
    0;

/// Alert status changes. Both throw `ApiException`; on success the list and
/// the dashboard's "Active Alerts" counter are refreshed.
@Riverpod(keepAlive: true)
class AlertActions extends _$AlertActions {
  @override
  void build() {}

  Future<void> acknowledge(Alert alert) =>
      _run(() => ref.read(alertsRepositoryProvider).acknowledge(alert.id));

  Future<void> resolve(Alert alert) =>
      _run(() => ref.read(alertsRepositoryProvider).resolve(alert.id));

  Future<void> _run(Future<void> Function() call) async {
    await call();
    ref
      ..invalidate(alertsProvider)
      ..invalidate(dashboardStatsProvider);
  }
}
