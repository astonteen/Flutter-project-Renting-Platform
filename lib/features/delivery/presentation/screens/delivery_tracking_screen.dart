import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final String? rentalId;

  const DeliveryTrackingScreen({
    super.key,
    required this.deliveryId,
    this.rentalId,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  late DeliveryBloc _deliveryBloc;

  @override
  void initState() {
    super.initState();
    _deliveryBloc = context.read<DeliveryBloc>();
    _loadDeliveryDetails();
  }

  void _loadDeliveryDetails() {
    // Load the specific delivery job details
    // For now, we'll load user deliveries and filter
    const userId = 'current_user_id'; // Would come from auth service
    _deliveryBloc.add(const LoadUserDeliveries(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.go('/track-orders'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Track Orders',
        ),
        actions: [
          IconButton(
            onPressed: _loadDeliveryDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserDeliveriesLoaded) {
            final delivery = state.deliveries
                .where((d) => d.id == widget.deliveryId)
                .firstOrNull;

            if (delivery == null) {
              return _buildDeliveryNotFound();
            }

            return _buildTrackingContent(delivery);
          }

          if (state is DeliveryError) {
            return _buildErrorState(state.message);
          }

          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildTrackingContent(DeliveryJobModel delivery) {
    return RefreshIndicator(
      onRefresh: () async => _loadDeliveryDetails(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryHeader(delivery),
            const SizedBox(height: 24),
            _buildTrackingProgress(delivery),
            const SizedBox(height: 24),
            _buildDeliveryDetails(delivery),
            const SizedBox(height: 24),
            _buildDriverInfo(delivery),
            const SizedBox(height: 24),
            _buildEstimatedTimes(delivery),
            if (delivery.isCompleted) ...[
              const SizedBox(height: 24),
              _buildCompletionInfo(delivery),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryHeader(DeliveryJobModel delivery) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(delivery.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(delivery.status),
                    size: 32,
                    color: _getStatusColor(delivery.status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery #${delivery.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    delivery.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTrackingProgress(DeliveryJobModel delivery) {
    final steps = [
      _ProgressStep(
        title: 'Order Placed',
        subtitle: 'Delivery request created',
        isCompleted: true,
        isActive: false,
        icon: Icons.shopping_cart,
      ),
      _ProgressStep(
        title: 'Driver Assigned',
        subtitle: 'Driver is heading to pickup',
        isCompleted:
            delivery.status.index >= DeliveryStatus.driverAssigned.index,
        isActive: delivery.status == DeliveryStatus.driverAssigned,
        icon: Icons.person,
      ),
      _ProgressStep(
        title: 'Heading to Pickup',
        subtitle: 'Driver is on the way to collect item',
        isCompleted:
            delivery.status.index >= DeliveryStatus.driverHeadingToPickup.index,
        isActive: delivery.status == DeliveryStatus.driverHeadingToPickup,
        icon: Icons.directions_car,
      ),
      _ProgressStep(
        title: 'Item Picked Up',
        subtitle: 'Item has been collected',
        isCompleted:
            delivery.status.index >= DeliveryStatus.itemCollected.index,
        isActive: delivery.status == DeliveryStatus.itemCollected,
        icon: Icons.check_circle,
      ),
      _ProgressStep(
        title: 'Out for Delivery',
        subtitle: 'Item is on the way to you',
        isCompleted: delivery.status.index >=
            DeliveryStatus.driverHeadingToDelivery.index,
        isActive: delivery.status == DeliveryStatus.driverHeadingToDelivery,
        icon: Icons.local_shipping,
      ),
      _ProgressStep(
        title: 'Delivered',
        subtitle: 'Item has been delivered',
        isCompleted: delivery.status == DeliveryStatus.itemDelivered,
        isActive: delivery.status == DeliveryStatus.itemDelivered,
        icon: Icons.done_all,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return _buildProgressStep(step, isLast);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(_ProgressStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? Colors.green
                    : step.isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                color: step.isCompleted || step.isActive
                    ? Colors.white
                    : Colors.grey,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: step.isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: step.isCompleted || step.isActive
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetails(DeliveryJobModel delivery) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAddressInfo(
              'Pickup Location',
              delivery.pickupAddress,
              Icons.location_on_outlined,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildAddressInfo(
              'Delivery Location',
              delivery.deliveryAddress,
              Icons.flag_outlined,
              Colors.green,
            ),
            if (delivery.specialInstructions?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                'Special Instructions',
                delivery.specialInstructions!,
                Icons.info_outline,
                Colors.blue,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.attach_money,
                    '\$${delivery.fee.toStringAsFixed(2)}',
                    'Delivery Fee',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    Icons.route,
                    '${delivery.distanceKm.toStringAsFixed(1)} km',
                    'Distance',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo(DeliveryJobModel delivery) {
    if (delivery.driverId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Finding Driver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'re finding the best driver for your delivery',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.customerName ?? 'Driver assigned',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Professional delivery driver',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (delivery.customerPhone != null)
                  IconButton(
                    onPressed: () => _callDriver(delivery.customerPhone!),
                    icon: const Icon(Icons.phone),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedTimes(DeliveryJobModel delivery) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (delivery.estimatedPickupTime != null)
              _buildTimeInfo(
                'Estimated Pickup',
                delivery.estimatedPickupTime!,
                Icons.access_time,
                Colors.orange,
              ),
            if (delivery.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 12),
              _buildTimeInfo(
                'Estimated Delivery',
                delivery.estimatedDeliveryTime!,
                Icons.schedule,
                Colors.green,
              ),
            ],
            if (delivery.actualPickupTime != null) ...[
              const SizedBox(height: 12),
              _buildTimeInfo(
                'Actual Pickup',
                delivery.actualPickupTime!,
                Icons.check_circle,
                Colors.blue,
              ),
            ],
            if (delivery.actualDeliveryTime != null) ...[
              const SizedBox(height: 12),
              _buildTimeInfo(
                'Delivered At',
                delivery.actualDeliveryTime!,
                Icons.done_all,
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionInfo(DeliveryJobModel delivery) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery Completed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your item has been successfully delivered.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (delivery.deliveryProofImage != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _viewProofImage(delivery.deliveryProofImage!),
                icon: const Icon(Icons.image),
                label: const Text('View Delivery Proof'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo(
      String title, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(
      String title, DateTime time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Delivery Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find a delivery with ID: ${widget.deliveryId}',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Delivery',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDeliveryDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading delivery details...'),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Today at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _callDriver(String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber...')),
    );
  }

  void _viewProofImage(String imageUrl) {
    // TODO: Implement image viewer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening proof image...')),
    );
  }
}

class _ProgressStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  _ProgressStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
  });
}
