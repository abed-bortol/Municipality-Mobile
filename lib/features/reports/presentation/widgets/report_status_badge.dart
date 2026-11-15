import 'package:flutter/material.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/l10n/l10n.dart';

/// Status pill (website `getStatusColor`).
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  static Color colorOf(ReportStatus status) => switch (status) {
    ReportStatus.submitted => const Color(0xFF60A5FA), // blue-400
    ReportStatus.underReview => const Color(0xFFC084FC), // purple-400
    ReportStatus.verified => const Color(0xFF818CF8), // indigo-400
    ReportStatus.inInvestigation => const Color(0xFFFBBF24), // amber-400
    ReportStatus.resolved => const Color(0xFF2DD4BF), // teal-400
    ReportStatus.closed => const Color(0xFF94A3B8), // slate-400
    ReportStatus.rejected => const Color(0xFFF87171), // red-400
  };

  @override
  Widget build(BuildContext context) => Pill(
    label: context.l10n.statusLabel(status.apiValue),
    color: colorOf(status),
  );
}
