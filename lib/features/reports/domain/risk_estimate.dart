import 'dart:math' as math;

import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/reports/domain/report.dart';

/// Live preview of the server's risk score while a report is being written.
typedef RiskEstimate = ({int score, RiskLevel level, RiskFactors factors});

/// Port of `calculateReportRisk` from the website's `utils/riskEngine.ts`
/// (same weights as the server). [nearby] are the reports the user can see,
/// used for the geographic cluster factor.
RiskEstimate estimateRisk({
  required String categoryName,
  required RiskLevel severity,
  required int affectedCount,
  required double lat,
  required double lng,
  DateTime? incidentDate,
  List<Report> nearby = const [],
  DateTime? now,
}) {
  final severityScore = switch (severity) {
    RiskLevel.critical => 25,
    RiskLevel.high => 18,
    RiskLevel.medium => 10,
    RiskLevel.low => 4,
  };

  final affected = math.max(affectedCount, 1);
  final affectedPeopleScore = switch (affected) {
    >= 50 => 25,
    >= 20 => 20,
    >= 10 => 15,
    >= 4 => 10,
    _ => 5,
  };

  final current = now ?? DateTime.now();
  final hours =
      math.max(0, current.difference(incidentDate ?? current).inMinutes) / 60;
  final recentReportsScore = hours <= 6
      ? 15
      : hours <= 24
          ? 10
          : hours <= 72
              ? 5
              : 2;

  final category = categoryName.toLowerCase();
  bool has(String s) => category.contains(s);
  final categoryScore = has('water') || has('drinking')
      ? 15
      : has('poison') || has('outbreak') || has('disease')
          ? 14
          : has('sewage')
              ? 12
              : has('food')
                  ? 10
                  : has('pest') || has('mosquito') || has('rodent')
                      ? 9
                      : 6;

  int geographicClusterScore;
  if (lat != 0 && lng != 0 && nearby.isNotEmpty) {
    final count = nearby
        .where((r) =>
            r.category.name.toLowerCase() == category &&
            r.location.lat != 0 &&
            r.location.lng != 0 &&
            haversineKm(lat, lng, r.location.lat, r.location.lng) <= 1.5)
        .length;
    geographicClusterScore = switch (count) {
      >= 5 => 20,
      >= 3 => 14,
      >= 1 => 7,
      _ => 2,
    };
  } else {
    geographicClusterScore = 4;
  }

  final score = (severityScore +
          affectedPeopleScore +
          recentReportsScore +
          categoryScore +
          geographicClusterScore)
      .clamp(0, 100);

  return (
    score: score,
    level: riskLevelForScore(score),
    factors: RiskFactors(
      severityScore: severityScore.toDouble(),
      affectedPeopleScore: affectedPeopleScore.toDouble(),
      recentReportsScore: recentReportsScore.toDouble(),
      geographicClusterScore: geographicClusterScore.toDouble(),
      categoryScore: categoryScore.toDouble(),
    ),
  );
}

/// Score bands: 0-25 low, 26-50 medium, 51-75 high, 76-100 critical.
RiskLevel riskLevelForScore(num score) => score >= 76
    ? RiskLevel.critical
    : score >= 51
        ? RiskLevel.high
        : score >= 26
            ? RiskLevel.medium
            : RiskLevel.low;

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
