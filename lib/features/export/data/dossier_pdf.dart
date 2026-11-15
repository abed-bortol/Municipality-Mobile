import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/export/domain/dossier.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF475569);
const _teal = PdfColor.fromInt(0xFF115E59);
const _rule = PdfColor.fromInt(0xFFCBD5E1);
const _panel = PdfColor.fromInt(0xFFF8FAFC);

/// The website's printable dossier as a PDF, in the app language.
///
/// The website signs it with two fixed officials and "[Certified Digital
/// Signature]"; here the signed-in user is the preparer and the approval
/// is left as an empty signature line, since nothing certifies it.
Future<Uint8List> buildDossierPdf({
  required DossierData data,
  required AppLocalizations l10n,
  required User preparedBy,
  required DateTime generatedAt,
  required pw.Font font,
  required pw.Font boldFont,
  PdfPageFormat format = PdfPageFormat.a4,
}) {
  final rtl = l10n.localeName == 'ar';
  final align = rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
  final stats = data.stats;

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(
      text,
      style: const pw.TextStyle(
        fontSize: 10.5,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  );

  pw.Widget table(List<String> headers, List<List<String>> rows) => rows.isEmpty
      ? pw.Text(
          l10n.dossierNoneRecorded,
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        )
      : pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          border: pw.TableBorder.all(color: _rule, width: 0.6),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF1F5F9),
          ),
          headerStyle: const pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          headerAlignment: align,
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: align,
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
        );

  pw.Widget signature(String role, String name, String detail) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _muted, width: 0.8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(role, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 2),
          pw.Text(
            name,
            style: const pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (detail.isNotEmpty)
            pw.Text(detail, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 28),
          pw.Text(
            l10n.dossierSignatureLine,
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
        ],
      ),
    ),
  );

  final date = DateFormat.yMMMMd(l10n.localeName).format(generatedAt);
  final doc = pw.Document(
    title: l10n.exportDossier,
    author: preparedBy.name,
    creator: 'Tripoli HealthPulse',
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      ),
      footer: (context) => pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              l10n.dossierFooter,
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ],
      ),
      build: (context) => [
        // Letterhead
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.5)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l10n.dossierAuthority,
                      style: const pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                    pw.Text(
                      l10n.dossierMunicipality,
                      style: const pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Text(
                      l10n.dossierDirectorate,
                      style: const pw.TextStyle(fontSize: 8.5, color: _teal),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    dossierNumber(generatedAt),
                    textDirection: pw.TextDirection.ltr,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    l10n.dossierDateGenerated(date),
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  pw.Text(
                    l10n.dossierClassification,
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 1. Summary
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _panel,
            border: pw.Border.all(color: _rule),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l10n.dossierSummaryTitle,
                style: const pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.dossierSummaryBody(
                  stats.totalReports,
                  stats.criticalCount,
                  stats.resolutionRate,
                ),
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
              ),
            ],
          ),
        ),
        // 2. Indicators
        heading(l10n.dossierIndicatorsTitle),
        table(
          [l10n.colIndicator, l10n.colValue, l10n.colStatus, l10n.colDirective],
          [
            [
              l10n.indTotal,
              '${stats.totalReports}',
              l10n.indTotalStatus,
              l10n.indTotalDirective,
            ],
            [
              l10n.indCritical,
              '${stats.criticalCount}',
              l10n.indCriticalStatus,
              l10n.indCriticalDirective,
            ],
            [
              l10n.indClusters,
              '${data.clusters.length}',
              l10n.indClustersStatus,
              l10n.indClustersDirective,
            ],
            [
              l10n.indResolved,
              '${stats.resolvedCount} (${stats.resolutionRate}%)',
              l10n.indResolvedStatus,
              l10n.indResolvedDirective,
            ],
          ],
        ),
        // 3. Clusters
        heading(l10n.dossierClustersTitle),
        table(
          [
            l10n.colClusterCode,
            l10n.colDistrict,
            l10n.colCategory,
            l10n.colIncidents,
            l10n.colAffected,
            l10n.colRisk,
          ],
          [
            for (final c in data.clusters)
              [
                c.clusterCode,
                l10n.districtName(c.district),
                l10n.categoryName(c.categoryName),
                '${c.reportCount}',
                '~${c.totalAffected}',
                l10n.riskLabel(c.riskLevel.apiValue),
              ],
          ],
        ),
        // 4. Critical reports
        heading(l10n.dossierCriticalTitle),
        table(
          [
            l10n.colReportNo,
            l10n.colCategory,
            l10n.colTitleLocation,
            l10n.colScore,
            l10n.colOfficer,
          ],
          [
            for (final r in data.criticalReports)
              [
                r.reportNumber,
                l10n.categoryName(r.category.name),
                '${r.title} (${l10n.districtName(r.location.district)})',
                '${r.riskScore.round()}',
                r.assignedOfficer?.name ?? l10n.unassignedOfficer,
              ],
          ],
        ),
        // Signatures
        pw.SizedBox(height: 28),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            signature(
              l10n.dossierPreparedBy,
              preparedBy.name,
              [
                l10n.roleLabel(preparedBy.role.apiValue),
                ?preparedBy.badgeNumber,
              ].join(' • '),
            ),
            pw.SizedBox(width: 28),
            signature(l10n.dossierReviewedBy, '', ''),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
