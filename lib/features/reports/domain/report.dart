import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'report.freezed.dart';
part 'report.g.dart';

/// Lifecycle of a report (`REPORT_STATUSES` on the server).
enum ReportStatus {
  @JsonValue('SUBMITTED')
  submitted,
  @JsonValue('UNDER_REVIEW')
  underReview,
  @JsonValue('VERIFIED')
  verified,
  @JsonValue('IN_INVESTIGATION')
  inInvestigation,
  @JsonValue('RESOLVED')
  resolved,
  @JsonValue('CLOSED')
  closed,
  @JsonValue('REJECTED')
  rejected;

  String get apiValue => _$ReportStatusEnumMap[this]!;

  bool get isOpen => !const {resolved, closed, rejected}.contains(this);
}

/// Public health incident report, normalized like `toReport()` in the
/// website's `utils/normalize.ts`.
@freezed
abstract class Report with _$Report {
  const factory Report({
    @JsonKey(readValue: readId) required String id,
    @Default('') String reportNumber,
    @Default(ReportCitizen()) ReportCitizen citizen,
    @Default(ReportCategory()) ReportCategory category,
    @Default('') String title,
    @Default('') String description,
    DateTime? incidentDate,
    @Default(ReportLocation()) ReportLocation location,
    @Default(0) int affectedCount,
    @JsonKey(unknownEnumValue: RiskLevel.medium)
    @Default(RiskLevel.medium)
    RiskLevel initialSeverity,
    @JsonKey(readValue: readNonEmpty) String? imageUrl,
    @Default('') String additionalComments,
    @JsonKey(unknownEnumValue: ReportStatus.submitted)
    @Default(ReportStatus.submitted)
    ReportStatus status,
    @JsonKey(readValue: _readOfficer) AssignedOfficer? assignedOfficer,
    @Default(0) double riskScore,
    @JsonKey(unknownEnumValue: RiskLevel.low)
    @Default(RiskLevel.low)
    RiskLevel riskLevel,
    @Default(RiskFactors()) RiskFactors riskFactors,
    @Default(<StatusHistoryEntry>[]) List<StatusHistoryEntry> statusHistory,
    DateTime? createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
}

@freezed
abstract class ReportCitizen with _$ReportCitizen {
  const factory ReportCitizen({
    @JsonKey(readValue: _readUserId) @Default('') String userId,
    @Default('') String name,
    @Default('') String phone,
    @Default('') String email,
  }) = _ReportCitizen;

  factory ReportCitizen.fromJson(Map<String, dynamic> json) =>
      _$ReportCitizenFromJson(json);
}

@freezed
abstract class ReportCategory with _$ReportCategory {
  const factory ReportCategory({
    @Default('') String name,
    @Default('') String code,
  }) = _ReportCategory;

  factory ReportCategory.fromJson(Map<String, dynamic> json) =>
      _$ReportCategoryFromJson(json);
}

@freezed
abstract class ReportLocation with _$ReportLocation {
  const factory ReportLocation({
    @Default('') String address,
    @Default('Tripoli') String district,
    @JsonKey(readValue: readDouble) @Default(0) double lat,
    @JsonKey(readValue: readDouble) @Default(0) double lng,
  }) = _ReportLocation;

  factory ReportLocation.fromJson(Map<String, dynamic> json) =>
      _$ReportLocationFromJson(json);
}

@freezed
abstract class AssignedOfficer with _$AssignedOfficer {
  const factory AssignedOfficer({
    @JsonKey(readValue: _readOfficerId) @Default('') String id,
    @Default('') String name,
    @Default('') String badgeNumber,
  }) = _AssignedOfficer;

  factory AssignedOfficer.fromJson(Map<String, dynamic> json) =>
      _$AssignedOfficerFromJson(json);
}

/// Breakdown of how the server's risk engine scored the report.
@freezed
abstract class RiskFactors with _$RiskFactors {
  const factory RiskFactors({
    @Default(0) double severityScore,
    @Default(0) double affectedPeopleScore,
    @Default(0) double recentReportsScore,
    @Default(0) double geographicClusterScore,
    @Default(0) double categoryScore,
    @Default(<String>[]) List<String> explanations,
  }) = _RiskFactors;

  factory RiskFactors.fromJson(Map<String, dynamic> json) =>
      _$RiskFactorsFromJson(json);
}

@freezed
abstract class StatusHistoryEntry with _$StatusHistoryEntry {
  const factory StatusHistoryEntry({
    @Default('') String oldStatus,
    @Default('') String newStatus,
    @JsonKey(readValue: _readChangedByName) @Default('') String changedBy,
    @JsonKey(readValue: _readChangedByRole) @Default('') String role,
    DateTime? timestamp,
    @Default('') String comment,
  }) = _StatusHistoryEntry;

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryEntryFromJson(json);
}

// Populated reference ({_id, name}) or plain id.
Object? _readUserId(Map<dynamic, dynamic> json, String key) => idOf(json[key]);

Object? _readOfficerId(Map<dynamic, dynamic> json, String key) =>
    idOf(json['officerId'] ?? json['id']);

// The server stores an empty officer sub-document when unassigned.
Object? _readOfficer(Map<dynamic, dynamic> json, String key) {
  final officer = json[key];
  return officer is Map && officer['name'] is String && officer['name'] != ''
      ? officer
      : null;
}

Object? _readChangedByName(Map<dynamic, dynamic> json, String key) =>
    switch (json['changedBy']) {
      Map m => m['name'],
      final v => v,
    };

Object? _readChangedByRole(Map<dynamic, dynamic> json, String key) =>
    switch (json['changedBy']) {
      Map m => m['role'],
      _ => json['role'],
    };
