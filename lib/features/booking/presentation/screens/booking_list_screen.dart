import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/core/widgets/lender_state_widgets.dart';
import 'package:rent_ease/core/router/app_routes.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

enum BookingFilter { all, upcoming, active, completed, cancelled }

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  BookingFilter _selectedFilter = BookingFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<LenderBloc>().add(const LoadAllBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRoutes.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocBuilder<LenderBloc, LenderState>(
              builder: (context, state) {
                if (state is LenderLoading) {
                  return const LoadingWidget();
                } else if (state is LenderError) {
                  return LenderErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<LenderBloc>().add(const LoadAllBookings()),
                  );
                } else if (state is AllBookingsLoaded) {
                  final filteredBookings = _getFilteredBookings(state.bookings);
                  return _buildBookingsList(filteredBookings);
                } else {
                  return const LenderEmptyState(
                    title: 'No bookings yet',
                    subtitle:
                        'Your bookings will appear here once customers start renting your items.',
                    icon: Icons.event_note,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: BookingFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                selectedColor:
                    ColorConstants.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: ColorConstants.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ColorConstants.primaryColor
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return LenderEmptyState(
        title: 'No ${_getFilterLabel(_selectedFilter).toLowerCase()} bookings',
        subtitle: 'Try selecting a different filter or check back later.',
        icon: Icons.event_available,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LenderBloc>().add(const LoadAllBookings());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => AppRoutes.goToBookingDetails(context, booking.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.listingName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rented by ${booking.renterName}',
                          style: TextStyle(
                            fontSize: 14,
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
                      color: _getBookingStatusColor(booking.status)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.displayName,
                      style: TextStyle(
                        color: _getBookingStatusColor(booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM d').format(booking.startDate)} - ${DateFormat('MMM d').format(booking.endDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${booking.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              if (booking.isDeliveryRequired) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case BookingFilter.all:
        return bookings;
      case BookingFilter.upcoming:
        return bookings.where((b) => b.startDate.isAfter(now)).toList();
      case BookingFilter.active:
        return bookings
            .where((b) =>
                b.startDate.isBefore(now) &&
                b.endDate.isAfter(now) &&
                b.status == BookingStatus.inProgress)
            .toList();
      case BookingFilter.completed:
        return bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      case BookingFilter.cancelled:
        return bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .toList();
    }
  }

  String _getFilterLabel(BookingFilter filter) {
    switch (filter) {
      case BookingFilter.all:
        return 'All';
      case BookingFilter.upcoming:
        return 'Upcoming';
      case BookingFilter.active:
        return 'Active';
      case BookingFilter.completed:
        return 'Completed';
      case BookingFilter.cancelled:
        return 'Cancelled';
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BookingFilter.values.map((filter) {
            return RadioListTile<BookingFilter>(
              title: Text(_getFilterLabel(filter)),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
