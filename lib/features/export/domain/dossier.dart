import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/domain/dashboard_stats.dart';
import 'package:municipality/features/reports/domain/report.dart';

/// Website ExportReportModal: how many critical reports the dossier lists.
const dossierCriticalLimit = 8;

/// Everything the official surveillance dossier shows.
typedef DossierData = ({
  DashboardStats stats,
  List<Cluster> clusters,
  List<Report> criticalReports,
});

DossierData buildDossierData({
  required DashboardStats stats,
  required List<Report> reports,
  required List<Cluster> clusters,
}) => (
  stats: stats,
  clusters: clusters,
  criticalReports: reports
      .where((r) => r.riskLevel == RiskLevel.critical)
      .take(dossierCriticalLimit)
      .toList(),
);

/// Unique per generation, unlike the website's fixed `DOC-TRP-EPI-YYYY-09`.
String dossierNumber(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'DOC-TRP-EPI-${at.year}${two(at.month)}${two(at.day)}-'
      '${two(at.hour)}${two(at.minute)}';
}
