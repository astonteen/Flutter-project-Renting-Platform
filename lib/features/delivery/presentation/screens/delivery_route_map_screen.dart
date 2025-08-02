import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/location_service.dart';
import 'package:rent_ease/core/services/directions_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'dart:async';

class DeliveryRouteMapScreen extends StatefulWidget {
  final DeliveryJobModel job;

  const DeliveryRouteMapScreen({
    super.key,
    required this.job,
  });

  @override
  State<DeliveryRouteMapScreen> createState() => _DeliveryRouteMapScreenState();
}

class _DeliveryRouteMapScreenState extends State<DeliveryRouteMapScreen> {
  GoogleMapController? _mapController;
  geo.Position? _currentPosition;
  final LocationService _locationService = LocationService();
  final DirectionsService _directionsService = DirectionsService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;

  // Default camera position
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(3.1390, 101.6869), // Kuala Lumpur default
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _setupMarkersAndRoute();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          );
        });
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  Future<void> _setupMarkersAndRoute() async {
    final Set<Marker> markers = {};

    // Driver's current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Driver current position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Pickup location marker
    if (widget.job.pickupLatitude != null &&
        widget.job.pickupLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position:
              LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.job.pickupAddress,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // Delivery location marker
    if (widget.job.deliveryLatitude != null &&
        widget.job.deliveryLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: LatLng(
              widget.job.deliveryLatitude!, widget.job.deliveryLongitude!),
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: widget.job.deliveryAddress,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Create route polylines
    await _createRoutePolylines();

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    // Fit all markers in view
    _fitMarkersInView();
  }

  Future<void> _createRoutePolylines() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRoute = true;
    });

    final Set<Polyline> polylines = {};
    double totalDistanceKm = 0;
    int totalDurationMin = 0;

    try {
      // Get actual road routes using Google Directions API
      if (_currentPosition != null &&
          widget.job.pickupLatitude != null &&
          widget.job.pickupLongitude != null &&
          widget.job.deliveryLatitude != null &&
          widget.job.deliveryLongitude != null) {
        final driverLocation =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        final pickupLocation =
            LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!);
        final deliveryLocation =
            LatLng(widget.job.deliveryLatitude!, widget.job.deliveryLongitude!);

        // Get multi-leg directions
        final directions = await _directionsService.getMultiLegDirections(
          driverLocation: driverLocation,
          pickupLocation: pickupLocation,
          deliveryLocation: deliveryLocation,
        );

        if (directions.isNotEmpty) {
          // Route 1: Driver to pickup (dashed blue line)
          if (directions.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('driver_to_pickup'),
                points: directions[0].polylinePoints,
                color: Colors.blue,
                width: 5,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );

            // Extract distance value for calculation
            final distanceText = directions[0].distance;
            final distanceValue = _extractDistanceValue(distanceText);
            totalDistanceKm += distanceValue;

            final durationText = directions[0].duration;
            final durationValue = _extractDurationValue(durationText);
            totalDurationMin += durationValue;
          }

          // Route 2: Pickup to delivery (solid green line)
          if (directions.length > 1) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('pickup_to_delivery'),
                points: directions[1].polylinePoints,
                color: ColorConstants.primaryColor,
                width: 6,
              ),
            );

            // Extract distance value for calculation
            final distanceText = directions[1].distance;
            final distanceValue = _extractDistanceValue(distanceText);
            totalDistanceKm += distanceValue;

            final durationText = directions[1].duration;
            final durationValue = _extractDurationValue(durationText);
            totalDurationMin += durationValue;
          }

          // Update route info
          _routeDistance = _formatDistance(totalDistanceKm);
          _routeDuration = '${totalDurationMin}min';

          debugPrint('✅ Created road routes: $_routeDistance, $_routeDuration');
        } else {
          debugPrint(
              '❌ No directions received, falling back to straight lines');
          _createFallbackRoutes(polylines);
        }
      } else {
        debugPrint('❌ Missing coordinates, creating fallback routes');
        _createFallbackRoutes(polylines);
      }
    } catch (e) {
      debugPrint('❌ Error creating routes: $e');
      _createFallbackRoutes(polylines);
    }

    if (mounted) {
      setState(() {
        _polylines = polylines;
        _isLoadingRoute = false;
      });
    }
  }

  void _createFallbackRoutes(Set<Polyline> polylines) {
    // Fallback to straight lines if directions API fails
    if (_currentPosition != null &&
        widget.job.pickupLatitude != null &&
        widget.job.pickupLongitude != null) {
      final List<LatLng> driverToPickupRoute = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!),
      ];

      polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_pickup'),
          points: driverToPickupRoute,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    if (widget.job.pickupLatitude != null &&
        widget.job.pickupLongitude != null &&
        widget.job.deliveryLatitude != null &&
        widget.job.deliveryLongitude != null) {
      final List<LatLng> pickupToDeliveryRoute = [
        LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!),
        LatLng(widget.job.deliveryLatitude!, widget.job.deliveryLongitude!),
      ];

      polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_delivery'),
          points: pickupToDeliveryRoute,
          color: ColorConstants.primaryColor,
          width: 6,
        ),
      );
    }
  }

  double _extractDistanceValue(String distanceText) {
    // Extract numeric value from distance text like "5.2 km" or "1,200 m"
    final regex = RegExp(r'([\d.,]+)\s*(km|m)');
    final match = regex.firstMatch(distanceText.toLowerCase());

    if (match != null) {
      final value =
          double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0') ?? 0;
      final unit = match.group(2);

      if (unit == 'km') {
        return value;
      } else if (unit == 'm') {
        return value / 1000; // Convert meters to kilometers
      }
    }

    return 0;
  }

  int _extractDurationValue(String durationText) {
    // Extract numeric value from duration text like "15 mins" or "1 hour 30 mins"
    int totalMinutes = 0;

    // Extract hours
    final hourRegex = RegExp(r'(\d+)\s*h');
    final hourMatch = hourRegex.firstMatch(durationText.toLowerCase());
    if (hourMatch != null) {
      totalMinutes += (int.tryParse(hourMatch.group(1) ?? '0') ?? 0) * 60;
    }

    // Extract minutes
    final minRegex = RegExp(r'(\d+)\s*min');
    final minMatch = minRegex.firstMatch(durationText.toLowerCase());
    if (minMatch != null) {
      totalMinutes += int.tryParse(minMatch.group(1) ?? '0') ?? 0;
    }

    return totalMinutes;
  }

  void _fitMarkersInView() {
    if (_markers.length < 2 || _mapController == null) return;

    final List<LatLng> positions =
        _markers.map((marker) => marker.position).toList();

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

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return geo.Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert to kilometers
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route - ${widget.job.itemName}'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _fitMarkersInView();
            },
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false, // Reduce memory usage
            trafficEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false, // Disable indoor maps
            scrollGesturesEnabled: true, // Allow panning
            zoomGesturesEnabled: true, // Allow zooming
            rotateGesturesEnabled: false, // Reduce gesture complexity
            tiltGesturesEnabled: false, // Reduce 3D rendering
            liteModeEnabled: false, // Keep interactive mode for navigation
          ),

          // Route info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildRouteInfoCard(),
          ),

          // Action buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildActionButtons(),
          ),

          // My location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _centerOnDriverLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    // Use real route data if available, otherwise calculate estimated distance
    String displayDistance;
    String displayDuration;

    if (_routeDistance != null && _routeDuration != null) {
      // Use real Google Directions data
      displayDistance = _routeDistance!;
      displayDuration = _routeDuration!;
    } else {
      // Calculate estimated distance as fallback
      double totalDistance = 0;
      int estimatedTime = 0;

      if (_currentPosition != null &&
          widget.job.pickupLatitude != null &&
          widget.job.pickupLongitude != null) {
        final driverToPickup = _calculateDistance(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!),
        );
        totalDistance += driverToPickup;
      }

      if (widget.job.pickupLatitude != null &&
          widget.job.pickupLongitude != null &&
          widget.job.deliveryLatitude != null &&
          widget.job.deliveryLongitude != null) {
        final pickupToDelivery = _calculateDistance(
          LatLng(widget.job.pickupLatitude!, widget.job.pickupLongitude!),
          LatLng(widget.job.deliveryLatitude!, widget.job.deliveryLongitude!),
        );
        totalDistance += pickupToDelivery;
      }

      estimatedTime = (totalDistance * 3).round(); // ~3 minutes per km
      displayDistance = _formatDistance(totalDistance);
      displayDuration = '${estimatedTime}min';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: ColorConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Route',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Order #${widget.job.id.substring(0, 8)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: _isLoadingRoute ? '...' : displayDistance,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: _isLoadingRoute ? '...' : displayDuration,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.attach_money,
                  label: '\$${widget.job.fee.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Start navigation button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _startNavigation,
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: const Text(
              'Start Navigation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Route options
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRouteOptions,
                icon: const Icon(Icons.alt_route, size: 18),
                label: const Text('Route Options'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareRoute,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Route'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _centerOnDriverLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _startNavigation() {
    // TODO: Integrate with Google Maps navigation or in-app navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation starting...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRouteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Route Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Fastest Route'),
              subtitle: const Text('Optimized for time'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.eco),
              title: const Text('Eco Route'),
              subtitle: const Text('Fuel efficient'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.traffic),
              title: const Text('Avoid Traffic'),
              subtitle: const Text('Less congestion'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRoute() {
    // TODO: Implement route sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route shared!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
