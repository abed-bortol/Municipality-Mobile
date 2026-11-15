import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/l10n/l10n.dart';

extension InvestigationResultUi on InvestigationResult {
  String label(AppLocalizations l10n) => switch (this) {
        InvestigationResult.confirmed => l10n.resultConfirmed,
        InvestigationResult.notConfirmed => l10n.resultNotConfirmed,
        InvestigationResult.inconclusive => l10n.resultInconclusive,
        InvestigationResult.resolved => l10n.resultResolved,
      };

  /// Website: confirmed rose, resolved emerald, others neutral.
  Color get color => switch (this) {
        InvestigationResult.confirmed => AppColors.rose400,
        InvestigationResult.resolved => const Color(0xFF34D399),
        InvestigationResult.notConfirmed => AppColors.teal300,
        InvestigationResult.inconclusive => const Color(0xFFFBBF24),
      };
}

extension InvestigationStatusUi on InvestigationStatus {
  String label(AppLocalizations l10n) => switch (this) {
        InvestigationStatus.pending => l10n.invStatusPending,
        InvestigationStatus.inProgress => l10n.invStatusInProgress,
        InvestigationStatus.completed => l10n.invStatusCompleted,
      };
}
