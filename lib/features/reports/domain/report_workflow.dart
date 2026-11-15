import 'package:municipality/features/reports/domain/report.dart';

/// Stages shown in the workflow stepper (REJECTED is a side exit).
const reportWorkflowSteps = [
  ReportStatus.submitted,
  ReportStatus.underReview,
  ReportStatus.verified,
  ReportStatus.inInvestigation,
  ReportStatus.resolved,
  ReportStatus.closed,
];

/// Forward-only workflow, matching the website's ReportDetailsModal and the
/// server's `STATUS_TRANSITIONS` (report.service.js).
extension ReportWorkflow on ReportStatus {
  /// The single forward step offered to staff, or null when terminal.
  ReportStatus? get nextStep => switch (this) {
        ReportStatus.submitted => ReportStatus.underReview,
        ReportStatus.underReview => ReportStatus.verified,
        ReportStatus.verified => ReportStatus.inInvestigation,
        ReportStatus.inInvestigation => ReportStatus.resolved,
        ReportStatus.resolved => ReportStatus.closed,
        ReportStatus.closed || ReportStatus.rejected => null,
      };

  /// Rejecting is allowed until the incident is resolved.
  bool get canReject => const {
        ReportStatus.submitted,
        ReportStatus.underReview,
        ReportStatus.verified,
        ReportStatus.inInvestigation,
      }.contains(this);

  bool get canAssign =>
      this != ReportStatus.closed && this != ReportStatus.rejected;

  /// Default audit comment when staff advance to this status without
  /// writing one (same texts the website stores).
  String get defaultComment => switch (this) {
        ReportStatus.underReview =>
          'Inspector initiated formal review of incident.',
        ReportStatus.verified =>
          'Citizen report verified by health surveillance triage team.',
        ReportStatus.inInvestigation => 'On-site field investigation launched.',
        ReportStatus.resolved => 'Inspection finalized and incident remediated.',
        ReportStatus.closed =>
          'Case officially closed and archived by health authority.',
        _ => 'Advanced forward to $apiValue as per inspection protocol.',
      };
}

/// Audit comment stored when a report is rejected.
String rejectionComment(String reason) =>
    'Report rejected / dismissed: $reason';
