import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/presentation/screens/driver_dashboard_view.dart';
import 'package:rent_ease/features/delivery/presentation/screens/delivery_tracking_screen.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

/// Smart Router for Delivery Section
/// Automatically routes users to appropriate interface:
/// - Drivers → Enhanced Driver Dashboard
/// - Users → User Delivery Tracking Interface
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;
  DriverProfileModel? _driverProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUser();
  }

  void _initializeUser() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _loadUserProfile();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadUserProfile() {
    if (_currentUserId != null) {
      // Check if user has driver profile
      context.read<DeliveryBloc>().add(LoadDriverProfile(_currentUserId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        }
      },
      builder: (context, state) {
        if (_isLoading) {
          return const Scaffold(
            body: LoadingWidget(),
          );
        }

        // Smart Routing Logic
        if (_driverProfile != null && _currentUserId != null) {
          // User has driver profile → Enhanced Driver Dashboard
          return DriverDashboardView(driverId: _currentUserId!);
        } else {
          // Regular user → User Delivery Tracking Interface
          return _buildUserDeliveryInterface();
        }
      },
    );
  }

  /// User-focused delivery tracking interface
  Widget _buildUserDeliveryInterface() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Deliveries'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refreshUserData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'driver_profile',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined),
                    SizedBox(width: 8),
                    Text('Become a Driver'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: ColorConstants.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              text: 'Incoming',
              icon: Icon(Icons.inbox_outlined, size: 20),
            ),
            Tab(
              text: 'In Transit',
              icon: Icon(Icons.local_shipping_outlined, size: 20),
            ),
            Tab(
              text: 'Completed',
              icon: Icon(Icons.check_circle_outline, size: 20),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // User Status Card
          _buildUserStatusCard(),

          // Tab Content
          Expanded(
            child: BlocBuilder<DeliveryBloc, DeliveryState>(
              builder: (context, state) {
                if (state is DeliveryLoading) {
                  return const LoadingWidget();
                }

                if (state is DeliveryError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: _refreshUserData,
                  );
                }

                if (state is UserDeliveriesLoaded) {
                  return _buildDeliveriesTabView(state.deliveries);
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shadowColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primaryColor,
                ColorConstants.primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Deliveries',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monitor your item delivery status',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showCreateDriverProfileDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Become Driver',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveriesTabView(List<DeliveryJobModel> deliveries) {
    final incomingDeliveries = deliveries
        .where((d) => [
              DeliveryStatus.pendingApproval,
              DeliveryStatus.approved,
              DeliveryStatus.driverAssigned
            ].contains(d.status))
        .toList();

    final inTransitDeliveries = deliveries
        .where((d) => [
              DeliveryStatus.driverHeadingToPickup,
              DeliveryStatus.itemCollected,
              DeliveryStatus.driverHeadingToDelivery
            ].contains(d.status))
        .toList();

    final completedDeliveries = deliveries
        .where((d) => [
              DeliveryStatus.itemDelivered,
              DeliveryStatus.returnDelivered
            ].contains(d.status))
        .toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDeliveryList(incomingDeliveries, 'No Incoming Deliveries',
            'Your upcoming deliveries will appear here.'),
        _buildDeliveryList(inTransitDeliveries, 'No Deliveries in Transit',
            'Active deliveries will appear here.'),
        _buildDeliveryList(completedDeliveries, 'No Completed Deliveries',
            'Your delivery history will appear here.'),
      ],
    );
  }

  Widget _buildDeliveryList(List<DeliveryJobModel> deliveries,
      String emptyTitle, String emptyMessage) {
    if (deliveries.isEmpty) {
      return _buildEmptyStateWithMessage(emptyTitle, emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshUserData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildDeliveryCard(delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryJobModel delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    Icons.local_shipping_outlined,
                    color: ColorConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (delivery.customerName != null)
                        Text(
                          'Driver: ${delivery.customerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeliveryRoute(delivery),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                    Icons.attach_money, '\$${delivery.fee.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                _buildInfoChip(
                    Icons.access_time, '${delivery.estimatedDuration}min'),
                const Spacer(),
                if (delivery.isActive)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _showDeliveryTracking(delivery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.navigation,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Track',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryRoute(DeliveryJobModel job) {
    return Column(
      children: [
        _buildAddressRow(
          Icons.location_on_outlined,
          'Pickup',
          job.pickupAddress,
          Colors.orange,
        ),
        Container(
          margin: const EdgeInsets.only(left: 12),
          height: 20,
          width: 2,
          color: Colors.grey[300],
        ),
        _buildAddressRow(
          Icons.flag_outlined,
          'Delivery',
          job.deliveryAddress,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAddressRow(
      IconData icon, String label, String address, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your deliveries or become a driver',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshUserData,
            icon: const Icon(Icons.refresh),
            label: const Text('Load Deliveries'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithMessage(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return Colors.amber;
      case DeliveryStatus.approved:
        return Colors.blue;
      case DeliveryStatus.driverAssigned:
      case DeliveryStatus.driverHeadingToPickup:
      case DeliveryStatus.driverHeadingToDelivery:
        return Colors.orange;
      case DeliveryStatus.itemCollected:
        return Colors.purple;
      case DeliveryStatus.itemDelivered:
      case DeliveryStatus.returnDelivered:
        return Colors.green;
      case DeliveryStatus.returnRequested:
      case DeliveryStatus.returnScheduled:
      case DeliveryStatus.returnCollected:
        return Colors.indigo;
      case DeliveryStatus.completed:
        return Colors.teal;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  // Event handlers
  void _refreshUserData() {
    if (_currentUserId != null) {
      context.read<DeliveryBloc>().add(LoadUserDeliveries(_currentUserId!));
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'driver_profile':
        _showCreateDriverProfileDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showCreateDriverProfileDialog() {
    context.pushNamed('driver-profile');
  }

  void _showDeliveryTracking(DeliveryJobModel delivery) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryTrackingScreen(
          deliveryId: delivery.id,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Help'),
        content: const Text(
          '• Track your deliveries in real-time\n'
          '• Get notifications for status updates\n'
          '• Contact your driver if needed\n'
          '• Rate your delivery experience\n'
          '• Become a driver to earn extra income',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
