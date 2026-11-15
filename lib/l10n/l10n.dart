import 'package:flutter/widgets.dart';
import 'package:municipality/l10n/generated/app_localizations.dart';

export 'package:municipality/l10n/generated/app_localizations.dart';

/// `context.l10n.signIn` instead of `AppLocalizations.of(context).signIn`.
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// Labels for values the API sends as raw strings (roles, statuses, risk
/// levels, districts, categories). Unknown values are shown as received.
extension ServerValueL10n on AppLocalizations {
  String roleLabel(String apiRole) => switch (apiRole) {
        'CITIZEN' => roleCitizen,
        'HEALTH_OFFICER' => roleHealthOfficer,
        'ADMINISTRATOR' => roleAdministrator,
        'SYSTEM' => roleSystem,
        _ => apiRole,
      };

  /// Audit trail actions logged by the server (auditService callers).
  String auditActionLabel(String action) => switch (action) {
        'ACKNOWLEDGE_ALERT' => actionAcknowledgeAlert,
        'ASSIGN_OFFICER' => actionAssignOfficer,
        'CREATE_CATEGORY' => actionCreateCategory,
        'CREATE_INVESTIGATION' => actionCreateInvestigation,
        'CREATE_USER' => actionCreateUser,
        'FINALIZE_INVESTIGATION' => actionFinalizeInvestigation,
        'REASSESS_RISK' => actionReassessRisk,
        'RESOLVE_ALERT' => actionResolveAlert,
        'RUN_CLUSTER_SCAN' => actionRunClusterScan,
        'SUBMIT_REPORT' => actionSubmitReport,
        'UPDATE_CATEGORY' => actionUpdateCategory,
        'UPDATE_CLUSTER_STATUS' => actionUpdateClusterStatus,
        'UPDATE_INVESTIGATION' => actionUpdateInvestigation,
        'UPDATE_REPORT_STATUS' => actionUpdateReportStatus,
        'UPDATE_USER_ROLE' => actionUpdateUserRole,
        'USER_LOGIN' => actionUserLogin,
        'USER_REGISTER' => actionUserRegister,
        _ => action,
      };

  String statusLabel(String apiStatus) => switch (apiStatus) {
        'SUBMITTED' => statusSubmitted,
        'UNDER_REVIEW' => statusUnderReview,
        'VERIFIED' => statusVerified,
        'IN_INVESTIGATION' => statusInInvestigation,
        'RESOLVED' => statusResolved,
        'CLOSED' => statusClosed,
        'REJECTED' => statusRejected,
        _ => apiStatus,
      };

  String riskLabel(String apiLevel) => switch (apiLevel) {
        'CRITICAL' => riskCritical,
        'HIGH' => riskHigh,
        'MEDIUM' => riskMedium,
        'LOW' => riskLow,
        _ => apiLevel,
      };

  String districtName(String district) => switch (district) {
        'Al-Tal' => districtAlTal,
        'Al-Mina' => districtAlMina,
        'Bab Al-Tabbaneh' => districtBabAlTabbaneh,
        'Jabal Mohsen' => districtJabalMohsen,
        'Abu Samra' => districtAbuSamra,
        'Al-Qobbeh' => districtAlQobbeh,
        'Dam w Farez' => districtDamWFarez,
        'Beddawi' => districtBeddawi,
        'Zahrieh' => districtZahrieh,
        'Maarad' => districtMaarad,
        'Mina Port' => districtMinaPort,
        'Haddadine' => districtHaddadine,
        'Swayqa' => districtSwayqa,
        'Azmi Street' => districtAzmiStreet,
        'Bab Al-Ramel' => districtBabAlRamel,
        _ => district,
      };

  String categoryName(String name) => switch (name) {
        'Food Safety' => categoryFoodSafety,
        'Suspected Food Poisoning' => categorySuspectedFoodPoisoning,
        'Water Contamination' => categoryWaterContamination,
        'Unsafe Drinking Water' => categoryUnsafeDrinkingWater,
        'Sewage Problem' => categorySewageProblem,
        'Garbage Accumulation' => categoryGarbageAccumulation,
        'Air Pollution' => categoryAirPollution,
        'Mosquito Infestation' => categoryMosquitoInfestation,
        'Rodent/Pest Problem' => categoryRodentPestProblem,
        'Suspected Disease/Outbreak' => categorySuspectedDiseaseOutbreak,
        'Environmental Hazard' => categoryEnvironmentalHazard,
        'Other' => categoryOther,
        _ => name,
      };
}
