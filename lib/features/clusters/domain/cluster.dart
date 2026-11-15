import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'cluster.freezed.dart';
part 'cluster.g.dart';

/// Lifecycle of a detected cluster (`CLUSTER_STATUSES` on the server).
enum ClusterStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INVESTIGATING')
  investigating,
  @JsonValue('CONTAINED')
  contained,
  @JsonValue('RESOLVED')
  resolved;

  String get apiValue => _$ClusterStatusEnumMap[this]!;
}

/// Geographic cluster of similar reports, normalized like `toCluster()` in
/// the website's `utils/normalize.ts`.
@freezed
abstract class Cluster with _$Cluster {
  const factory Cluster({
    @JsonKey(readValue: readId) required String id,
    @Default('') String clusterCode,
    @Default('') String categoryName,
    @Default('') String district,
    @JsonKey(readValue: _readLat) @Default(0) double lat,
    @JsonKey(readValue: _readLng) @Default(0) double lng,
    @Default(1000) double radiusMeters,
    @JsonKey(readValue: _readReportNumbers)
    @Default(<String>[])
    List<String> reportNumbers,
    @Default(0) int reportCount,
    @Default(0) int totalAffected,
    @JsonKey(unknownEnumValue: RiskLevel.medium)
    @Default(RiskLevel.medium)
    RiskLevel riskLevel,
    @Default(72) int timeWindowHours,
    DateTime? detectedAt,
    @JsonKey(unknownEnumValue: ClusterStatus.active)
    @Default(ClusterStatus.active)
    ClusterStatus status,
  }) = _Cluster;

  factory Cluster.fromJson(Map<String, dynamic> json) =>
      _$ClusterFromJson(json);
}

Object? _readLat(Map<dynamic, dynamic> json, String key) =>
    json['centroid'] is Map ? readDouble(json['centroid'] as Map, 'lat') : null;

Object? _readLng(Map<dynamic, dynamic> json, String key) =>
    json['centroid'] is Map ? readDouble(json['centroid'] as Map, 'lng') : null;

// `reportIds` is populated with `{ _id, reportNumber }` documents.
Object? _readReportNumbers(Map<dynamic, dynamic> json, String key) => [
  for (final r in json['reportIds'] as List? ?? const [])
    if (r is Map && r['reportNumber'] is String) r['reportNumber'],
];
