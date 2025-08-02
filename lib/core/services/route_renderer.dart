import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

/// Helper class for rendering delivery routes on Google Maps
class RouteRenderer {
  static const double kDriverMarkerHue = BitmapDescriptor.hueBlue;
  static const double kPickupMarkerHue = BitmapDescriptor.hueOrange;
  static const double kDeliveryMarkerHue = BitmapDescriptor.hueGreen;

  static const double kDriverToPickupPolylineWidth = 5.0;
  static const double kPickupToDeliveryPolylineWidth = 6.0;

  static const int kPolylineDashLength = 20;
  static const int kPolylineGapLength = 10;

  /// Create markers for driver location, pickup, and delivery
  static Set<Marker> createRouteMarkers({
    required LatLng driverLocation,
    required LatLng pickupLocation,
    required LatLng deliveryLocation,
    required DeliveryJobModel job,
  }) {
    final Set<Marker> markers = {};

    // Driver location marker
    markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: driverLocation,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Driver current position',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(kDriverMarkerHue),
      ),
    );

    // Pickup location marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_location'),
        position: pickupLocation,
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: job.pickupAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(kPickupMarkerHue),
      ),
    );

    // Delivery location marker
    markers.add(
      Marker(
        markerId: const MarkerId('delivery_location'),
        position: deliveryLocation,
        infoWindow: InfoWindow(
          title: 'Delivery Location',
          snippet: job.deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(kDeliveryMarkerHue),
      ),
    );

    return markers;
  }

  /// Create polylines for route display
  static Set<Polyline> createRoutePolylines({
    required List<dynamic> directions,
  }) {
    final Set<Polyline> polylines = {};

    if (directions.isEmpty) return polylines;

    // Driver to pickup route (dashed blue)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('driver_to_pickup'),
        points: directions[0].polylinePoints,
        color: const Color(0xFF2196F3), // Bright blue
        width: kDriverToPickupPolylineWidth.toInt(),
        patterns: [
          PatternItem.dash(kPolylineDashLength.toDouble()),
          PatternItem.gap(kPolylineGapLength.toDouble())
        ],
      ),
    );

    // Pickup to delivery route (solid primary color)
    if (directions.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_delivery'),
          points: directions[1].polylinePoints,
          color: ColorConstants.primaryColor,
          width: kPickupToDeliveryPolylineWidth.toInt(),
        ),
      );
    }

    return polylines;
  }

  /// Calculate bounds for fitting route markers in view
  static LatLngBounds calculateRouteBounds({
    required Set<Marker> markers,
  }) {
    if (markers.isEmpty) {
      throw ArgumentError('Cannot calculate bounds for empty marker set');
    }

    final positions = markers.map((marker) => marker.position).toList();

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
