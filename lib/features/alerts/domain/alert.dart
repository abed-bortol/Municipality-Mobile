import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

enum AlertStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('ACKNOWLEDGED')
  acknowledged,
  @JsonValue('RESOLVED')
  resolved,
}

/// `ALERT_TYPES` on the server.
enum AlertType {
  @JsonValue('CRITICAL_INCIDENT')
  criticalIncident,
  @JsonValue('CLUSTER_DETECTED')
  clusterDetected,
  @JsonValue('GEOGRAPHIC_SPIKE')
  geographicSpike,
  @JsonValue('CATEGORY_SURGE')
  categorySurge,
  @JsonValue('UNRESOLVED_TIMEOUT')
  unresolvedTimeout,
}

/// Surveillance alert raised by the server (critical report, cluster...),
/// normalized like `toAlert()` in the website's `utils/normalize.ts`.
@freezed
abstract class Alert with _$Alert {
  const factory Alert({
    @JsonKey(readValue: readId) required String id,
    @Default('') String alertCode,
    @JsonKey(unknownEnumValue: AlertType.criticalIncident)
    @Default(AlertType.criticalIncident)
    AlertType alertType,
    @Default('') String title,
    @Default('') String description,
    @JsonKey(readValue: _readRefId) String? relatedReportId,
    @JsonKey(readValue: _readRefId) String? relatedClusterId,
    @JsonKey(unknownEnumValue: RiskLevel.high)
    @Default(RiskLevel.high)
    RiskLevel riskLevel,
    @Default('') String area,
    @JsonKey(unknownEnumValue: AlertStatus.active)
    @Default(AlertStatus.active)
    AlertStatus status,
    @JsonKey(readValue: _readOfficerName) String? assignedOfficer,
    DateTime? createdAt,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}

// Populated reference or plain id; missing becomes null.
Object? _readRefId(Map<dynamic, dynamic> json, String key) {
  final id = idOf(json[key]);
  return id.isEmpty ? null : id;
}

Object? _readOfficerName(Map<dynamic, dynamic> json, String key) =>
    switch (json[key]) {
      {'name': final String name} when name.isNotEmpty => name,
      _ => null,
    };
