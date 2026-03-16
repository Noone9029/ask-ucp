import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'osrm_models.dart';

class OsrmService {
  static const String _base = 'https://router.project-osrm.org';

  static Future<OsrmRoute> walkingRouteWithSteps({
    required LatLng start,
    required LatLng end,
  }) async {
    final url = Uri.parse(
      '$_base/route/v1/foot/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson&alternatives=false&steps=true',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('OSRM error: ${res.statusCode} ${res.reasonPhrase}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = (jsonMap['routes'] as List?)?.cast<Map<String, dynamic>>();
    if (routes == null || routes.isEmpty) {
      throw Exception('No route returned by OSRM.');
    }

    final route0 = routes.first;
    final distance = (route0['distance'] as num?)?.toDouble() ?? 0;
    final duration = (route0['duration'] as num?)?.toDouble() ?? 0;

    // geometry
    final geometry = route0['geometry'] as Map<String, dynamic>?;
    final coords = (geometry?['coordinates'] as List?)?.cast<List>() ?? [];

    final points = coords.map((c) {
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();

    if (points.length < 2) {
      throw Exception('Route geometry too short.');
    }

    // steps
    final legs = (route0['legs'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final steps = <OsrmStep>[];

    for (final leg in legs) {
      final legSteps = (leg['steps'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final s in legSteps) {
        final maneuver = (s['maneuver'] as Map?)?.cast<String, dynamic>() ?? {};
        final type = maneuver['type']?.toString() ?? 'continue';
        final modifier = maneuver['modifier']?.toString();
        final name = s['name']?.toString();

        final instr = _humanInstruction(type, modifier, name);

        steps.add(
          OsrmStep(
            instruction: instr,
            distanceMeters: (s['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (s['duration'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }

    return OsrmRoute(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: steps,
    );
  }

  static String _humanInstruction(String type, String? modifier, String? name) {
    String base;
    switch (type) {
      case 'depart':
        base = 'Start';
        break;
      case 'arrive':
        base = 'Arrive';
        break;
      case 'turn':
        base = 'Turn';
        break;
      case 'roundabout':
        base = 'Take the roundabout';
        break;
      case 'merge':
        base = 'Merge';
        break;
      case 'on ramp':
        base = 'Enter ramp';
        break;
      case 'off ramp':
        base = 'Exit ramp';
        break;
      case 'fork':
        base = 'Keep';
        break;
      default:
        base = 'Continue';
    }

    final mod = (modifier ?? '').trim();
    final road = (name ?? '').trim();

    final parts = <String>[];
    parts.add(base);
    if (mod.isNotEmpty && base != 'Start' && base != 'Arrive') parts.add(mod);
    if (road.isNotEmpty && road != 'null') parts.add('onto $road');

    return parts.join(' ');
  }
}
