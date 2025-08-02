import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/core/widgets/detail_row_widget.dart';
import 'package:rent_ease/core/widgets/status_card_widget.dart';
import 'package:rent_ease/core/router/app_routes.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingModel? _booking;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    context.read<LenderBloc>().add(LoadBookingDetails(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRoutes.pop(context),
        ),
        actions: [
          if (_booking != null)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'contact',
                  child: Row(
                    children: [
                      Icon(Icons.message),
                      SizedBox(width: 8),
                      Text('Contact Renter'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Booking'),
                    ],
                  ),
                ),
                if (_booking!.status == BookingStatus.pending)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: SpacingConstants.sm),
                        Text('Cancel Booking',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: BlocListener<LenderBloc, LenderState>(
        listener: (context, state) {
          if (state is BookingDetailsLoaded) {
            setState(() {
              _booking = state.booking;
            });
          } else if (state is LenderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
        },
        child: BlocBuilder<LenderBloc, LenderState>(
          builder: (context, state) {
            if (state is LenderLoading) {
              return const LoadingWidget();
            }

            if (_booking == null) {
              return const Center(
                child: Text('Booking not found'),
              );
            }

            return _buildBookingContent();
          },
        ),
      ),
    );
  }

  Widget _buildBookingContent() {
    return SingleChildScrollView(
      padding: SpacingConstants.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: SpacingConstants.lg),
          _buildBookingDetails(),
          const SizedBox(height: 20),
          _buildRenterInfo(),
          const SizedBox(height: 20),
          _buildPaymentInfo(),
          if (_booking!.isDeliveryRequired) ...[
            const SizedBox(height: 20),
            _buildDeliveryInfo(),
          ],
          if (_booking!.specialRequests?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _buildSpecialRequests(),
          ],
          const SizedBox(height: SpacingConstants.xl),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return StatusCard(
      title: _booking!.status.displayName,
      subtitle: _getStatusDescription(),
      icon: _getStatusIcon(),
      primaryColor: _getBookingStatusColor(_booking!.status),
    );
  }

  Widget _buildBookingDetails() {
    return DetailCard(
      title: 'Booking Information',
      children: [
        DetailRow(
          icon: Icons.inventory_2_outlined,
          title: 'Item',
          value: _booking!.listingName,
        ),
        DetailRow(
          icon: Icons.calendar_today,
          title: 'Start Date',
          value: DateFormat('EEEE, MMMM d, yyyy').format(_booking!.startDate),
        ),
        DetailRow(
          icon: Icons.event,
          title: 'End Date',
          value: DateFormat('EEEE, MMMM d, yyyy').format(_booking!.endDate),
        ),
        DetailRow(
          icon: Icons.schedule,
          title: 'Duration',
          value: _booking!.durationDisplay,
        ),
        DetailRow(
          icon: Icons.confirmation_number,
          title: 'Booking ID',
          value: _booking!.id.substring(0, 8).toUpperCase(),
        ),
      ],
    );
  }

  Widget _buildRenterInfo() {
    return DetailCard(
      title: 'Renter Information',
      children: [
        DetailRow(
          icon: Icons.person,
          title: 'Name',
          value: _booking!.renterName,
        ),
        DetailRow(
          icon: Icons.email,
          title: 'Email',
          value: _booking!.renterEmail,
        ),
        if (_booking!.renterPhone != null)
          DetailRow(
            icon: Icons.phone,
            title: 'Phone',
            value: _booking!.renterPhone!,
          ),
        DetailRow(
          icon: Icons.star,
          title: 'Rating',
          value:
              '${_booking!.renterRating.toStringAsFixed(1)} (${_booking!.renterReviewCount} reviews)',
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return DetailCard(
      title: 'Payment Information',
      children: [
        DetailRow(
          icon: Icons.attach_money,
          title: 'Total Amount',
          value: '\$${_booking!.totalAmount.toStringAsFixed(2)}',
        ),
        DetailRow(
          icon: Icons.security,
          title: 'Security Deposit',
          value: '\$${_booking!.securityDeposit.toStringAsFixed(2)}',
        ),
        DetailRow(
          icon: Icons.payment,
          title: 'Deposit Status',
          value: _booking!.isDepositPaid ? 'Paid' : 'Pending',
          iconColor: _booking!.isDepositPaid ? Colors.green : Colors.orange,
        ),
        if (_booking!.isDeliveryRequired && _booking!.deliveryFee != null)
          DetailRow(
            icon: Icons.local_shipping,
            title: 'Delivery Fee',
            value: '\$${_booking!.deliveryFee!.toStringAsFixed(2)}',
          ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return DetailCard(
      title: 'Delivery Information',
      children: [
        const DetailRow(
          icon: Icons.local_shipping,
          title: 'Delivery Required',
          value: 'Yes',
          iconColor: ColorConstants.primaryColor,
        ),
        if (_booking!.deliveryAddress != null)
          DetailRow(
            icon: Icons.location_on,
            title: 'Delivery Address',
            value: _booking!.deliveryAddress!,
            isMultiline: true,
          ),
        if (_booking!.deliveryFee != null)
          DetailRow(
            icon: Icons.attach_money,
            title: 'Delivery Fee',
            value: '\$${_booking!.deliveryFee!.toStringAsFixed(2)}',
          ),
      ],
    );
  }

  Widget _buildSpecialRequests() {
    return DetailCard(
      title: 'Special Requests',
      children: [
        DetailRow(
          icon: Icons.note,
          title: 'Notes',
          value: _booking!.specialRequests!,
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_booking!.status == BookingStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmBooking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm Booking'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _cancelBooking(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.errorColor,
                side: const BorderSide(color: ColorConstants.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Decline Booking'),
            ),
          ),
        ],
        if (_booking!.status == BookingStatus.confirmed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _markItemReady(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mark Item Ready'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _contactRenter(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.primaryColor,
              side: const BorderSide(color: ColorConstants.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Contact Renter'),
          ),
        ),
      ],
    );
  }

  String _getStatusDescription() {
    switch (_booking!.status) {
      case BookingStatus.pending:
        return 'Waiting for your approval';
      case BookingStatus.confirmed:
        return 'Booking confirmed, prepare item for handoff';
      case BookingStatus.inProgress:
        return 'Item is currently rented out';
      case BookingStatus.completed:
        return 'Rental completed successfully';
      case BookingStatus.cancelled:
        return 'Booking was cancelled';
      case BookingStatus.overdue:
        return 'Item return is overdue';
    }
  }

  IconData _getStatusIcon() {
    switch (_booking!.status) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.overdue:
        return Icons.warning;
    }
  }

  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return ColorConstants.warningColor;
      case BookingStatus.confirmed:
        return ColorConstants.successColor;
      case BookingStatus.inProgress:
        return ColorConstants.infoColor;
      case BookingStatus.completed:
        return ColorConstants.successColor;
      case BookingStatus.cancelled:
        return ColorConstants.errorColor;
      case BookingStatus.overdue:
        return ColorConstants.errorColor;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'contact':
        _contactRenter();
        break;
      case 'edit':
        _editBooking();
        break;
      case 'cancel':
        _cancelBooking();
        break;
    }
  }

  void _confirmBooking() {
    context.read<LenderBloc>().add(UpdateBookingStatus(
          bookingId: _booking!.id,
          status: BookingStatus.confirmed,
        ));
  }

  void _cancelBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LenderBloc>().add(UpdateBookingStatus(
                    bookingId: _booking!.id,
                    status: BookingStatus.cancelled,
                  ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _markItemReady() {
    context.read<LenderBloc>().add(UpdateBookingStatus(
          bookingId: _booking!.id,
          status: BookingStatus.inProgress,
        ));
  }

  void _contactRenter() {
    // Navigate to messages or show contact options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact renter feature coming soon!'),
      ),
    );
  }

  void _editBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit booking feature coming soon!'),
      ),
    );
  }
}
