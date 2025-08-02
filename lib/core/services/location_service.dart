import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:rent_ease/core/config/environment_config.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static String get googleApiKey => EnvironmentConfig.googlePlacesApiKey;

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _formatAddress(place);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Search places using Google Places API
  Future<List<Prediction>> searchPlaces(String query) async {
    try {
      // This would typically use the Google Places API
      // For now, we'll return an empty list as the google_places_flutter
      // package handles the API calls internally
      return [];
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  /// Get place details from place ID
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      // This would use Google Places Details API
      // Implementation depends on the specific package being used
      return null;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  /// Parse address components from Google Places prediction
  Map<String, String> parseGooglePlaceAddress(String fullAddress) {
    final components = <String, String>{};
    final parts = fullAddress.split(', ');

    if (parts.isNotEmpty) {
      // For most addresses, the street address includes the first 1-2 parts
      // depending on the format (e.g., "360 Mall, Jassem Mohamed Al Kharafi Rd.")
      if (parts.length >= 3) {
        // If we have 3+ parts, combine first two as street address
        components['street'] = '${parts[0]}, ${parts[1]}';
      } else {
        // If only 1-2 parts, use the first part as street
        components['street'] = parts.first;
      }

      if (parts.length >= 2) {
        // Last part is usually country
        final country = parts.last;
        components['country'] = country;

        // Adjust parsing based on whether we used 1 or 2 parts for street
        final streetPartsUsed = parts.length >= 3 ? 2 : 1;
        final remainingParts = parts.sublist(streetPartsUsed, parts.length - 1);

        if (remainingParts.isNotEmpty) {
          // Parse based on country-specific patterns
          final secondToLast = parts[parts.length - 2];

          // Different postal code patterns for different countries
          RegExp? postalCodePattern;

          switch (country.toLowerCase()) {
            case 'united states':
            case 'usa':
            case 'us':
              // US: State abbreviation + ZIP (e.g., "CA 90210" or "NY 10001-1234")
              postalCodePattern =
                  RegExp(r'([A-Z]{2})\s+(\d{5}(?:-\d{4})?)\s*\$');
              break;
            case 'canada':
            case 'ca':
              // Canada: Province + Postal Code (e.g., "ON K1A 0A6")
              postalCodePattern =
                  RegExp(r'([A-Z]{2})\s+([A-Z]\d[A-Z]\s*\d[A-Z]\d)\s*\$');
              break;
            case 'united kingdom':
            case 'uk':
            case 'gb':
              // UK: Postcode at the end (e.g., "London SW1A 1AA")
              postalCodePattern =
                  RegExp(r'([A-Z]{1,2}\d[A-Z\d]?)\s*(\d[A-Z]{2})\s*\$');
              break;
            case 'australia':
            case 'au':
              // Australia: State + 4-digit postcode (e.g., "NSW 2000")
              postalCodePattern = RegExp(r'([A-Z]{2,3})\s+(\d{4})\s*\$');
              break;
            case 'germany':
            case 'de':
              // Germany: 5-digit postcode (e.g., "10115")
              postalCodePattern = RegExp(r'(\d{5})\s*\$');
              break;
            case 'france':
            case 'fr':
              // France: 5-digit postcode (e.g., "75001")
              postalCodePattern = RegExp(r'(\d{5})\s*\$');
              break;
            default:
              // Generic pattern for other countries
              postalCodePattern = RegExp(r'([A-Z0-9\s-]{3,10})\s*\$');
          }

          final match = postalCodePattern.firstMatch(secondToLast);

          if (match != null) {
            if (match.groupCount >= 2) {
              // Has both state/province and postal code
              components['state'] = match.group(1)?.trim() ?? '';
              components['postalCode'] = match.group(2)?.trim() ?? '';
            } else {
              // Only postal code
              components['postalCode'] = match.group(1)?.trim() ?? '';
              // Try to extract state/province from remaining text
              final remaining =
                  secondToLast.replaceFirst(match.group(0)!, '').trim();
              if (remaining.isNotEmpty) {
                components['state'] = remaining;
              }
            }
          } else {
            // No postal code pattern found, treat as state/province
            components['state'] = secondToLast;
          }

          // City is usually the part before state/country
          if (remainingParts.length >= 2) {
            components['city'] = remainingParts[remainingParts.length - 2];
          } else if (remainingParts.length == 1) {
            // Only one remaining part, could be city or state
            if (components['state']?.isEmpty ?? true) {
              components['city'] = remainingParts[0];
            }
          }
        }
      }
    }

    return components;
  }

  /// Validate address completeness
  bool isAddressComplete(Map<String, String> addressComponents) {
    final requiredFields = ['street', 'city', 'state', 'country'];
    return requiredFields.every((field) =>
        addressComponents.containsKey(field) &&
        addressComponents[field]!.isNotEmpty);
  }

  /// Format address for display
  String formatAddressForDisplay(Map<String, String> components) {
    final parts = <String>[];

    if (components['street']?.isNotEmpty == true) {
      parts.add(components['street']!);
    }
    if (components['city']?.isNotEmpty == true) {
      parts.add(components['city']!);
    }
    if (components['state']?.isNotEmpty == true &&
        components['postalCode']?.isNotEmpty == true) {
      parts.add('${components['state']} ${components['postalCode']}');
    } else if (components['state']?.isNotEmpty == true) {
      parts.add(components['state']!);
    }
    if (components['country']?.isNotEmpty == true) {
      parts.add(components['country']!);
    }

    return parts.join(', ');
  }

  /// Format address from placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
