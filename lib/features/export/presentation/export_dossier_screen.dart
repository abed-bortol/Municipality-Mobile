import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/export/data/dossier_pdf.dart';
import 'package:municipality/features/export/domain/dossier.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_dossier_screen.g.dart';

typedef DossierFonts = ({pw.Font regular, pw.Font bold});

/// Cairo covers Latin and Arabic, like the app's own fonts. Downloaded
/// once and cached by `printing` (same as google_fonts in the UI).
@Riverpod(keepAlive: true)
Future<DossierFonts> dossierFonts(Ref ref) async => (
  regular: await PdfGoogleFonts.cairoRegular(),
  bold: await PdfGoogleFonts.cairoBold(),
);

/// Website ExportReportModal: the official surveillance dossier, previewed
/// as a PDF that can be printed, saved or shared (staff only).
class ExportDossierScreen extends ConsumerWidget {
  const ExportDossierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(dashboardStatsProvider);
    final reports = ref.watch(reportsProvider);
    final clusters = ref.watch(activeClustersProvider);
    final fonts = ref.watch(dossierFontsProvider);
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };

    void retry() => ref
      ..invalidate(dashboardStatsProvider)
      ..invalidate(reportsProvider)
      ..invalidate(activeClustersProvider)
      ..invalidate(dossierFontsProvider);

    final failed = [
      stats,
      reports,
      clusters,
      fonts,
    ].any((v) => v.hasError && !v.hasValue);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportDossier)),
      body: switch ((stats.value, reports.value, clusters.value, fonts.value)) {
        _ when failed => Center(child: LoadErrorView(onRetry: retry)),
        (final s?, final r?, final c?, final f?) when user != null =>
          PdfPreview(
            // Rebuilt when the language or the data changes.
            key: ValueKey((l10n.localeName, s, r, c)),
            build: (format) => buildDossierPdf(
              data: buildDossierData(stats: s, reports: r.reports, clusters: c),
              l10n: l10n,
              preparedBy: user,
              generatedAt: DateTime.now(),
              font: f.regular,
              boldFont: f.bold,
              format: format,
            ),
            pdfFileName: '${dossierNumber(DateTime.now())}.pdf',
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            scrollViewDecoration: const BoxDecoration(
              color: AppColors.slate900,
            ),
            loadingWidget: const Center(child: CircularProgressIndicator()),
          ),
        _ => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                l10n.dossierLoadingFonts,
                style: const TextStyle(color: AppColors.slate400),
              ),
            ],
          ),
        ),
      },
    );
  }
}
