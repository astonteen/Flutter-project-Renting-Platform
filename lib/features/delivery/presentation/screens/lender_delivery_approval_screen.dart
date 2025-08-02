import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/core/widgets/detail_row_widget.dart';
import 'package:rent_ease/core/widgets/status_card_widget.dart';
import 'package:rent_ease/core/router/app_routes.dart';

class LenderDeliveryApprovalScreen extends StatefulWidget {
  final String deliveryId;

  const LenderDeliveryApprovalScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<LenderDeliveryApprovalScreen> createState() =>
      _LenderDeliveryApprovalScreenState();
}

class _LenderDeliveryApprovalScreenState
    extends State<LenderDeliveryApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DeliveryJobModel? _delivery;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDeliveryDetails();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _loadDeliveryDetails() {
    // Load the specific delivery directly instead of all jobs
    final deliveryBloc = context.read<DeliveryBloc>();
    deliveryBloc.add(LoadDeliveryById(widget.deliveryId));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Delivery Approval',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRoutes.pop(context),
        ),
        actions: [
          if (_delivery != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDeliveryDetails,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySuccess) {
            _showSuccessMessage(state.message);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) AppRoutes.pop(context);
            });
          } else if (state is DeliveryError) {
            _showErrorMessage(state.message);
            setState(() => _isProcessing = false);
          } else if (state is DeliveryJobUpdated) {
            // Handle direct delivery loading
            setState(() {
              _delivery = state.job;
            });
          }
        },
        child: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            if (state is DeliveryLoading) {
              return const LoadingWidget();
            }

            if (_delivery == null) {
              return _buildDeliveryNotFound();
            }

            return _buildApprovalContent();
          },
        ),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Delivery Request Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This delivery request may have been approved or cancelled.',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => AppRoutes.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildDeliveryDetails(),
              const SizedBox(height: 20),
              _buildCustomerInfo(),
              const SizedBox(height: 20),
              _buildTimeoutWarning(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return DeliveryStatusCard(
      itemName: _delivery!.itemName,
    );
  }

  Widget _buildDeliveryDetails() {
    return DetailCard(
      title: 'Delivery Details',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ColorConstants.warningColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.warningColor.withAlpha(75)),
        ),
        child: const Text(
          'Needs Approval',
          style: TextStyle(
            color: ColorConstants.warningColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      children: [
        DetailRow(
          icon: Icons.inventory_2_outlined,
          title: 'Item',
          value: _delivery!.itemName,
        ),
        DetailRow(
          icon: Icons.person_outline,
          title: 'Customer',
          value: _delivery!.customerName ?? 'Unknown Customer',
        ),
        DetailRow(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: _delivery!.customerPhone ?? 'Not provided',
        ),
        const Divider(height: 24),
        DetailRow(
          icon: Icons.location_on_outlined,
          title: 'Pickup From',
          value: _delivery!.pickupAddress,
        ),
        DetailRow(
          icon: Icons.location_off_outlined,
          title: 'Deliver To',
          value: _delivery!.deliveryAddress,
        ),
        DetailRow(
          icon: Icons.route_outlined,
          title: 'Distance',
          value: '${_delivery!.distanceKm.toStringAsFixed(1)} km',
        ),
        const Divider(height: 24),
        DetailRow(
          icon: Icons.attach_money,
          title: 'Delivery Fee',
          value: '\$${_delivery!.fee.toStringAsFixed(2)}',
        ),
        DetailRow(
          icon: Icons.access_time,
          title: 'Est. Duration',
          value: '${_delivery!.estimatedDuration} minutes',
        ),
        if (_delivery!.specialInstructions?.isNotEmpty == true) ...[
          const Divider(height: 24),
          DetailRow(
            icon: Icons.note_outlined,
            title: 'Special Instructions',
            value: _delivery!.specialInstructions!,
            isMultiline: true,
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      ColorConstants.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _delivery!.customerName ?? 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _delivery!.customerPhone ?? 'Phone not available',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutWarning() {
    if (_delivery!.lenderApprovalTimeout == null) {
      return const SizedBox.shrink();
    }

    final timeLeft =
        _delivery!.lenderApprovalTimeout!.difference(DateTime.now());
    if (timeLeft.isNegative) return const SizedBox.shrink();

    final hoursLeft = timeLeft.inHours;
    final minutesLeft = timeLeft.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-approval in ${hoursLeft}h ${minutesLeft}m',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  'If not approved, this request will be automatically approved.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _approveDelivery(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Approve Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => _approveDelivery(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 24),
                SizedBox(width: 8),
                Text(
                  'Decline Delivery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _approveDelivery(bool approve) {
    setState(() => _isProcessing = true);

    if (approve) {
      // Approve the delivery
      context.read<DeliveryBloc>().add(
            ApproveDeliveryRequest(widget.deliveryId),
          );
    } else {
      // Decline the delivery
      context.read<DeliveryBloc>().add(
            DeclineDeliveryRequest(widget.deliveryId),
          );
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Extension to add firstOrNull to Iterable
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
