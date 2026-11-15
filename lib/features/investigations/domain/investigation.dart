import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/utils/json_readers.dart';
import 'package:municipality/features/reports/domain/report.dart';

part 'investigation.freezed.dart';
part 'investigation.g.dart';

/// `INVESTIGATION_RESULTS` on the server.
enum InvestigationResult {
  @JsonValue('Confirmed')
  confirmed,
  @JsonValue('Not Confirmed')
  notConfirmed,
  @JsonValue('Inconclusive')
  inconclusive,
  @JsonValue('Resolved')
  resolved;

  String get apiValue => _$InvestigationResultEnumMap[this]!;
}

/// `INVESTIGATION_STATUSES` on the server. Only finalizing completes one.
enum InvestigationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed;

  String get apiValue => _$InvestigationStatusEnumMap[this]!;
}

/// Field investigation of a report, normalized like `toInvestigation()` on
/// the website. The list endpoint populates the report, so its status is
/// available for the "Finalize" shortcut.
@freezed
abstract class Investigation with _$Investigation {
  const factory Investigation({
    @JsonKey(readValue: readId) required String id,
    @Default('') String investigationCode,
    @JsonKey(readValue: _readReportId) @Default('') String reportId,
    @JsonKey(readValue: _readReportNumber) @Default('') String reportNumber,
    @JsonKey(readValue: _readReportTitle) String? reportTitle,
    @JsonKey(
      readValue: _readReportStatus,
      unknownEnumValue: JsonKey.nullForUndefinedEnumValue,
    )
    ReportStatus? reportStatus,
    @JsonKey(readValue: _readOfficerName) @Default('') String officerName,
    @JsonKey(readValue: _readOfficerBadge) @Default('') String officerBadge,
    DateTime? investigationDate,
    @Default('') String findings,
    @Default('') String actionsTaken,
    @Default('') String recommendations,
    @JsonKey(unknownEnumValue: InvestigationResult.inconclusive)
    @Default(InvestigationResult.inconclusive)
    InvestigationResult result,
    @Default('') String samplesCollected,
    @Default('') String notes,
    @JsonKey(unknownEnumValue: InvestigationStatus.inProgress)
    @Default(InvestigationStatus.inProgress)
    InvestigationStatus status,
  }) = _Investigation;

  factory Investigation.fromJson(Map<String, dynamic> json) =>
      _$InvestigationFromJson(json);
}

/// Editable fields sent to `POST /investigations`, `PUT /investigations/:id`
/// and the finalize endpoint.
@Freezed(fromJson: false, toJson: true)
abstract class InvestigationDraft with _$InvestigationDraft {
  @JsonSerializable(includeIfNull: false)
  const factory InvestigationDraft({
    required String findings,
    required String actionsTaken,
    @Default('') String recommendations,
    @Default(InvestigationResult.resolved) InvestigationResult result,
    @Default('') String samplesCollected,
    @Default('') String notes,
    InvestigationStatus? status,
  }) = _InvestigationDraft;
}

Map<dynamic, dynamic>? _report(Map<dynamic, dynamic> json) =>
    json['reportId'] is Map ? json['reportId'] as Map : null;

Object? _readReportId(Map<dynamic, dynamic> json, String key) =>
    idOf(json['reportId']);

Object? _readReportNumber(Map<dynamic, dynamic> json, String key) =>
    json['reportNumber'] ?? _report(json)?['reportNumber'];

Object? _readReportTitle(Map<dynamic, dynamic> json, String key) =>
    _report(json)?['title'];

Object? _readReportStatus(Map<dynamic, dynamic> json, String key) =>
    _report(json)?['status'];

Object? _readOfficerName(Map<dynamic, dynamic> json, String key) =>
    json['officer'] is Map ? json['officer']['name'] : null;

Object? _readOfficerBadge(Map<dynamic, dynamic> json, String key) =>
    json['officer'] is Map ? json['officer']['badgeNumber'] : null;
