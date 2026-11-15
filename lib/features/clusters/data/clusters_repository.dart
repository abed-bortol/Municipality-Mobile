import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clusters_repository.g.dart';

@Riverpod(keepAlive: true)
ClustersRepository clustersRepository(Ref ref) =>
    ClustersRepository(ref.watch(dioProvider));

/// `/api/clusters` (server/src/routes/cluster.routes.js). Staff only.
class ClustersRepository {
  ClustersRepository(this._dio);

  final Dio _dio;

  /// Clusters that are not resolved yet.
  Future<List<Cluster>> getClusters() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>('/clusters');
    return jsonList(res.data, 'clusters').map(Cluster.fromJson).toList();
  });

  /// Runs the detection algorithm on recent reports.
  Future<List<Cluster>> detect() => apiCall(() async {
    final res = await _dio.post<Map<String, dynamic>>('/clusters/detect');
    return jsonList(res.data, 'clusters').map(Cluster.fromJson).toList();
  });

  Future<Cluster> updateStatus(String id, ClusterStatus status) =>
      apiCall(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/clusters/$id/status',
          data: {'status': status.apiValue},
        );
        return Cluster.fromJson(jsonObject(res.data, 'cluster'));
      });
}
