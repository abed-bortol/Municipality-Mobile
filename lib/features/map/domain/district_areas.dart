import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';

/// Approximate district centres and outlines from the website's
/// `DISTRICT_BOUNDS` (TripoliMap.tsx). Only these nine have outlines.
const districtAreas = <String, ({LatLng center, List<LatLng> outline})>{
  'Al-Mina': (
    center: LatLng(34.4518, 35.8198),
    outline: [
      LatLng(34.4590, 35.8100),
      LatLng(34.4580, 35.8300),
      LatLng(34.4480, 35.8320),
      LatLng(34.4440, 35.8230),
      LatLng(34.4460, 35.8120),
    ],
  ),
  'Al-Tal': (
    center: LatLng(34.4362, 35.8441),
    outline: [
      LatLng(34.4395, 35.8410),
      LatLng(34.4395, 35.8475),
      LatLng(34.4330, 35.8480),
      LatLng(34.4325, 35.8415),
    ],
  ),
  'Bab Al-Tabbaneh': (
    center: LatLng(34.4442, 35.8504),
    outline: [
      LatLng(34.4480, 35.8460),
      LatLng(34.4475, 35.8550),
      LatLng(34.4405, 35.8540),
      LatLng(34.4410, 35.8465),
    ],
  ),
  'Jabal Mohsen': (
    center: LatLng(34.4468, 35.8562),
    outline: [
      LatLng(34.4510, 35.8540),
      LatLng(34.4505, 35.8620),
      LatLng(34.4435, 35.8610),
      LatLng(34.4435, 35.8545),
    ],
  ),
  'Abu Samra': (
    center: LatLng(34.4221, 35.8482),
    outline: [
      LatLng(34.4280, 35.8420),
      LatLng(34.4275, 35.8560),
      LatLng(34.4150, 35.8540),
      LatLng(34.4160, 35.8410),
    ],
  ),
  'Al-Qobbeh': (
    center: LatLng(34.4378, 35.8612),
    outline: [
      LatLng(34.4420, 35.8560),
      LatLng(34.4410, 35.8690),
      LatLng(34.4310, 35.8680),
      LatLng(34.4315, 35.8565),
    ],
  ),
  'Dam w Farez': (
    center: LatLng(34.4285, 35.8324),
    outline: [
      LatLng(34.4335, 35.8270),
      LatLng(34.4330, 35.8370),
      LatLng(34.4240, 35.8360),
      LatLng(34.4245, 35.8260),
    ],
  ),
  'Beddawi': (
    center: LatLng(34.4612, 35.8640),
    outline: [
      LatLng(34.4680, 35.8580),
      LatLng(34.4670, 35.8710),
      LatLng(34.4540, 35.8690),
      LatLng(34.4550, 35.8570),
    ],
  ),
  'Zahrieh': (
    center: LatLng(34.4412, 35.8415),
    outline: [
      LatLng(34.4445, 35.8375),
      LatLng(34.4440, 35.8450),
      LatLng(34.4380, 35.8445),
      LatLng(34.4385, 35.8370),
    ],
  ),
};

final tripoliCenterLatLng = LatLng(tripoliCenter.lat, tripoliCenter.lng);

/// Nearest district centre to a picked point, with the website's fallbacks
/// for points far from every centre (`estimateDistrictFromCoords`).
String estimateDistrict(double lat, double lng) {
  var closest = 'Al-Tal';
  var minDistance = double.infinity;
  for (final MapEntry(key: name, value: area) in districtAreas.entries) {
    final d = math.sqrt(
      math.pow(lat - area.center.latitude, 2) +
          math.pow(lng - area.center.longitude, 2),
    );
    if (d < minDistance) {
      minDistance = d;
      closest = name;
    }
  }
  if (minDistance > 0.05) {
    if (lat > 34.455) return 'Beddawi';
    if (lng < 35.83) return 'Al-Mina';
    if (lat < 34.43) return 'Abu Samra';
  }
  return closest;
}
