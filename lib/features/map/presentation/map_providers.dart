import 'package:latlong2/latlong.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/features/map/domain/map_filter.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_providers.g.dart';

/// Map filters; kept while switching tabs.
@Riverpod(keepAlive: true)
class MapFilterController extends _$MapFilterController {
  @override
  MapFilter build() => const MapFilter();

  void setRiskLevel(RiskLevel? value) =>
      state = state.copyWith(riskLevel: value);

  void setStatus(ReportStatus? value) => state = state.copyWith(status: value);

  void setCategory(String? value) => state = state.copyWith(category: value);

  void clear() => state = const MapFilter();
}

/// Point the map should fly to next ("View on map" from another screen).
/// The map clears it once handled.
@Riverpod(keepAlive: true)
class MapFocus extends _$MapFocus {
  @override
  LatLng? build() => null;

  void focus(LatLng point) => state = point;

  void clear() => state = null;
}
