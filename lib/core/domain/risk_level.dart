import 'package:freezed_annotation/freezed_annotation.dart';

/// Shared by reports, alerts and clusters (`RISK_LEVELS` on the server).
/// Ordered from least to most severe.
enum RiskLevel {
  @JsonValue('LOW')
  low,
  @JsonValue('MEDIUM')
  medium,
  @JsonValue('HIGH')
  high,
  @JsonValue('CRITICAL')
  critical;

  String get apiValue => name.toUpperCase();

  bool get isUrgent => this == high || this == critical;
}
