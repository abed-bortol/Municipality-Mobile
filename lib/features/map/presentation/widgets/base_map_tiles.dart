import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:municipality/l10n/l10n.dart';

/// Base maps offered by the website (no API key needed).
enum MapStyle {
  osm(
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    19,
    'OpenStreetMap contributors',
  ),
  streets(
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    19,
    'Esri — Street Map',
  ),
  dark(
    'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    16,
    'Esri — Dark Canvas',
  ),
  satellite(
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    18,
    'Esri — Satellite View',
  );

  const MapStyle(this.urlTemplate, this.maxNativeZoom, this.attribution);

  final String urlTemplate;
  final int maxNativeZoom;
  final String attribution;

  String label(AppLocalizations l10n) => switch (this) {
    MapStyle.osm => l10n.mapStyleOsm,
    MapStyle.streets => l10n.mapStyleStreets,
    MapStyle.dark => l10n.mapStyleDark,
    MapStyle.satellite => l10n.mapStyleSatellite,
  };
}

/// Tile layer plus the attribution the tile providers require.
List<Widget> baseMapLayers(MapStyle style) => [
  TileLayer(
    urlTemplate: style.urlTemplate,
    maxNativeZoom: style.maxNativeZoom,
    // Identifies the app to the tile servers (OSM usage policy).
    userAgentPackageName: 'lb.tripoli.municipality',
  ),
  SimpleAttributionWidget(source: Text(style.attribution)),
];
