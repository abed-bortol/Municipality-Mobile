import 'package:municipality/features/clusters/data/clusters_repository.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clusters_providers.g.dart';

/// Cluster scan and status changes. Both throw `ApiException`; on success
/// the cluster list and the dashboard counters are refreshed.
@Riverpod(keepAlive: true)
class ClusterActions extends _$ClusterActions {
  @override
  void build() {}

  /// Runs the server's detection and returns the clusters it found.
  Future<List<Cluster>> detect() async {
    final clusters = await ref.read(clustersRepositoryProvider).detect();
    _refresh();
    return clusters;
  }

  Future<void> updateStatus(Cluster cluster, ClusterStatus status) async {
    await ref.read(clustersRepositoryProvider).updateStatus(cluster.id, status);
    _refresh();
  }

  void _refresh() => ref
    ..invalidate(activeClustersProvider)
    ..invalidate(dashboardStatsProvider);
}
