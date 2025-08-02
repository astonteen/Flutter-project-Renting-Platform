import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:rent_ease/core/config/environment_config.dart';

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String instructions;
  final String? trafficDuration; // New: Duration considering traffic
  final List<String>? warnings; // New: Route warnings

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.instructions,
    this.trafficDuration,
    this.warnings,
  });
}

class DirectionsService {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Get driving directions between two points using Routes API v2
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String travelMode = 'DRIVE',
    bool includeTraffic = true,
  }) async {
    try {
      final String apiKey = EnvironmentConfig.googlePlacesApiKey;

      if (apiKey.isEmpty) {
        debugPrint('❌ Google API key not configured');
        return null;
      }

      // Build waypoints if provided
      List<Map<String, dynamic>>? intermediates;
      if (waypoints != null && waypoints.isNotEmpty) {
        intermediates = waypoints
            .map((point) => {
                  'location': {
                    'latLng': {
                      'latitude': point.latitude,
                      'longitude': point.longitude,
                    }
                  }
                })
            .toList();
      }

      // Request body for Routes API v2
      final requestBody = {
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            }
          }
        },
        if (intermediates != null) 'intermediates': intermediates,
        'travelMode': travelMode,
        'routingPreference':
            includeTraffic ? 'TRAFFIC_AWARE' : 'TRAFFIC_UNAWARE',
        'computeAlternativeRoutes': false,
        'routeModifiers': {
          'avoidTolls': false,
          'avoidHighways': false,
          'avoidFerries': false,
        },
        'languageCode': 'en-US',
        'units': 'METRIC',
      };

      debugPrint('🗺️ Fetching directions from Google Routes API v2...');

      final response = await _dio.post(
        _baseUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps.navigationInstruction,routes.warnings',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Extract polyline points
          final String? encodedPolyline = route['polyline']?['encodedPolyline'];
          if (encodedPolyline == null) {
            debugPrint('❌ No polyline data in response');
            return null;
          }

          final List<List<num>> decodedPoints = decodePolyline(encodedPolyline);
          final List<LatLng> polylinePoints = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          // Extract distance and duration
          final int? distanceMeters = route['distanceMeters'];
          final String? duration = route['duration'];

          final String distance = distanceMeters != null
              ? _formatDistance(distanceMeters)
              : 'Unknown distance';

          final String formattedDuration = duration != null
              ? _formatDurationFromString(duration)
              : 'Unknown duration';

          // Extract navigation instructions
          String instructions = '';
          if (route['legs'] != null) {
            final List<String> stepInstructions = [];
            for (final leg in route['legs']) {
              if (leg['steps'] != null) {
                for (final step in leg['steps']) {
                  final navInstruction =
                      step['navigationInstruction']?['instructions'];
                  if (navInstruction != null) {
                    stepInstructions.add(navInstruction);
                  }
                }
              }
            }
            instructions = stepInstructions.join('; ');
          }

          // Extract warnings
          List<String>? warnings;
          if (route['warnings'] != null) {
            warnings = List<String>.from(route['warnings']);
          }

          debugPrint(
              '✅ Successfully got directions: $distance, $formattedDuration');
          debugPrint('📍 Polyline points: ${polylinePoints.length}');
          if (warnings != null && warnings.isNotEmpty) {
            debugPrint('⚠️ Route warnings: ${warnings.join(', ')}');
          }

          return DirectionsResult(
            polylinePoints: polylinePoints,
            distance: distance,
            duration: formattedDuration,
            instructions: instructions.isEmpty
                ? 'No detailed instructions available'
                : instructions,
            warnings: warnings,
          );
        } else {
          debugPrint('❌ No routes found in response');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        debugPrint('❌ Response: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting directions: $e');
      return null;
    }
  }

  /// Get multi-leg directions (driver -> pickup -> delivery)
  Future<List<DirectionsResult>> getMultiLegDirections({
    required LatLng driverLocation,
    required LatLng pickupLocation,
    required LatLng deliveryLocation,
    bool includeTraffic = true,
  }) async {
    final List<DirectionsResult> results = [];

    try {
      // Leg 1: Driver to pickup
      final leg1 = await getDirections(
        origin: driverLocation,
        destination: pickupLocation,
        includeTraffic: includeTraffic,
      );
      if (leg1 != null) {
        results.add(leg1);
      }

      // Leg 2: Pickup to delivery
      final leg2 = await getDirections(
        origin: pickupLocation,
        destination: deliveryLocation,
        includeTraffic: includeTraffic,
      );
      if (leg2 != null) {
        results.add(leg2);
      }

      debugPrint('✅ Got ${results.length} direction legs');
      return results;
    } catch (e) {
      debugPrint('❌ Error getting multi-leg directions: $e');
      return results;
    }
  }

  /// Get optimized route for multiple stops using Routes API v2
  Future<DirectionsResult?> getOptimizedRoute({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    bool optimizeWaypoints = true,
    bool includeTraffic = true,
  }) async {
    try {
      final String apiKey = EnvironmentConfig.googlePlacesApiKey;

      if (apiKey.isEmpty) {
        debugPrint('❌ Google API key not configured');
        return null;
      }

      // Build intermediates for waypoints
      final intermediates = waypoints
          .map((point) => {
                'location': {
                  'latLng': {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  }
                }
              })
          .toList();

      // Request body for optimized route
      final requestBody = {
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            }
          }
        },
        'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'routingPreference':
            includeTraffic ? 'TRAFFIC_AWARE' : 'TRAFFIC_UNAWARE',
        'optimizeWaypointOrder': optimizeWaypoints,
        'routeModifiers': {
          'avoidTolls': false,
          'avoidHighways': false,
          'avoidFerries': false,
        },
        'languageCode': 'en-US',
        'units': 'METRIC',
      };

      debugPrint('🗺️ Fetching optimized route...');

      final response = await _dio.post(
        _baseUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.optimizedIntermediateWaypointIndex',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Extract polyline points
          final String? encodedPolyline = route['polyline']?['encodedPolyline'];
          if (encodedPolyline == null) {
            debugPrint('❌ No polyline data in response');
            return null;
          }

          final List<List<num>> decodedPoints = decodePolyline(encodedPolyline);
          final List<LatLng> polylinePoints = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          // Extract distance and duration
          final int? distanceMeters = route['distanceMeters'];
          final String? duration = route['duration'];

          final String distance = distanceMeters != null
              ? _formatDistance(distanceMeters)
              : 'Unknown distance';

          final String formattedDuration = duration != null
              ? _formatDurationFromString(duration)
              : 'Unknown duration';

          debugPrint(
              '✅ Successfully got optimized route: $distance, $formattedDuration');

          return DirectionsResult(
            polylinePoints: polylinePoints,
            distance: distance,
            duration: formattedDuration,
            instructions: 'Optimized route with ${waypoints.length} stops',
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting optimized route: $e');
      return null;
    }
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '${meters}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  String _formatDurationFromString(String duration) {
    // Duration comes in format like "1234s"
    final seconds = int.tryParse(duration.replaceAll('s', '')) ?? 0;
    return _formatDuration(seconds);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds / 60;
    if (minutes < 60) {
      return '${minutes.round()}min';
    } else {
      final hours = minutes / 60;
      final remainingMinutes = minutes % 60;
      return '${hours.floor()}h ${remainingMinutes.round()}min';
    }
  }
}
