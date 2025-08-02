import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/location_service.dart';
import 'package:rent_ease/core/services/directions_service.dart';
import 'package:rent_ease/core/services/route_renderer.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DriverDashboardView extends StatefulWidget {
  final String driverId;
  final Map<String, dynamic>? routeData;

  const DriverDashboardView({
    super.key,
    required this.driverId,
    this.routeData,
  });

  @override
  State<DriverDashboardView> createState() => _DriverDashboardViewState();
}

class _DriverDashboardViewState extends State<DriverDashboardView>
    with TickerProviderStateMixin {
  late DeliveryBloc _deliveryBloc;
  GoogleMapController? _mapController;
  geo.Position? _currentPosition;
  final LocationService _locationService = LocationService();
  final DirectionsService _directionsService = DirectionsService();

  // Route display state
  Set<Marker> _routeMarkers = {};
  Set<Polyline> _routePolylines = {};
  DeliveryJobModel? _selectedJob;
  bool _isLoadingRoute = false;
  List<DeliveryJobModel> _lastKnownJobs = [];
  String? _routeDistance;
  String? _routeDuration;

  // Cached profile and metrics data
  DriverProfileModel? _cachedProfile;
  Map<String, dynamic>? _cachedMetrics;

  // Default location (will be updated with driver's current location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _deliveryBloc = context.read<DeliveryBloc>();
    debugPrint(
        'DriverDashboardView using DeliveryBloc: ${_deliveryBloc.hashCode}');
    _getCurrentLocation();
    _loadInitialData();

    // Check for route arguments after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRouteArguments();
    });
  }

  void _checkForRouteArguments() {
    final args = widget.routeData ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?);

    if (args != null && args['showRoute'] == true && args['jobId'] != null) {
      final jobId = args['jobId'] as String;
      debugPrint('🗺️ Showing route for job: $jobId');
      _waitForJobDataAndShowRoute(jobId);
    }
  }

  void _waitForJobDataAndShowRoute(String jobId) {
    debugPrint('🔄 Looking for job: $jobId');

    // Try to find the job immediately first
    final currentState = _deliveryBloc.state;
    List<DeliveryJobModel>? jobs = _getJobsFromState(currentState);
    if (jobs != null) {
      debugPrint('📋 Available jobs: ${jobs.map((j) => j.id).toList()}');
      final job = _findJobById(jobs, jobId);
      if (job != null) {
        debugPrint('✅ Found job immediately: ${job.id} - ${job.itemName}');
        _displayRoute(job);
        return;
      }
    }

    // If not found, wait for job data to load
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final currentState = _deliveryBloc.state;
      debugPrint('🔍 Current state type: ${currentState.runtimeType}');

      List<DeliveryJobModel>? jobs = _getJobsFromState(currentState);
      if (jobs != null) {
        debugPrint('📋 Checking jobs: ${jobs.map((j) => j.id).toList()}');
        final job = _findJobById(jobs, jobId);
        if (job != null) {
          debugPrint('✅ Found job: ${job.id} - ${job.itemName}');
          timer.cancel();
          _displayRoute(job);
          return;
        }
      }

      // Cancel timer after 5 seconds
      if (timer.tick > 10) {
        timer.cancel();
        debugPrint('❌ Could not find job: $jobId');
        debugPrint('📋 Final state type: ${currentState.runtimeType}');
        debugPrint(
            '📋 Available jobs were: ${jobs?.map((j) => j.id).toList() ?? "none"}');
      }
    });
  }

  List<DeliveryJobModel>? _getJobsFromState(DeliveryState state) {
    if (state is DriverJobsLoaded) {
      return state.jobs;
    } else if (state is DeliveryLoaded) {
      return state.driverJobs;
    }
    // Check if we have any cached jobs from a previous DeliveryLoaded state
    // This helps when state transitions to other states like DriverMetricsLoaded
    if (_lastKnownJobs.isNotEmpty) {
      debugPrint(
          '🔄 Using cached jobs: ${_lastKnownJobs.map((j) => j.id.substring(0, 8)).toList()}');
      return _lastKnownJobs;
    }
    return null;
  }

  DeliveryJobModel? _findJobById(List<DeliveryJobModel> jobs, String jobId) {
    debugPrint('🔍 Looking for jobId: $jobId in ${jobs.length} jobs');

    // Try exact match first
    for (final job in jobs) {
      debugPrint('🔍 Comparing: $jobId == ${job.id} ? ${job.id == jobId}');
      if (job.id == jobId) return job;
    }

    // Try prefix match (first 8 characters of the search ID)
    final shortId = jobId.length >= 8 ? jobId.substring(0, 8) : jobId;
    debugPrint('🔍 Trying prefix match with: $shortId');
    for (final job in jobs) {
      debugPrint(
          '🔍 Does ${job.id} start with $shortId? ${job.id.startsWith(shortId)}');
      if (job.id.startsWith(shortId)) return job;
    }

    // Try reverse - if job ID is shorter, see if search ID starts with job ID
    for (final job in jobs) {
      if (jobId.startsWith(job.id)) {
        debugPrint('🔍 Reverse match: $jobId starts with ${job.id}');
        return job;
      }
    }

    debugPrint('❌ No match found for: $jobId');
    return null;
  }

  void _displayRoute(DeliveryJobModel job) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        debugPrint('🗺️ Displaying route for ${job.itemName}');
        showJobRoute(job);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          );
        });

        // Update map camera if controller is available
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(_initialCameraPosition),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  void _loadInitialData() {
    // Load driver profile and metrics
    debugPrint('🔄 Loading driver profile for: ${widget.driverId}');
    _deliveryBloc.add(LoadDriverProfile(widget.driverId));

    debugPrint('🔄 Loading driver metrics for: ${widget.driverId}');
    _deliveryBloc.add(LoadDriverMetrics(widget.driverId));

    // Load data with a delay to prevent overwhelming the connection
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _deliveryBloc.add(LoadDriverJobs(widget.driverId));
      }
    });

    // Removed the delayed LoadAvailableJobs call to prevent driverJobs from being overwritten
  }

  void refreshData() {
    debugPrint('🔄 Refreshing all driver data...');
    _loadInitialData();
  }

  /// Display route for a specific delivery job on the map
  Future<void> showJobRoute(DeliveryJobModel job) async {
    // Ensure we have the driver's current location before proceeding
    if (_currentPosition == null) {
      // Attempt to retrieve the current location again
      await _getCurrentLocation();
    }

    if (_currentPosition == null) {
      // Still unable to obtain the location – show error and exit
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (job.pickupLatitude == null ||
        job.pickupLongitude == null ||
        job.deliveryLatitude == null ||
        job.deliveryLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job coordinates not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _selectedJob = job;
    });

    try {
      final driverLocation =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final pickupLocation = LatLng(job.pickupLatitude!, job.pickupLongitude!);
      final deliveryLocation =
          LatLng(job.deliveryLatitude!, job.deliveryLongitude!);

      // Get route directions
      final directions = await _directionsService.getMultiLegDirections(
        driverLocation: driverLocation,
        pickupLocation: pickupLocation,
        deliveryLocation: deliveryLocation,
      );

      if (directions.isNotEmpty && mounted) {
        // Use RouteRenderer helper to create markers and polylines
        final markers = RouteRenderer.createRouteMarkers(
          driverLocation: driverLocation,
          pickupLocation: pickupLocation,
          deliveryLocation: deliveryLocation,
          job: job,
        );

        final polylines = RouteRenderer.createRoutePolylines(
          directions: directions,
        );

        setState(() {
          _routeMarkers = markers;
          _routePolylines = polylines;
        });

        // Update map padding when route is displayed
        _updateMapPadding();

        // Fit route in view
        _fitRouteInView();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route displayed for ${job.itemName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load route'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  /// Clear route display from the map
  void clearRoute() {
    HapticFeedback.mediumImpact();
    setState(() {
      _routeMarkers = {};
      _routePolylines = {};
      _selectedJob = null;
      _isLoadingRoute = false;
      _routeDistance = null;
      _routeDuration = null;
    });

    // Reset map padding when route is cleared
    _updateMapPadding();
  }

  /// Fit the route markers in view
  void _fitRouteInView() {
    if (_routeMarkers.length < 2 || _mapController == null) return;

    final bounds = RouteRenderer.calculateRouteBounds(markers: _routeMarkers);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        100.0, // padding
      ),
    );
  }

  /// Update map padding to avoid UI overlap
  void _updateMapPadding() {
    if (_mapController == null) return;

    // Note: setPadding is not available in google_maps_flutter
    // This method is kept for future enhancement when padding support is added
    // For now, we rely on proper UI positioning to avoid overlap
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DeliveryLoading) {
          // Show a loading indicator, perhaps a dialog
          // Be careful not to show it for all loading states, maybe check for a specific action type
        } else if (state is CashOutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is DeliveryError &&
            state.errorType == 'cashout_failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Driver Dashboard',
            style: TextStyle(
              color: ColorConstants.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: ColorConstants.primaryColor,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: ColorConstants.white),
              onPressed: refreshData,
              tooltip: 'Refresh Data',
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: ColorConstants.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            debugPrint(
                '🏗️ Dashboard building with state: ${state.runtimeType}');

            // Cache driver jobs when they're available
            if (state is DeliveryLoaded && state.driverJobs.isNotEmpty) {
              _lastKnownJobs = state.driverJobs;
              debugPrint('💾 Cached ${_lastKnownJobs.length} driver jobs');
            }

            // Cache profile and metrics data
            if (state is DriverProfileLoaded) {
              _cachedProfile = state.profile;
              debugPrint(
                  '💾 Cached driver profile data - earnings: ${_cachedProfile!.totalEarnings}, vehicle: ${_cachedProfile!.vehicleModel}');
            }
            if (state is DriverMetricsLoaded) {
              _cachedMetrics = state.metrics;
              debugPrint('💾 Cached driver metrics data: $_cachedMetrics');
            }

            // Check if driver is online/offline
            bool isOnline =
                false; // Default to offline to prevent auto-online behavior

            if (state is DriverAvailabilityUpdated) {
              isOnline = state.isAvailable;
            } else if (state is DriverAvailabilityEnhancedUpdated) {
              isOnline = state.isAvailable;
            } else if (state is DriverProfileLoaded) {
              isOnline = state.profile.isAvailable;
            } else if (_cachedProfile != null) {
              // Use cached profile availability if no specific state
              isOnline = _cachedProfile!.isAvailable;
            }

            // Show loading when data is being fetched
            if (state is DeliveryLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConstants.primaryColor),
                ),
              );
            }

            // If online, show fullscreen map
            if (isOnline) {
              return _buildFullscreenMapView();
            }

            // If offline, show cards view
            return _buildCardsView();
          },
        ),
      ), // This closes the Scaffold
    ); // This closes the BlocListener
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        double availableBalance = 0.0;

        // Use cached metrics data for more up-to-date earnings
        if (_cachedMetrics != null) {
          availableBalance =
              (_cachedMetrics!['available_balance'] ?? 0.0).toDouble();
          debugPrint(
              '💰 Balance card using cached metrics with available balance: $availableBalance');
        } else if (state is DriverMetricsLoaded) {
          availableBalance =
              (state.metrics['available_balance'] ?? 0.0).toDouble();
          debugPrint(
              '💰 Balance card loaded metrics with available balance: $availableBalance');
        } else if (_cachedProfile != null) {
          // Fallback to cached profile if metrics are not available
          availableBalance = _cachedProfile!.totalEarnings;
          debugPrint(
              '💰 Balance card using fallback cached profile with earnings: $availableBalance');
        } else if (state is DriverProfileLoaded) {
          // Fallback to loaded profile if metrics are not available
          availableBalance = state.profile.totalEarnings;
          debugPrint(
              '💰 Balance card using fallback loaded profile with earnings: $availableBalance');
        } else {
          debugPrint(
              '💰 Balance card - no balance data available, current: ${state.runtimeType}');
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.veryLightGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: ColorConstants.secondaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${availableBalance.toStringAsFixed(0)}\$',
                    style: const TextStyle(
                      color: ColorConstants.primaryTextColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showCashOutDialog(context, availableBalance),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: ColorConstants.darkGrey,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'cash out',
                        style: TextStyle(
                          color: ColorConstants.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: ColorConstants.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCashOutDialog(BuildContext context, double availableBalance) {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cash Out'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Available to cash out: \$${availableBalance.toStringAsFixed(2)}'),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount to cash out',
                    prefixText: '\$',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final double? amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount <= 0) {
                      return 'Amount must be positive';
                    }
                    if (amount > availableBalance) {
                      return 'Amount cannot exceed your available balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final double amount = double.parse(amountController.text);
                  Navigator.of(dialogContext).pop();
                  _initiateCashOut(context, amount);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _initiateCashOut(BuildContext context, double amount) {
    // Use the driver ID from the widget
    final driverId = widget.driverId;
    if (driverId.isNotEmpty) {
      debugPrint(
          '💳 Initiating cash out for driver: $driverId, amount: \$${amount.toStringAsFixed(2)}');
      _deliveryBloc.add(CashOut(driverId, amount));
    } else {
      debugPrint('❌ Driver ID not available for cash out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to process cash out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRatingCard() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        double rating = 0.0; // Default to 0 instead of 4.8
        int totalDeliveries = 0;

        // Use cached profile data if available
        if (_cachedProfile != null) {
          rating = _cachedProfile!.averageRating;
          totalDeliveries = _cachedProfile!.totalDeliveries;
          debugPrint(
              '⭐ Rating card using cached profile - rating: $rating, deliveries: $totalDeliveries');
        } else if (state is DriverProfileLoaded) {
          rating = state.profile.averageRating;
          totalDeliveries = state.profile.totalDeliveries;
          debugPrint(
              '⭐ Rating card loaded profile - rating: $rating, deliveries: $totalDeliveries');
        } else {
          debugPrint(
              '⭐ Rating card - no profile data available, current: ${state.runtimeType}');
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.darkGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating',
                style: TextStyle(
                  color: ColorConstants.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: ColorConstants.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripsCard() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        int todaySuccessfulDeliveries = 0;

        if (_cachedMetrics != null) {
          todaySuccessfulDeliveries = _cachedMetrics!['today_deliveries'] ?? 0;
        } else if (state is DriverMetricsLoaded) {
          todaySuccessfulDeliveries = state.metrics['today_deliveries'] ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.veryLightGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Successful deliveries today',
                style: TextStyle(
                  color: ColorConstants.secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                todaySuccessfulDeliveries.toString(),
                style: const TextStyle(
                  color: ColorConstants.primaryTextColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYourCarCard() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        String vehicleModel = 'No vehicle registered';
        IconData vehicleIcon = Icons.directions_car_filled;
        bool hasVehicleData = false;

        // Use cached profile data if available
        final profile = _cachedProfile ??
            (state is DriverProfileLoaded ? state.profile : null);

        if (profile != null) {
          hasVehicleData = profile.vehicleModel?.isNotEmpty == true;
          debugPrint(
              '🚗 Vehicle card using profile - model: ${profile.vehicleModel}, hasData: $hasVehicleData');

          if (hasVehicleData) {
            vehicleModel = profile.vehicleModel!;

            // Set appropriate icon based on vehicle type
            switch (profile.vehicleType) {
              case VehicleType.motorcycle:
                vehicleIcon = Icons.motorcycle;
                break;
              case VehicleType.bike:
                vehicleIcon = Icons.pedal_bike;
                break;
              case VehicleType.van:
                vehicleIcon = Icons.airport_shuttle;
                break;
              case VehicleType.car:
                vehicleIcon = Icons.directions_car_filled;
            }
          } else {
            // Driver profile exists but no vehicle model
            vehicleModel = 'Add vehicle info';
            vehicleIcon = Icons.add_circle_outline;
          }
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.veryLightGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your car',
                style: TextStyle(
                  color: ColorConstants.secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              // Vehicle icon and model in same layout as tips card
              Row(
                children: [
                  Icon(
                    vehicleIcon,
                    size: 24,
                    color: hasVehicleData
                        ? ColorConstants.primaryTextColor.withValues(alpha: 0.8)
                        : ColorConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vehicleModel,
                      style: TextStyle(
                        color: hasVehicleData
                            ? ColorConstants.primaryTextColor
                            : ColorConstants.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyIncomeCard() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        double todayEarnings = 0.0;

        // Use cached metrics data if available
        if (_cachedMetrics != null) {
          todayEarnings = _cachedMetrics!['today_earnings']?.toDouble() ?? 0.0;
        } else if (state is DriverMetricsLoaded) {
          todayEarnings = state.metrics['today_earnings']?.toDouble() ?? 0.0;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.darkGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Earnings',
                style: TextStyle(
                  color: ColorConstants.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${todayEarnings.toStringAsFixed(0)}\$',
                style: const TextStyle(
                  color: ColorConstants.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyIncomeChart() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        List<ChartData> chartData = [
          ChartData('09', 0),
          ChartData('10', 0),
          ChartData('11', 0),
          ChartData('12', 0),
          ChartData('13', 0),
          ChartData('14', 0),
          ChartData('15', 0),
          ChartData('16', 0),
        ];

        // Get real metrics if available - use cached data if available
        final metrics = _cachedMetrics ??
            (state is DriverMetricsLoaded ? state.metrics : null);

        double weekEarnings = 0.0;

        if (metrics != null) {
          weekEarnings = metrics['week_earnings']?.toDouble() ?? 0.0;

          // If we have daily breakdown data, use it
          final dailyData = metrics['daily_earnings'] as Map<String, dynamic>?;
          if (dailyData != null && dailyData.isNotEmpty) {
            // Get current week's days
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

            chartData = [];
            for (int i = 0; i < 7; i++) {
              final day = startOfWeek.add(Duration(days: i));
              final dayKey = 'day_${day.day}';
              final dayLabel = day.day.toString().padLeft(2, '0');
              final earnings = (dailyData[dayKey] ?? 0).toDouble();
              chartData.add(ChartData(dayLabel, earnings));
            }
          } else {
            // Fallback to simulated data
            final simulatedData = [12.0, 18.0, 24.0, 15.0, 30.0, 22.0, 28.0];
            chartData = [];
            for (int i = 0; i < 8; i++) {
              final dayLabel = (9 + i).toString();
              final earnings =
                  i < simulatedData.length ? simulatedData[i] : 0.0;
              chartData.add(ChartData(dayLabel, earnings));
            }
            // Calculate week earnings from simulated data
            weekEarnings =
                simulatedData.fold(0.0, (sum, earnings) => sum + earnings);
          }
        } else {
          // No metrics available, use default
          weekEarnings = 149.0; // Default weekly earnings
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.darkGrey, // Use theme color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly income',
                style: TextStyle(
                  color: ColorConstants.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${weekEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: ColorConstants.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(width: 0),
                    labelStyle: TextStyle(
                      color: ColorConstants.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: const NumericAxis(
                    isVisible: false,
                    axisLine: AxisLine(width: 0),
                    majorTickLines: MajorTickLines(width: 0),
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  plotAreaBorderWidth: 0,
                  backgroundColor: Colors.transparent,
                  series: <CartesianSeries<ChartData, String>>[
                    ColumnSeries<ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.day,
                      yValueMapper: (ChartData data, _) => data.income,
                      pointColorMapper: (ChartData data, _) => data.income > 0
                          ? ColorConstants.successColor
                          : ColorConstants.errorColor,
                      borderRadius: BorderRadius.circular(4),
                      width: 0.6,
                      spacing: 0.1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullscreenMapView() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Google Maps - Now takes full screen
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // Set dynamic padding to avoid UI overlap
              _updateMapPadding();
              // Update camera to current location if available
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      zoom: 16.0,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: _initialCameraPosition,
            markers: _routeMarkers,
            polylines: _routePolylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false, // Disabled to reduce memory usage
            trafficEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false, // Disable indoor maps
            liteModeEnabled: false, // Keep interactive mode for navigation
            mapType: MapType.normal,
            scrollGesturesEnabled: true, // Allow panning
            zoomGesturesEnabled: true, // Allow zooming
            rotateGesturesEnabled: false, // Reduce gesture complexity
            tiltGesturesEnabled: false, // Reduce 3D rendering
            // Remove custom style to reduce processing overhead
          ),
          // Enhanced online status indicator (top-right)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ONLINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Distance/ETA chip (top-left)
          if (_selectedJob != null &&
              !_isLoadingRoute &&
              _routeDistance != null)
            Positioned(
              top: 90,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.navigation,
                      size: 16,
                      color: ColorConstants.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_routeDistance • $_routeDuration',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Clear route FAB (bottom-right, above go offline)
          if (_selectedJob != null)
            Positioned(
              bottom: 160, // Above go offline button
              right: 16,
              child: FloatingActionButton.small(
                onPressed: clearRoute,
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                elevation: 4,
                child: const Icon(Icons.close, size: 20),
              ),
            ),

          // Enhanced go offline button (bottom-right)
          Positioned(
            bottom: 100, // Above bottom nav
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _deliveryBloc
                        .add(UpdateDriverAvailability(widget.driverId, false));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.stop,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Go Offline',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView() {
    return Column(
      children: [
        _buildDriverStatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildRatingCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTripsCard()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildYourCarCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDailyIncomeCard()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeeklyIncomeChart(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Event Handlers
  Widget _buildDriverStatusBar() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        bool isOnline =
            false; // Default to offline to prevent auto-online behavior

        if (state is DriverAvailabilityUpdated) {
          isOnline = state.isAvailable;
        } else if (state is DriverAvailabilityEnhancedUpdated) {
          isOnline = state.isAvailable;
        } else if (state is DriverProfileLoaded) {
          isOnline = state.profile.isAvailable;
        } else if (_cachedProfile != null) {
          // Use cached profile availability if no specific state
          isOnline = _cachedProfile!.isAvailable;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isOnline
                ? ColorConstants.successColor.withValues(alpha: 0.1)
                : ColorConstants.warningColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOnline
                  ? ColorConstants.successColor.withValues(alpha: 0.2)
                  : ColorConstants.warningColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status indicator dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline
                      ? ColorConstants.successColor
                      : ColorConstants.warningColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? ColorConstants.successColor
                            : ColorConstants.warningColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? 'Ready to receive delivery requests'
                          : 'Not receiving jobs',
                      style: const TextStyle(
                        color: ColorConstants.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Modern toggle switch
              Switch.adaptive(
                value: isOnline,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  _deliveryBloc
                      .add(UpdateDriverAvailability(widget.driverId, value));
                },
                activeColor: ColorConstants.successColor,
                inactiveThumbColor: ColorConstants.warningColor,
                inactiveTrackColor:
                    ColorConstants.warningColor.withValues(alpha: 0.3),
                activeTrackColor:
                    ColorConstants.successColor.withValues(alpha: 0.3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChartData {
  ChartData(this.day, this.income);
  final String day;
  final double income;
}
