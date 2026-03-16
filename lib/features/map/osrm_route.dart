import 'package:latlong2/latlong.dart';

class OsrmRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const OsrmRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
