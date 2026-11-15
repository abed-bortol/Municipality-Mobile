import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/features/alerts/presentation/alerts_providers.dart';
import 'package:municipality/features/clusters/domain/cluster.dart';
import 'package:municipality/features/dashboard/presentation/dashboard_providers.dart';
import 'package:municipality/features/map/domain/district_areas.dart';
import 'package:municipality/features/map/presentation/map_providers.dart';
import 'package:municipality/features/map/presentation/widgets/base_map_tiles.dart';
import 'package:municipality/features/map/presentation/widgets/map_sheets.dart';
import 'package:municipality/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

const _initialZoom = 13.5;

/// Website TripoliMap: reports coloured by risk, cluster circles and
/// district outlines on a switchable base map (staff only).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  MapStyle _style = MapStyle.osm;
  bool _showClusters = true;
  bool _showDistricts = true;

  // Where to open; a pending "View on map" request wins.
  late final LatLng _initialCenter = _takeFocus() ?? tripoliCenterLatLng;

  LatLng? _takeFocus() {
    final focus = ref.read(mapFocusProvider);
    if (focus != null) {
      Future.microtask(() => ref.read(mapFocusProvider.notifier).clear());
    }
    return focus;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recenter() => _controller.move(tripoliCenterLatLng, _initialZoom);

  Future<void> _openLayers() async {
    final result = await showMapLayersSheet(
      context,
      style: _style,
      showClusters: _showClusters,
      showDistricts: _showDistricts,
      clusterCount: ref.read(activeClustersProvider).value?.length ?? 0,
    );
    if (result != null && mounted) {
      setState(() {
        _style = result.style;
        _showClusters = result.showClusters;
        _showDistricts = result.showDistricts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    ref.listen(mapFocusProvider, (_, point) {
      if (point == null) return;
      _controller.move(point, 15.5);
      ref.read(mapFocusProvider.notifier).clear();
    });

    final filter = ref.watch(mapFilterControllerProvider);
    final all = ref.watch(reportsProvider).value?.reports ?? const <Report>[];
    final shown = filter.apply(all);
    final clusters = _showClusters
        ? ref.watch(activeClustersProvider).value ?? const <Cluster>[]
        : const <Cluster>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripoliMap),
        actions: [
          IconButton(
            tooltip: l10n.filters,
            onPressed: () => showMapFilterSheet(context, all),
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: l10n.mapLayers,
            onPressed: _openLayers,
            icon: const Icon(Icons.layers_outlined),
          ),
          const NotificationBell(),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              ...baseMapLayers(_style).take(1),
              if (_showDistricts) ...[
                PolygonLayer(
                  polygons: [
                    for (final area in districtAreas.values)
                      Polygon(
                        points: area.outline,
                        color: AppColors.teal500.withValues(alpha: 0.08),
                        borderColor: AppColors.teal400.withValues(alpha: 0.7),
                        borderStrokeWidth: 1.5,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final MapEntry(key: name, value: area)
                        in districtAreas.entries)
                      Marker(
                        point: area.center,
                        width: 120,
                        height: 26,
                        child: _DistrictLabel(
                          name: l10n.districtName(name),
                          onTap: () => showDistrictProfileSheet(
                            context,
                            district: name,
                            reports: all,
                            alerts: ref.read(alertsProvider).value ?? const [],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              CircleLayer(
                circles: [
                  for (final c in clusters)
                    if (c.lat != 0 && c.lng != 0)
                      CircleMarker(
                        point: LatLng(c.lat, c.lng),
                        radius: c.radiusMeters > 0 ? c.radiusMeters : 750,
                        useRadiusInMeter: true,
                        color: _clusterColor(c).withValues(
                          alpha: c.riskLevel == RiskLevel.critical
                              ? 0.22
                              : 0.14,
                        ),
                        borderColor: _clusterColor(c),
                        borderStrokeWidth: 2,
                      ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final c in clusters)
                    if (c.lat != 0 && c.lng != 0)
                      Marker(
                        point: LatLng(c.lat, c.lng),
                        width: 34,
                        height: 34,
                        child: _TapTarget(
                          label: c.clusterCode,
                          onTap: () => showClusterSheet(context, c, all),
                          child: Icon(
                            Icons.coronavirus_outlined,
                            color: _clusterColor(c),
                            size: 26,
                          ),
                        ),
                      ),
                  for (final r in shown)
                    Marker(
                      point: LatLng(r.location.lat, r.location.lng),
                      width: _markerSize(r.riskLevel) + 8,
                      height: _markerSize(r.riskLevel) + 8,
                      child: _TapTarget(
                        label: '#${r.reportNumber}',
                        onTap: () => showReportPreviewSheet(context, r),
                        child: _ReportDot(level: r.riskLevel),
                      ),
                    ),
                ],
              ),
              ...baseMapLayers(_style).skip(1),
            ],
          ),
          PositionedDirectional(
            top: 12,
            start: 12,
            end: 72,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Overlay(
                text: l10n.reportsOnMap(shown.length, all.length),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 36,
            end: 12,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              tooltip: l10n.recenterMap,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

Color _clusterColor(Cluster c) => c.riskLevel == RiskLevel.critical
    ? const Color(0xFFF43F5E)
    : const Color(0xFFF97316);

double _markerSize(RiskLevel level) => switch (level) {
  RiskLevel.critical => 22,
  RiskLevel.high => 18,
  RiskLevel.medium => 15,
  RiskLevel.low => 12,
};

class _ReportDot extends StatelessWidget {
  const _ReportDot({required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final size = _markerSize(level);
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: RiskBadge.colorOf(level),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _TapTarget extends StatelessWidget {
  const _TapTarget({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    ),
  );
}

class _DistrictLabel extends StatelessWidget {
  const _DistrictLabel({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: _TapTarget(
      label: name,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.teal600),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.teal300,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.slate900.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.slate700),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.slate100),
    ),
  );
}

/// Opens the map tab centred on [point] (e.g. from the cluster monitor).
void showOnMap(BuildContext context, WidgetRef ref, LatLng point) {
  ref.read(mapFocusProvider.notifier).focus(point);
  context.go(AppRoutes.map);
}
