import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  /// Calculate distance between two points in kilometers
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Check if distance is within a reasonable range for "nearby"
  static bool isNearby(double distanceKm, {double maxKm = 25.0}) {
    return distanceKm <= maxKm;
  }
}
