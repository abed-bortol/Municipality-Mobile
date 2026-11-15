import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';

void main() {
  test('Cluster.fromJson normalizes a server document like toCluster()', () {
    final cluster = Cluster.fromJson({
      '_id': 'c1',
      'clusterCode': 'CLU-001',
      'categoryName': 'Water Contamination',
      'district': 'Al-Mina',
      'centroid': {'lat': '34.45', 'lng': 35.81},
      'reportIds': [
        {'_id': 'r1', 'reportNumber': 'TRP-1'},
        'r2',
      ],
      'reportCount': 2,
      'totalAffected': 40,
      'riskLevel': 'HIGH',
      'detectedAt': '2026-11-01T10:00:00.000Z',
      'status': 'INVESTIGATING',
    });

    expect(cluster.id, 'c1');
    expect(cluster.lat, 34.45);
    expect(cluster.lng, 35.81);
    expect(cluster.reportNumbers, ['TRP-1']);
    expect(cluster.riskLevel, RiskLevel.high);
    expect(cluster.status, ClusterStatus.investigating);
    expect(cluster.radiusMeters, 1000);
    expect(cluster.timeWindowHours, 72);
  });

  test('missing or unknown values fall back to defaults', () {
    final cluster = Cluster.fromJson({
      'id': 'c2',
      'riskLevel': 'EXTREME',
      'status': 'ARCHIVED',
    });

    expect(cluster.lat, 0);
    expect(cluster.reportNumbers, isEmpty);
    expect(cluster.riskLevel, RiskLevel.medium);
    expect(cluster.status, ClusterStatus.active);
    expect(ClusterStatus.contained.apiValue, 'CONTAINED');
  });
}
