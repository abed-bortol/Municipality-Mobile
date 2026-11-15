import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/report.dart';

part 'new_report_request.freezed.dart';
part 'new_report_request.g.dart';

/// Body of `POST /reports` (website: `NewReportPayload` in reportService.ts).
@Freezed(fromJson: false, toJson: true)
abstract class NewReportRequest with _$NewReportRequest {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory NewReportRequest({
    required ReportCategory category,
    required String title,
    required String description,
    DateTime? incidentDate,
    required ReportLocation location,
    required int affectedCount,
    required RiskLevel initialSeverity,
    String? imageUrl,
    String? additionalComments,
  }) = _NewReportRequest;
}
