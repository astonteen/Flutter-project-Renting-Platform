import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'dart:math' as math;

class DriverJobsScreen extends StatefulWidget {
  const DriverJobsScreen({super.key});

  @override
  State<DriverJobsScreen> createState() => _DriverJobsScreenState();
}

class _DriverJobsScreenState extends State<DriverJobsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DeliveryBloc _deliveryBloc;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _deliveryBloc = context.read<DeliveryBloc>();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
      _loadJobData();
    }
  }

  void _loadJobData() {
    if (_currentUserId != null) {
      // Remove LoadAvailableJobs since LoadDriverJobs now loads both
      _deliveryBloc.add(LoadDriverJobs(_currentUserId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        // Auto-refresh job listings when status updates are successful
        if (state is DeliveryJobUpdated) {
          // Show success message for job updates
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: ColorConstants.successColor,
              duration: const Duration(seconds: 2),
            ),
          );

          // Auto-refresh with a small delay to ensure backend is updated
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadJobData();
            }
          });
        } else if (state is DeliverySuccess) {
          // Show success message for general success states
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: ColorConstants.successColor,
              duration: const Duration(seconds: 2),
            ),
          );

          // Auto-refresh with a small delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadJobData();
            }
          });
        } else if (state is DeliveryError && state.errorType == 'accept_job') {
          // Show error message for job acceptance failures
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: ColorConstants.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is DeliveryError &&
            state.errorType == 'update_status') {
          // Show error message for status update failures
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: ColorConstants.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Job Listings',
            style: TextStyle(
              color: ColorConstants.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: ColorConstants.primaryColor,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: ColorConstants.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: ColorConstants.white,
            indicatorWeight: 3,
            labelColor: ColorConstants.white,
            unselectedLabelColor: ColorConstants.white.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.work_outline),
                text: 'Available',
              ),
              Tab(
                icon: Icon(Icons.local_shipping),
                text: 'Active',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Completed',
              ),
            ],
          ),
        ),
        body: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            if (state is DeliveryLoading) {
              return const Center(child: LoadingWidget());
            }

            if (state is DeliveryError) {
              return Center(
                child: CustomErrorWidget(
                  message: state.message,
                  onRetry: _loadJobData,
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableJobsTab(state),
                _buildActiveJobsTab(state),
                _buildCompletedJobsTab(state),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadJobData,
          backgroundColor: ColorConstants.primaryColor,
          child: const Icon(
            Icons.refresh,
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableJobsTab(DeliveryState state) {
    List<DeliveryJobModel> availableJobs = [];

    if (state is DeliveryLoaded) {
      availableJobs = state.availableJobs;
    }

    if (availableJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline,
        title: 'No Available Jobs',
        subtitle: 'Check back later for new delivery opportunities',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadJobData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableJobs.length,
        itemBuilder: (context, index) {
          final job = availableJobs[index];
          return _buildJobCard(
            job: job,
            onTap: () => _showJobDetails(job),
            actionButton: _buildAcceptButton(job),
          );
        },
      ),
    );
  }

  Widget _buildActiveJobsTab(DeliveryState state) {
    List<DeliveryJobModel> activeJobs = [];

    if (state is DeliveryLoaded) {
      activeJobs = state.driverJobs
          .where((job) => [
                DeliveryStatus.driverAssigned,
                DeliveryStatus.driverHeadingToPickup,
                DeliveryStatus.itemCollected,
                DeliveryStatus.driverHeadingToDelivery,
              ].contains(job.status))
          .toList();
    }

    if (activeJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping,
        title: 'No Active Deliveries',
        subtitle: 'Accept available jobs to start earning',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadJobData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeJobs.length,
        itemBuilder: (context, index) {
          final job = activeJobs[index];
          return _buildJobCard(
            job: job,
            onTap: () => _showJobDetails(job),
            actionButton: _buildStatusButton(job),
          );
        },
      ),
    );
  }

  Widget _buildCompletedJobsTab(DeliveryState state) {
    List<DeliveryJobModel> completedJobs = [];

    if (state is DeliveryLoaded) {
      completedJobs = state.driverJobs
          .where((job) => [
                DeliveryStatus.itemDelivered,
                DeliveryStatus.returnDelivered,
              ].contains(job.status))
          .toList();
    }

    if (completedJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Completed Deliveries',
        subtitle: 'Your completed deliveries will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadJobData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedJobs.length,
        itemBuilder: (context, index) {
          final job = completedJobs[index];
          return _buildJobCard(
            job: job,
            onTap: () => _showJobDetails(job),
            actionButton: _buildCompletedBadge(job),
          );
        },
      ),
    );
  }

  Widget _buildJobCard({
    required DeliveryJobModel job,
    required VoidCallback onTap,
    required Widget actionButton,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildJobCardHeader(job, actionButton),
              const SizedBox(height: 16),
              _buildJobAddressInfo(job),
              const SizedBox(height: 16),
              _buildJobCardActions(job),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCardHeader(DeliveryJobModel job, Widget actionButton) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item info with icon and action button
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(job.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getJobIcon(job.deliveryType),
                color: _getStatusColor(job.status),
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
                      if (job.isReturnDelivery)
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
                          job.isReturnDelivery
                              ? 'Return: ${job.itemName}'
                              : job.itemName.isNotEmpty
                                  ? job.itemName
                                  : 'Unknown Item',
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
                  const SizedBox(height: 2),
                  Text(
                    'Job #${job.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Action button on the right
            actionButton,
          ],
        ),
        const SizedBox(height: 12),
        // Status badge below title and job code
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(job.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            job.statusDisplayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobAddressInfo(DeliveryJobModel job) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildJobAddressRow(
            icon: Icons.location_on,
            label: 'Pickup',
            address: job.pickupAddress,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildJobAddressRow(
            icon: Icons.location_off,
            label: 'Delivery',
            address: job.deliveryAddress,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildJobAddressRow({
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

  Widget _buildJobCardActions(DeliveryJobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cost and duration info row
        Row(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.grey[600],
              size: 16,
            ),
            Text(
              '\$${job.fee.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.straighten,
              color: Colors.grey[600],
              size: 16,
            ),
            Text(
              '${job.distanceKm.toStringAsFixed(1)} km',
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
              '${job.estimatedDuration} min',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openMapNavigation(job),
                icon: const Icon(Icons.map, size: 16),
                label: const Text(
                  'View Route',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.infoColor,
                  side: const BorderSide(color: ColorConstants.infoColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_canCalculateDistance(job))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me,
                      size: 14,
                      color: ColorConstants.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_calculateDistance(job).toStringAsFixed(1)} km total',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcceptButton(DeliveryJobModel job) {
    return ElevatedButton(
      onPressed: () => _acceptJob(job),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.successColor,
        foregroundColor: ColorConstants.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: ColorConstants.successColor.withValues(alpha: 0.3),
        minimumSize: Size(_getButtonWidth('Accept'), 36),
      ),
      child: const Text(
        'Accept',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusButton(DeliveryJobModel job) {
    final statusColor = _getStatusColor(job.status);
    final actionText = _getNextActionText(job.status);

    return ElevatedButton(
      onPressed: () => _updateJobStatus(job),
      style: ElevatedButton.styleFrom(
        backgroundColor: statusColor,
        foregroundColor: ColorConstants.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: statusColor.withValues(alpha: 0.3),
        minimumSize: Size(_getButtonWidth(actionText), 36),
      ),
      child: Text(
        actionText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  double _getButtonWidth(String text) {
    // Return consistent button widths based on text length
    switch (text) {
      case 'Accept':
        return 80;
      case 'Head to Pickup':
        return 120;
      case 'Mark Picked Up':
        return 120;
      case 'Head to Delivery':
        return 130;
      case 'Mark Delivered':
        return 120;
      default:
        return 100;
    }
  }

  Widget _buildCompletedBadge(DeliveryJobModel job) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstants.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: ColorConstants.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: ColorConstants.successColor,
          ),
          const SizedBox(width: 4),
          Text(
            job.status == DeliveryStatus.itemDelivered
                ? 'Delivered'
                : 'Returned',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorConstants.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: ColorConstants.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: ColorConstants.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColorConstants.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadJobData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: ColorConstants.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptJob(DeliveryJobModel job) {
    if (job.status == DeliveryStatus.approved && _currentUserId != null) {
      _deliveryBloc.add(AcceptDeliveryJob(job.id, _currentUserId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Accepting delivery #${job.id.substring(0, 8)}...'),
              ),
            ],
          ),
          backgroundColor: ColorConstants.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateJobStatus(DeliveryJobModel job) {
    DeliveryStatus nextStatus;
    String actionText;

    switch (job.status) {
      case DeliveryStatus.driverAssigned:
        nextStatus = DeliveryStatus.driverHeadingToPickup;
        actionText = 'Heading to pickup';
        break;
      case DeliveryStatus.driverHeadingToPickup:
        nextStatus = DeliveryStatus.itemCollected;
        actionText = 'Marking as picked up';
        break;
      case DeliveryStatus.itemCollected:
        nextStatus = DeliveryStatus.driverHeadingToDelivery;
        actionText = 'Heading to delivery';
        break;
      case DeliveryStatus.driverHeadingToDelivery:
        nextStatus = DeliveryStatus.itemDelivered;
        actionText = 'Marking as delivered';
        break;
      default:
        return; // No next status
    }

    _deliveryBloc.add(UpdateJobStatus(job.id, nextStatus));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  '$actionText for delivery #${job.id.substring(0, 8)}...'),
            ),
          ],
        ),
        backgroundColor: ColorConstants.infoColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showJobDetails(DeliveryJobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delivery #${job.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', job.statusDisplayText),
              _buildDetailRow(
                  'Type', job.deliveryType.toString().split('.').last),
              _buildDetailRow('Fee', '\$${job.fee.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Distance', '${job.distanceKm.toStringAsFixed(1)} km'),
              _buildDetailRow('Duration', '${job.estimatedDuration} minutes'),
              const SizedBox(height: 16),
              const Text(
                'Pickup Location:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(job.pickupAddress),
              const SizedBox(height: 12),
              const Text(
                'Delivery Location:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(job.deliveryAddress),
              if (job.specialInstructions?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text(
                  'Special Instructions:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(job.specialInstructions ?? ''),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (job.status == DeliveryStatus.approved && _currentUserId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptJob(job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.successColor,
                foregroundColor: ColorConstants.white,
              ),
              child: const Text('Accept Job'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return ColorConstants.warningColor;
      case DeliveryStatus.approved:
        return ColorConstants.infoColor;
      case DeliveryStatus.driverAssigned:
        return ColorConstants.primaryColor;
      case DeliveryStatus.driverHeadingToPickup:
        return ColorConstants.warningColor;
      case DeliveryStatus.itemCollected:
        return ColorConstants.infoColor;
      case DeliveryStatus.driverHeadingToDelivery:
        return ColorConstants.primaryColor;
      case DeliveryStatus.itemDelivered:
        return ColorConstants.successColor;
      case DeliveryStatus.returnRequested:
        return ColorConstants.warningColor;
      case DeliveryStatus.returnScheduled:
        return ColorConstants.infoColor;
      case DeliveryStatus.returnCollected:
        return ColorConstants.infoColor;
      case DeliveryStatus.returnDelivered:
        return ColorConstants.successColor;
      case DeliveryStatus.completed:
        return ColorConstants.successColor;
      case DeliveryStatus.cancelled:
        return ColorConstants.errorColor;
    }
  }

  IconData _getJobIcon(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickupDelivery:
        return Icons.local_shipping;
      case DeliveryType.returnPickup:
        return Icons.keyboard_return;
    }
  }

  String _getNextActionText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Awaiting Approval';
      case DeliveryStatus.approved:
        return 'Accept Job';
      case DeliveryStatus.driverAssigned:
        return 'Head to Pickup';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Mark Picked Up';
      case DeliveryStatus.itemCollected:
        return 'Head to Delivery';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Mark Delivered';
      case DeliveryStatus.itemDelivered:
        return 'Job Complete';
      case DeliveryStatus.returnRequested:
        return 'Return Requested';
      case DeliveryStatus.returnScheduled:
        return 'Return Scheduled';
      case DeliveryStatus.returnCollected:
        return 'Returning Item';
      case DeliveryStatus.returnDelivered:
        return 'Return Complete';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Map navigation functionality
  Future<void> _openMapNavigation(DeliveryJobModel job) async {
    if (!_canCalculateDistance(job)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available for this job'),
          backgroundColor: ColorConstants.warningColor,
        ),
      );
      return;
    }

    // Directly show route on dashboard
    _showRouteOnDashboard(job);
  }

  void _showRouteOnDashboard(DeliveryJobModel job) {
    // Navigate via GoRouter with query parameters
    context.go('/driver-dashboard?showRoute=true&jobId=${job.id}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing route for ${job.itemName} on dashboard'),
        backgroundColor: ColorConstants.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _canCalculateDistance(DeliveryJobModel job) {
    return job.pickupLatitude != null &&
        job.pickupLongitude != null &&
        job.deliveryLatitude != null &&
        job.deliveryLongitude != null;
  }

  double _calculateDistance(DeliveryJobModel job) {
    if (!_canCalculateDistance(job)) return 0.0;

    return _calculateDistanceBetweenPoints(
      job.pickupLatitude!,
      job.pickupLongitude!,
      job.deliveryLatitude!,
      job.deliveryLongitude!,
    );
  }

  double _calculateDistanceBetweenPoints(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
