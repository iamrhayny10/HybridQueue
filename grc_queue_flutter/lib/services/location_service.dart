// lib/services/location_service.dart
//
// Geofencing for ticket issuance:
//   - Students must be within 200m of GRC to JOIN the queue
//   - Monitoring the live queue has NO location restriction
//
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

class LocationService {
  /// Check if student is within [AppConstants.issueRadiusMeters] of GRC.
  /// Returns null on success (within range), or an error message string.
  static Future<String?> checkWithinSchool() async {
    // DEV BYPASS — set AppConstants.skipLocationCheck = false before demo
    if (AppConstants.skipLocationCheck) return null;
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are turned off on your device. '
          'Please enable GPS to join the queue.';
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission was denied. '
            'The app needs your location to confirm you are at GRC '
            'before issuing a queue ticket.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. '
          'Please go to your device Settings → Apps → GRC Queue → '
          'Permissions → Location and allow it, then try again.';
    }

    // 3. Get current position (balanced accuracy, fast timeout)
    late Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return 'Could not get your location. Make sure GPS is on and '
          'you have a clear view of the sky, then try again.';
    }

    // 4. Calculate distance to GRC
    final distanceMeters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      AppConstants.schoolLat,
      AppConstants.schoolLng,
    );

    if (distanceMeters > AppConstants.issueRadiusMeters) {
      final km = (distanceMeters / 1000).toStringAsFixed(2);
      return 'You are ${km}km away from GRC. '
          'You must be within ${AppConstants.issueRadiusMeters.toInt()}m '
          'of the school to get a queue ticket.';
    }

    // Within range — allow ticket issuance
    return null;
  }
}
