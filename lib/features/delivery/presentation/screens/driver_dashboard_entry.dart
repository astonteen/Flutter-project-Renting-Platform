import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/presentation/screens/driver_dashboard_view.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';

class DriverDashboardEntry extends StatefulWidget {
  final Map<String, dynamic>? routeData;

  const DriverDashboardEntry({super.key, this.routeData});

  @override
  State<DriverDashboardEntry> createState() => _DriverDashboardEntryState();
}

class _DriverDashboardEntryState extends State<DriverDashboardEntry> {
  String? _currentUserId;
  DriverProfileModel? _driverProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _loadDriverProfile();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadDriverProfile() {
    if (_currentUserId != null) {
      context.read<DeliveryBloc>().add(LoadDriverProfile(_currentUserId!));
    }
  }

  void _handleBecomeDriver() {
    context.go('/driver-registration');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DriverProfileLoaded) {
          setState(() {
            _driverProfile = state.profile;
            _isLoading = false;
          });
        } else if (state is DriverProfileCreated) {
          setState(() {
            _driverProfile = state.profile;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to the driver dashboard!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is DeliveryError &&
            state.errorType == 'profile_not_found') {
          setState(() {
            _isLoading = false;
          });
        } else if (state is DeliveryError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (_isLoading) {
          return const Scaffold(
            body: LoadingWidget(),
          );
        }

        // If user has driver profile, show enhanced driver dashboard
        if (_driverProfile != null && _currentUserId != null) {
          return DriverDashboardView(
            driverId: _currentUserId!,
            routeData: widget.routeData,
          );
        }

        // If user doesn't have driver profile, show become driver prompt
        return _buildBecomeDriverScreen();
      },
    );
  }

  Widget _buildBecomeDriverScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: NavigationHelper.createHamburgerMenuBackButton(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dynamic Icon and Status
            _buildDriverStatusIcon(),
            const SizedBox(height: 32),

            // Dynamic Title and Description
            _buildDynamicContent(),
            const SizedBox(height: 32),

            // Dynamic Benefits/Features
            _buildDynamicFeatures(),
            const SizedBox(height: 48),

            // Dynamic Action Button
            _buildDynamicActionButton(),
            const SizedBox(height: 16),

            // Back Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStatusIcon() {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    if (_driverProfile != null) {
      if (_driverProfile!.isActive) {
        iconData = Icons.delivery_dining;
        iconColor = Colors.green[600]!;
        backgroundColor = Colors.green[100]!;
      } else {
        iconData = Icons.pause_circle_outline;
        iconColor = Colors.orange[600]!;
        backgroundColor = Colors.orange[100]!;
      }
    } else {
      iconData = Icons.local_shipping_outlined;
      iconColor = ColorConstants.primaryColor;
      backgroundColor = ColorConstants.primaryColor.withValues(alpha: 0.1);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 60,
        color: iconColor,
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (_driverProfile != null) {
      return Column(
        children: [
          const Text(
            'Welcome Back, Driver!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _driverProfile!.isActive
                ? 'Your driver profile is active. Ready to start accepting deliveries?'
                : 'Your driver profile is currently inactive. Activate it to start receiving delivery requests.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildDriverInfoCard(),
        ],
      );
    } else {
      return const Column(
        children: [
          Text(
            'Become a Driver',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Join our delivery network and start earning money by delivering items in your area. '
            'Work on your own schedule and choose which deliveries to accept.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildDriverInfoCard() {
    if (_driverProfile == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Vehicle', _driverProfile!.vehicleTypeDisplayText),
          if (_driverProfile!.vehicleModel != null)
            _buildInfoRow('Model', _driverProfile!.vehicleModel!),
          if (_driverProfile!.licensePlate != null)
            _buildInfoRow('License Plate', _driverProfile!.licensePlate!),
          _buildInfoRow(
              'Total Deliveries', _driverProfile!.totalDeliveries.toString()),
          _buildInfoRow('Rating', _driverProfile!.formattedAverageRating),
          _buildInfoRow(
              'Total Earnings', _driverProfile!.formattedTotalEarnings),
          _buildInfoRow('Status', _driverProfile!.availabilityStatus),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFeatures() {
    if (_driverProfile != null) {
      return Column(
        children: [
          _buildBenefitItem(
            icon: Icons.dashboard,
            title: 'Enhanced Dashboard',
            description:
                'Access your full driver dashboard with job management',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.location_on,
            title: 'Job Tracking',
            description: 'Track active deliveries and view job history',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.analytics,
            title: 'Performance Analytics',
            description: 'View your earnings, ratings, and delivery stats',
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildBenefitItem(
            icon: Icons.schedule,
            title: 'Flexible Schedule',
            description: 'Work when you want, how you want',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.monetization_on,
            title: 'Earn Money',
            description: 'Get paid for every delivery you complete',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.location_on,
            title: 'Local Deliveries',
            description: 'Deliver items in your neighborhood',
          ),
        ],
      );
    }
  }

  Widget _buildDynamicActionButton() {
    if (_driverProfile != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to enhanced driver dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverDashboardView(
                  driverId: _currentUserId!,
                  routeData: widget.routeData,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _driverProfile!.isActive ? Colors.green : Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Go to Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleBecomeDriver,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Get Started as Driver',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: ColorConstants.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
