import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/rental/data/models/rental_booking_model.dart';
import 'package:rent_ease/features/rental/presentation/bloc/booking_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:rent_ease/core/services/app_rating_service.dart';
import 'package:rent_ease/features/reviews/presentation/widgets/rate_rental_sheet.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load user bookings with actual user ID
    final userId = SupabaseService.currentUser?.id;
    if (userId != null) {
      context.read<BookingBloc>().add(LoadUserBookings(userId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Rentals'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: const SizedBox.shrink(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: ColorConstants.primaryColor,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const LoadingWidget();
          }

          if (state is BookingError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () {
                final userId = SupabaseService.currentUser?.id;
                if (userId != null) {
                  context.read<BookingBloc>().add(LoadUserBookings(userId));
                }
              },
            );
          }

          if (state is BookingsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(
                  _getActiveBookings(state.bookings),
                  'No active rentals',
                  'You don\'t have any active rentals at the moment.',
                ),
                _buildBookingsList(
                  _getPastBookings(state.bookings),
                  'No past rentals',
                  'Your rental history will appear here.',
                ),
                _buildBookingsList(
                  state.bookings,
                  'No rentals',
                  'You haven\'t made any rentals yet.',
                ),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  List<RentalBookingModel> _getActiveBookings(
      List<RentalBookingModel> bookings) {
    // Debug: Print all booking statuses
    debugPrint('🔍 Total bookings: ${bookings.length}');
    for (var booking in bookings) {
      debugPrint(
          '📋 Booking ${booking.id}: status="${booking.status}", item="${booking.displayItemName}"');
    }

    final activeBookings = bookings
        .where((booking) =>
            booking.status == 'confirmed' ||
            booking.status == 'in_progress' ||
            booking.status == 'active' ||
            booking.status == 'pending')
        .toList();

    debugPrint('✅ Active bookings found: ${activeBookings.length}');
    return activeBookings;
  }

  List<RentalBookingModel> _getPastBookings(List<RentalBookingModel> bookings) {
    return bookings
        .where((booking) =>
            booking.status == 'completed' || booking.status == 'cancelled')
        .toList();
  }

  Widget _buildBookingsList(
    List<RentalBookingModel> bookings,
    String emptyTitle,
    String emptyMessage,
  ) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          context.read<BookingBloc>().add(LoadUserBookings(userId));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BookingCard(booking: bookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    String title = 'No rentals yet',
    String message = 'Start exploring items to rent!',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to home tab - using proper navigation
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Browse Items'),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final RentalBookingModel booking;

  const BookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${_safeSubstring(booking.id, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),

            // Item info with actual data
            Row(
              children: [
                // Item image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: booking.bestImageUrl.isNotEmpty
                        ? Image.network(
                            booking.bestImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.displayItemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${booking.displayOwnerName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Tap to view item details
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    context.push('/item/${booking.itemId}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rental period
            _buildInfoRow(
              Icons.calendar_today,
              'Rental Period',
              booking.formattedDateRange,
            ),
            const SizedBox(height: 8),

            // Duration
            _buildInfoRow(
              Icons.schedule,
              'Duration',
              '${booking.rentalDays} day${booking.rentalDays > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 8),

            // Total amount
            _buildInfoRow(
              Icons.attach_money,
              'Total Amount',
              '\$${booking.totalAmount.toStringAsFixed(2)}',
            ),

            // Delivery info
            if (booking.needsDelivery) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.local_shipping,
                'Delivery',
                'Delivery required',
              ),
            ],

            // Ready status for confirmed bookings
            if (booking.status == 'confirmed') ...[
              const SizedBox(height: 8),
              _buildPickupAvailabilityRow(booking),
            ],

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context, booking),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'confirmed':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'in_progress':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'completed':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        booking.statusDisplayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupAvailabilityRow(RentalBookingModel booking) {
    final now = DateTime.now();
    final canPickupNow = booking.isItemReady &&
        (now.isAfter(booking.startDate) ||
            now.isAtSameMomentAs(booking.startDate));
    final isItemPrepared = booking.isItemReady;
    final rentalHasStarted = now.isAfter(booking.startDate) ||
        now.isAtSameMomentAs(booking.startDate);

    IconData icon;
    Color color;
    String message;

    if (canPickupNow) {
      icon = Icons.check_circle;
      color = Colors.green;
      message = 'Available for pickup now';
    } else if (isItemPrepared && !rentalHasStarted) {
      icon = Icons.schedule;
      color = Colors.orange;
      final daysUntilPickup = booking.startDate.difference(now).inDays + 1;
      message =
          'Item prepared - Pickup available in $daysUntilPickup day${daysUntilPickup > 1 ? 's' : ''}';
    } else if (!isItemPrepared && rentalHasStarted) {
      icon = Icons.warning;
      color = Colors.red;
      message = 'Rental started but item not prepared yet';
    } else if (!isItemPrepared && !rentalHasStarted) {
      icon = Icons.pending;
      color = Colors.grey;
      message = 'Item being prepared by owner';
    } else {
      icon = Icons.help;
      color = Colors.grey;
      message = 'Status unknown';
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, RentalBookingModel booking) {
    List<Widget> buttons = [];

    if (booking.status == 'pending') {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Cancel booking
              context.read<BookingBloc>().add(
                    UpdateBookingStatus(
                      bookingId: booking.id,
                      status: 'cancelled',
                    ),
                  );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Cancel'),
          ),
        ),
      );
    }

    if (booking.status == 'confirmed') {
      final now = DateTime.now();
      final canPickupNow = booking.isItemReady &&
          (now.isAfter(booking.startDate) ||
              now.isAtSameMomentAs(booking.startDate));
      final isItemPrepared = booking.isItemReady;
      final rentalHasStarted = now.isAfter(booking.startDate) ||
          now.isAtSameMomentAs(booking.startDate);

      // Show appropriate button based on status
      if (canPickupNow) {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Show pickup instructions
                _showPickupInstructions(context, booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ready for Pickup'),
            ),
          ),
        );
      } else if (isItemPrepared && !rentalHasStarted) {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Show early pickup info
                _showEarlyPickupInfo(context, booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Prepared - View Info'),
            ),
          ),
        );
      } else {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Contact owner or view details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact owner feature coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Contact Owner'),
            ),
          ),
        );
      }

      // Add delivery address update button if delivery is required
      if (booking.needsDelivery) {
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                context.pushNamed(
                  'delivery-address-update',
                  pathParameters: {'rentalId': booking.id},
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                side: const BorderSide(color: ColorConstants.primaryColor),
              ),
              child: const Text('Update Address'),
            ),
          ),
        );
      }
    }

    if (booking.status == 'completed') {
      // Only show Leave Review button if renter hasn't rated yet
      final hasRated = booking.customerRatedAt != null;

      if (!hasRated) {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Show rating modal
                _showRatingModal(context, booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave Review'),
            ),
          ),
        );
      } else {
        // Optional: Show "Reviewed" status or nothing
        buttons.add(
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: ColorConstants.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConstants.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: ColorConstants.successColor,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reviewed',
                      style: TextStyle(
                        color: ColorConstants.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return buttons.isEmpty ? const SizedBox.shrink() : Row(children: buttons);
  }

  void _showPickupInstructions(
      BuildContext context, RentalBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready for Pickup! 📦'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rental "${booking.displayItemName}" is ready for pickup.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next Steps:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Contact the owner to arrange pickup time'),
            const Text('• Bring a valid ID and payment confirmation'),
            const Text('• Inspect the item before taking it'),
            if (booking.needsDelivery) ...[
              const SizedBox(height: 8),
              const Text(
                'Note: Since delivery is required, the owner will coordinate delivery details with you.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Contact owner action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact owner feature coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
            ),
            child: const Text('Contact Owner'),
          ),
        ],
      ),
    );
  }

  void _showEarlyPickupInfo(BuildContext context, RentalBookingModel booking) {
    final daysUntilPickup =
        booking.startDate.difference(DateTime.now()).inDays + 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Prepared! 📦'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rental "${booking.displayItemName}" has been prepared by the owner.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup available in $daysUntilPickup day${daysUntilPickup > 1 ? 's' : ''} (${_formatDate(booking.startDate)})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What this means:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Item is cleaned, tested, and ready'),
            const Text('• Owner has finished preparation'),
            const Text('• You can contact them to arrange details'),
            Text('• Pickup allowed starting ${_formatDate(booking.startDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Contact owner action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact owner feature coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
            ),
            child: const Text('Contact Owner'),
          ),
        ],
      ),
    );
  }

  String _safeSubstring(String text, int length) {
    if (text.length <= length) {
      return text;
    }
    return text.substring(0, length);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRatingModal(BuildContext context, RentalBookingModel booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => RateRentalSheet(
        promptData: RatingPromptEvent(
          rentalId: booking.id,
          itemName: booking.itemName ?? 'Unknown Item',
          counterPartyName: booking.ownerName ?? 'Unknown Owner',
          counterPartyId: booking.ownerId,
          isRenterRating: true, // Renter rating the owner
        ),
      ),
    );
  }
}
