import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/l10n/l10n.dart';

extension ClusterStatusLabel on ClusterStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ClusterStatus.active => l10n.clusterActive,
    ClusterStatus.investigating => l10n.clusterInvestigating,
    ClusterStatus.contained => l10n.clusterContained,
    ClusterStatus.resolved => l10n.clusterResolved,
  };

  Color get color => switch (this) {
    ClusterStatus.active => AppColors.rose400,
    ClusterStatus.investigating => const Color(0xFFFBBF24),
    ClusterStatus.contained => AppColors.cyan500,
    ClusterStatus.resolved => AppColors.teal400,
  };
}
