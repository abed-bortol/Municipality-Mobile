import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/map/domain/district_areas.dart';
import 'package:municipality/features/map/presentation/widgets/base_map_tiles.dart';
import 'package:municipality/l10n/l10n.dart';

typedef PickedLocation = ({double lat, double lng, String district});

/// Opens the picker; null if the user backs out.
Future<PickedLocation?> pickLocation(BuildContext context, {LatLng? initial}) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(initial: initial),
      ),
    );

/// Rounded like the website picker (5 decimals, about 1 m).
double roundCoordinate(double value) => double.parse(value.toStringAsFixed(5));

/// Website report form "pinpoint" map: tap to drop the pin.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng? _pin = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pin = _pin;
    final district = pin == null
        ? null
        : estimateDistrict(pin.latitude, pin.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pickLocationTitle)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: widget.initial ?? tripoliCenterLatLng,
                initialZoom: 14,
                minZoom: 10,
                maxZoom: 18,
                onTap: (_, point) => setState(() => _pin = point),
              ),
              children: [
                ...baseMapLayers(MapStyle.osm).take(1),
                if (pin != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.rose400,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ...baseMapLayers(MapStyle.osm).skip(1),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pin == null
                        ? l10n.pickLocationHint
                        : '${l10n.pinnedAt(roundCoordinate(pin.latitude).toString(), roundCoordinate(pin.longitude).toString())}\n${l10n.detectedDistrict(l10n.districtName(district!))}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.slate300),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: pin == null
                        ? null
                        : () => Navigator.pop<PickedLocation>(context, (
                            lat: roundCoordinate(pin.latitude),
                            lng: roundCoordinate(pin.longitude),
                            district: district!,
                          )),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.useThisLocation),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
