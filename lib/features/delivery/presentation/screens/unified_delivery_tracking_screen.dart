import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/screens/enhanced_return_request_screen.dart';

import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'dart:async';

class UnifiedDeliveryTrackingScreen extends StatefulWidget {
  const UnifiedDeliveryTrackingScreen({super.key});

  @override
  State<UnifiedDeliveryTrackingScreen> createState() =>
      _UnifiedDeliveryTrackingScreenState();
}

class _UnifiedDeliveryTrackingScreenState
    extends State<UnifiedDeliveryTrackingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressAnimationController;
  String? _currentUserId;
  List<DeliveryJobModel> _allDeliveries = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _initializeUser();
    _setupAutoRefresh();
  }

  void _setupControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimationController.forward();
  }

  void _initializeUser() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _refreshData();
    }
  }

  void _setupAutoRefresh() {
    // Auto-refresh every 30 seconds for active deliveries
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _currentUserId != null) {
        final hasActiveDeliveries =
            _allDeliveries.any((delivery) => delivery.isActive);
        if (hasActiveDeliveries) {
          _refreshData();
        }
      }
    });
  }

  void _refreshData() {
    if (_currentUserId != null) {
      context.read<DeliveryBloc>().add(LoadUserDeliveries(_currentUserId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Track Deliveries',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationsModal(),
            tooltip: 'Notifications',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: ColorConstants.primaryColor,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.hourglass_empty, size: 20),
              text: 'Pending',
            ),
            Tab(
              icon: Icon(Icons.local_shipping, size: 20),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.check_circle, size: 20),
              text: 'Delivered',
            ),
            Tab(
              icon: Icon(Icons.history, size: 20),
              text: 'All',
            ),
          ],
        ),
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySuccess) {
            _showSuccessMessage(state.message);
            _refreshData();
          } else if (state is DeliveryError) {
            _showErrorMessage(state.message);
          } else if (state is DeliveryJobUpdated) {
            // Handle individual job updates
            _showSuccessMessage(state.message);
            _refreshData();
          } else if (state is UserDeliveriesLoaded) {
            // Update local state when deliveries are loaded
            if (mounted) {
              setState(() {
                _allDeliveries = state.deliveries;
              });
            }
          }
        },
        child: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            if (state is DeliveryLoading) {
              return const LoadingWidget();
            }

            if (state is UserDeliveriesLoaded) {
              _allDeliveries = state.deliveries;
              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDeliveryList(_getPendingDeliveries()),
                    _buildDeliveryList(_getActiveDeliveries()),
                    _buildDeliveryList(_getDeliveredDeliveries()),
                    _buildDeliveryList(_allDeliveries),
                  ],
                ),
              );
            }

            if (state is DeliveryError) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: _refreshData,
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/help'),
        backgroundColor: ColorConstants.primaryColor,
        icon: const Icon(Icons.help_outline, color: Colors.white),
        label: const Text(
          'Need Help?',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  List<DeliveryJobModel> _getPendingDeliveries() {
    return _allDeliveries
        .where((delivery) =>
            delivery.status == DeliveryStatus.pendingApproval ||
            delivery.status == DeliveryStatus.approved)
        .toList();
  }

  List<DeliveryJobModel> _getActiveDeliveries() {
    return _allDeliveries.where((delivery) => delivery.isActive).toList();
  }

  List<DeliveryJobModel> _getDeliveredDeliveries() {
    return _allDeliveries.where((delivery) => delivery.isCompleted).toList();
  }

  Widget _buildDeliveryList(List<DeliveryJobModel> deliveries) {
    if (deliveries.isEmpty) {
      return _buildEmptyTabState();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          return _buildDeliveryCard(deliveries[index]);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryJobModel delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showDeliveryDetails(delivery),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(delivery),
              const SizedBox(height: 12),
              _buildProgressIndicator(delivery),
              const SizedBox(height: 16),
              _buildAddressInfo(delivery),
              const SizedBox(height: 16),
              _buildCardActions(delivery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(DeliveryJobModel delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(delivery.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(delivery.status),
                color: _getStatusColor(delivery.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (delivery.isReturnDelivery)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal[100],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'RET',
                            style: TextStyle(
                              color: Colors.teal[700],
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          delivery.isReturnDelivery
                              ? 'Return: ${delivery.itemName}'
                              : delivery.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Order #${delivery.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(delivery.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleAwareStatusText(delivery),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(DeliveryJobModel delivery) {
    final progress = delivery.progressPercentage / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          delivery.statusDetailMessage,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _progressAnimationController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: progress * _progressAnimationController.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(delivery.status),
                    ),
                    minHeight: 6,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${delivery.progressPercentage}%',
              style: TextStyle(
                color: _getStatusColor(delivery.status),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressInfo(DeliveryJobModel delivery) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildAddressRow(
            icon: Icons.location_on,
            label: 'Pickup',
            address: delivery.pickupAddress,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildAddressRow(
            icon: Icons.location_off,
            label: 'Delivery',
            address: delivery.deliveryAddress,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(DeliveryJobModel delivery) {
    final hasApprovalButtons = delivery.needsApproval && delivery.userIsOwner;
    final hasActionButtons = delivery.status == DeliveryStatus.itemDelivered &&
        !delivery.isReturnDelivery &&
        delivery.userIsRenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row - cost and duration info
        Row(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.grey[600],
              size: 16,
            ),
            Text(
              '\$${delivery.fee.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.access_time,
              color: Colors.grey[600],
              size: 16,
            ),
            Text(
              '${delivery.estimatedDuration} min',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),

        // Second row - buttons (if any)
        if (hasApprovalButtons || hasActionButtons) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasApprovalButtons) ..._buildApprovalButtons(delivery),
              if (hasActionButtons) ..._buildActionButtons(delivery),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(DeliveryJobModel delivery) {
    final bool hasReturnButton =
        delivery.status == DeliveryStatus.itemDelivered &&
            !delivery.isReturnDelivery &&
            delivery.userIsRenter;

    if (hasReturnButton) {
      // When both buttons are present, use more compact design
      return [
        // Track button
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(right: 2),
            child: ElevatedButton(
              onPressed: () => _showDeliveryDetails(delivery),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, size: 12, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Track',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Return button
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(left: 2),
            child: OutlinedButton(
              onPressed: () => _requestReturn(delivery),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                side: BorderSide(
                  color: ColorConstants.primaryColor.withValues(alpha: 0.4),
                  width: 1,
                ),
                backgroundColor:
                    ColorConstants.primaryColor.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_return,
                    size: 12,
                    color: ColorConstants.primaryColor,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Return',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    } else {
      // When only track button is present, use full width
      return [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => _showDeliveryDetails(delivery),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Track',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
  }

  Widget _buildEmptyTabState() {
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
            'No deliveries found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your deliveries will appear here when you make bookings',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
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
            'Track Your Deliveries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your delivery updates will appear here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
      case DeliveryStatus.approved:
        return Colors.blue;
      case DeliveryStatus.driverAssigned:
      case DeliveryStatus.driverHeadingToPickup:
        return Colors.orange;
      case DeliveryStatus.itemCollected:
        return Colors.purple;
      case DeliveryStatus.driverHeadingToDelivery:
        return Colors.indigo;
      case DeliveryStatus.itemDelivered:
        return Colors.green;
      case DeliveryStatus.returnRequested:
        return Colors.amber;
      case DeliveryStatus.returnScheduled:
        return Colors.indigo;
      case DeliveryStatus.returnCollected:
        return Colors.teal;
      case DeliveryStatus.returnDelivered:
        return Colors.green;
      case DeliveryStatus.completed:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
      case DeliveryStatus.approved:
        return Icons.schedule;
      case DeliveryStatus.driverAssigned:
        return Icons.check_circle;
      case DeliveryStatus.driverHeadingToPickup:
        return Icons.directions_car;
      case DeliveryStatus.itemCollected:
        return Icons.inventory;
      case DeliveryStatus.driverHeadingToDelivery:
        return Icons.local_shipping;
      case DeliveryStatus.itemDelivered:
        return Icons.done_all;
      case DeliveryStatus.returnRequested:
        return Icons.keyboard_return;
      case DeliveryStatus.returnScheduled:
        return Icons.schedule;
      case DeliveryStatus.returnCollected:
        return Icons.local_shipping;
      case DeliveryStatus.returnDelivered:
        return Icons.done_all;
      case DeliveryStatus.completed:
        return Icons.check_circle;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showDeliveryDetails(DeliveryJobModel delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDeliveryDetailsModal(delivery),
    );
  }

  Widget _buildDeliveryDetailsModal(DeliveryJobModel delivery) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader(delivery),
                      const SizedBox(height: 20),
                      _buildDetailedProgress(delivery),
                      const SizedBox(height: 20),
                      _buildDeliveryTimeline(delivery),
                      const SizedBox(height: 20),
                      if (delivery.driverId != null) _buildDriverInfo(delivery),
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

  Widget _buildModalHeader(DeliveryJobModel delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (delivery.isReturnDelivery)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_return,
                      color: Colors.teal[700],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'RETURN',
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.isReturnDelivery
                        ? 'Return: ${delivery.itemName}'
                        : delivery.itemName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Order #${delivery.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(delivery.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                delivery.statusDisplayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedProgress(DeliveryJobModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            delivery.statusDetailMessage,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: delivery.progressPercentage / 100.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStatusColor(delivery.status),
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${delivery.progressPercentage}% Complete',
            style: TextStyle(
              color: _getStatusColor(delivery.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline(DeliveryJobModel delivery) {
    final timelineSteps = _getTimelineSteps(delivery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...timelineSteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == timelineSteps.length - 1;

          return _buildTimelineStep(step, isLast);
        }).toList(),
      ],
    );
  }

  Widget _buildTimelineStep(TimelineStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? (step.isActive
                        ? ColorConstants.primaryColor
                        : Colors.green)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.isCompleted ? Icons.check : step.icon,
                color: Colors.white,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: step.isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: step.isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (step.timestamp != null)
                  Text(
                    _formatTimestamp(step.timestamp!),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TimelineStep> _getTimelineSteps(DeliveryJobModel delivery) {
    // Create role-aware timeline steps
    return [
      TimelineStep(
        title: 'Order Placed',
        subtitle: delivery.userIsOwner
            ? 'Delivery request received'
            : 'Delivery request created',
        icon: Icons.shopping_cart,
        isCompleted: true,
        isActive: false,
        timestamp: delivery.createdAt,
      ),
      TimelineStep(
        title: delivery.userIsOwner ? 'Review Request' : 'Awaiting Approval',
        subtitle: delivery.userIsOwner
            ? (delivery.lenderApprovalRequired
                ? 'Pending your approval'
                : 'Request processed')
            : 'Owner reviewing delivery request',
        icon: Icons.pending,
        isCompleted: delivery.status.index >= DeliveryStatus.approved.index,
        isActive: delivery.status == DeliveryStatus.pendingApproval,
        timestamp: delivery.lenderApprovedAt,
      ),
      TimelineStep(
        title: 'Driver Assigned',
        subtitle: delivery.userIsOwner
            ? 'Driver found and assigned'
            : 'Driver found and assigned to your delivery',
        icon: Icons.person,
        isCompleted:
            delivery.status.index >= DeliveryStatus.driverAssigned.index,
        isActive: delivery.status == DeliveryStatus.driverAssigned,
        timestamp: delivery.status.index >= DeliveryStatus.driverAssigned.index
            ? (delivery.updatedAt
                    .isAfter(delivery.createdAt.add(const Duration(minutes: 1)))
                ? delivery.updatedAt
                : null)
            : null,
      ),
      TimelineStep(
        title: 'Driver En Route to Pickup',
        subtitle: delivery.userIsOwner
            ? 'Driver heading to collect your item'
            : 'Driver on the way to collect item',
        icon: Icons.directions_car,
        isCompleted:
            delivery.status.index >= DeliveryStatus.driverHeadingToPickup.index,
        isActive: delivery.status == DeliveryStatus.driverHeadingToPickup,
        timestamp: delivery.status.index >=
                DeliveryStatus.driverHeadingToPickup.index
            ? (delivery.updatedAt
                    .isAfter(delivery.createdAt.add(const Duration(minutes: 5)))
                ? delivery.updatedAt
                : null)
            : null,
      ),
      TimelineStep(
        title: 'Item Picked Up',
        subtitle: delivery.userIsOwner
            ? 'Your item collected successfully'
            : 'Driver collected item and heading to you',
        icon: Icons.check_circle,
        isCompleted:
            delivery.status.index >= DeliveryStatus.itemCollected.index,
        isActive: delivery.status == DeliveryStatus.itemCollected,
        timestamp: delivery.pickupTime,
      ),
      TimelineStep(
        title: 'Out for Delivery',
        subtitle: delivery.userIsOwner
            ? 'Item being delivered to renter'
            : 'Item is on the way to your address',
        icon: Icons.local_shipping,
        isCompleted: delivery.status.index >=
            DeliveryStatus.driverHeadingToDelivery.index,
        isActive: delivery.status == DeliveryStatus.driverHeadingToDelivery,
        timestamp: delivery.status.index >=
                DeliveryStatus.driverHeadingToDelivery.index
            ? delivery.pickupTime?.add(const Duration(minutes: 5))
            : null,
      ),
      TimelineStep(
        title: 'Delivered',
        subtitle: delivery.userIsOwner
            ? 'Item delivered to renter successfully'
            : 'Item delivered to you successfully',
        icon: Icons.done_all,
        isCompleted:
            delivery.status.index >= DeliveryStatus.itemDelivered.index,
        isActive: delivery.status == DeliveryStatus.itemDelivered,
        timestamp: delivery.dropoffTime,
      ),
    ];
  }

  Widget _buildDriverInfo(DeliveryJobModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Driver',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: ColorConstants.primaryColor,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver ${delivery.driverId?.substring(0, 8) ?? 'Unknown'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Professional delivery partner',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () => _contactDriver(delivery),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Delivery Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _approveDelivery(String deliveryId) {
    context.read<DeliveryBloc>().add(ApproveDeliveryRequest(deliveryId));
  }

  List<Widget> _buildApprovalButtons(DeliveryJobModel delivery) {
    return [
      // Approve button
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          height: 32,
          child: ElevatedButton(
            onPressed: () => _approveDelivery(delivery.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    delivery.isReturnDelivery ? 'Approve' : 'Approve',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Decline button
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          height: 32,
          child: OutlinedButton(
            onPressed: () => _declineDelivery(delivery.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!, width: 1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    delivery.isReturnDelivery ? 'Decline' : 'Decline',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  void _declineDelivery(String deliveryId) {
    context.read<DeliveryBloc>().add(DeclineDeliveryRequest(deliveryId));
  }

  void _contactDriver(DeliveryJobModel delivery) {
    // TODO: Implement driver contact functionality
    _showSuccessMessage('Driver contact feature coming soon!');
  }

  void _requestReturn(DeliveryJobModel delivery) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EnhancedReturnRequestScreen(originalDelivery: delivery),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final DateTime? timestamp;

  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
    this.timestamp,
  });
}

String _getRoleAwareStatusText(DeliveryJobModel delivery) {
  // Return owner/lender-specific status text when user is the owner
  if (delivery.userIsOwner) {
    switch (delivery.status) {
      case DeliveryStatus.pendingApproval:
        return delivery.lenderApprovalRequired
            ? 'Awaiting your approval'
            : 'Processing request';
      case DeliveryStatus.approved:
        return 'Looking for a driver';
      case DeliveryStatus.driverAssigned:
        return 'Driver assigned';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Driver heading to collect item';
      case DeliveryStatus.itemCollected:
        return 'Item collected - heading to renter';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Out for delivery to renter';
      case DeliveryStatus.itemDelivered:
        return 'Item delivered to renter';
      case DeliveryStatus.returnRequested:
        return 'Return requested by renter';
      case DeliveryStatus.returnScheduled:
        return 'Return pickup scheduled';
      case DeliveryStatus.returnCollected:
        return 'Item collected from renter';
      case DeliveryStatus.returnDelivered:
        return 'Item returned to you';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Use default renter-centric text for renters
  return delivery.statusDisplayText;
}
