import 'package:latlong2/latlong.dart';

class OsrmStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;

  const OsrmStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OsrmRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<OsrmStep> steps;

  const OsrmRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });
}
