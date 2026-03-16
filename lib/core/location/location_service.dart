import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<void> ensureReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it from settings.');
    }
  }

  static Future<Position> currentPosition() async {
    await ensureReady();
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
