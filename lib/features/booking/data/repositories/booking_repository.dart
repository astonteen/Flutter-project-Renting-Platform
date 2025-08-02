import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/core/constants/app_constants.dart';

class BookingRepository {
  // Get all bookings for a specific listing (for owners)
  Future<List<BookingModel>> getBookingsForListing(String listingId) async {
    try {
      // Show bookings from the last 30 days and all future bookings
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              image_urls,
              primary_image_url
            )
          ''')
          .eq('item_id', listingId)
          .gte('end_date', thirtyDaysAgo.toIso8601String())
          .order('start_date', ascending: false);

      return response.map<BookingModel>((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final item = json['items'] as Map<String, dynamic>?;
        final primaryImageUrl = item?['primary_image_url'] as String? ?? '';
        final imageUrls = item?['image_urls'] as List<dynamic>? ?? [];

        // Use primary image, or first from image_urls if no primary set
        final finalImageUrl = primaryImageUrl.isNotEmpty
            ? primaryImageUrl
            : (imageUrls.isNotEmpty ? imageUrls.first.toString() : '');

        return BookingModel(
          id: json['id'] as String,
          listingId: json['item_id'] as String,
          listingName: item?['name'] as String? ?? 'Unknown Item',
          listingImageUrl: finalImageUrl,
          renterId: json['renter_id'] as String,
          renterName: profile?['full_name'] as String? ?? 'Unknown Renter',
          renterEmail: profile?['email'] as String? ?? '',
          renterPhone: profile?['phone_number'] as String?,
          renterAvatarUrl: profile?['avatar_url'] as String?,
          renterRating: 4.5, // TODO: Calculate from reviews
          renterReviewCount: 0, // TODO: Count from reviews
          startDate: DateTime.parse(json['start_date'] as String),
          endDate: DateTime.parse(json['end_date'] as String),
          totalAmount: double.parse(json['total_price'].toString()),
          securityDeposit: json['security_deposit'] != null
              ? double.parse(json['security_deposit'].toString())
              : 0.0,
          status: _mapStatus(json['status'] as String),
          specialRequests: '', // TODO: Add to database schema if needed
          notes: '', // TODO: Add to database schema if needed
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          isDeliveryRequired: json['delivery_required'] as bool? ?? false,
          isDepositPaid: json['payment_status'] == 'paid',
          isItemReady: json['is_item_ready'] as bool? ?? false,
          conversationId: null, // TODO: Link to messages table
          hasReturnDelivery: null, // No delivery tracking data available here
          returnDeliveryStatus: null,
          isReturnCompleted: null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      await SupabaseService.client.from('rentals').update({
        'status': _mapStatusToDatabase(status),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Mark item as ready for pickup
  Future<void> markItemReady(String bookingId, {bool isReady = true}) async {
    try {
      // If marking ready, validate timing and maintenance status
      if (isReady) {
        // Get booking details to check start date and item
        final bookingResponse = await SupabaseService.client
            .from('rentals')
            .select(
                'start_date, delivery_required, item_id, items(name, category_id, categories(name))')
            .eq('id', bookingId)
            .single();

        final startDate =
            DateTime.parse(bookingResponse['start_date'] as String);
        final isDeliveryRequired =
            bookingResponse['delivery_required'] as bool? ?? false;
        final itemId = bookingResponse['item_id'] as String;
        final itemData = bookingResponse['items'] as Map<String, dynamic>?;
        final itemName = itemData?['name'] as String? ?? 'item';
        final now = DateTime.now();

        // Define preparation windows
        final maxDaysEarly = isDeliveryRequired
            ? AppConstants.maxDaysEarlyDelivery
            : AppConstants.maxDaysEarlyPickup;
        final earliestReadyDate =
            startDate.subtract(Duration(days: maxDaysEarly));

        if (now.isBefore(earliestReadyDate)) {
          final daysUntilCanMark = earliestReadyDate.difference(now).inDays + 1;
          final pickupOrDelivery = isDeliveryRequired ? 'delivery' : 'pickup';

          throw Exception(
              'Item can only be marked ready $maxDaysEarly days before $pickupOrDelivery date. '
              'You can mark this item ready in $daysUntilCanMark day${daysUntilCanMark > 1 ? 's' : ''}.');
        }

        // Check for active maintenance blocks
        final maintenanceBlocks = await SupabaseService.client
            .from('availability_blocks')
            .select('blocked_from, blocked_until, reason, metadata')
            .eq('item_id', itemId)
            .eq('block_type', 'maintenance')
            .gte('blocked_until', now.toIso8601String())
            .order('blocked_from', ascending: true);

        if (maintenanceBlocks.isNotEmpty) {
          final activeBlock = maintenanceBlocks.first;
          final blockEnd = DateTime.parse(activeBlock['blocked_until']);
          final daysUntilAvailable = blockEnd.difference(now).inDays + 1;
          final maintenanceType =
              activeBlock['metadata']?['maintenance_type'] ?? 'maintenance';

          throw Exception(
              'Cannot mark $itemName as ready: currently under $maintenanceType until ${blockEnd.day}/${blockEnd.month}/${blockEnd.year}. '
              'Item will be available in $daysUntilAvailable day${daysUntilAvailable > 1 ? 's' : ''}.');
        }

        // Check for return buffer conflicts
        final returnBlocks = await SupabaseService.client
            .from('availability_blocks')
            .select('blocked_from, blocked_until, reason, rental_id')
            .eq('item_id', itemId)
            .eq('block_type', 'post_rental')
            .gte('blocked_until', now.toIso8601String())
            .order('blocked_from', ascending: true);

        if (returnBlocks.isNotEmpty) {
          final activeBlock = returnBlocks.first;
          final blockEnd = DateTime.parse(activeBlock['blocked_until']);
          final daysUntilAvailable = blockEnd.difference(now).inDays + 1;

          throw Exception(
              'Cannot mark $itemName as ready: currently in return processing period until ${blockEnd.day}/${blockEnd.month}/${blockEnd.year}. '
              'Item will be available in $daysUntilAvailable day${daysUntilAvailable > 1 ? 's' : ''}.');
        }
      }

      await SupabaseService.client.from('rentals').update({
        'is_item_ready': isReady,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception(
          'Failed to mark item as ${isReady ? 'ready' : 'not ready'}: $e');
    }
  }

  // Add notes to booking
  Future<void> addNotes(String bookingId, String notes) async {
    try {
      // TODO: Add notes field to database schema
      await SupabaseService.client.from('rentals').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to add notes: $e');
    }
  }

  // Get booking statistics for a listing
  Future<Map<String, dynamic>> getBookingStatistics(String listingId) async {
    try {
      // Show statistics from the last 30 days and all future bookings
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await SupabaseService.client
          .from('rentals')
          .select('status, total_price')
          .eq('item_id', listingId)
          .gte('end_date', thirtyDaysAgo.toIso8601String());

      final bookings = response as List<dynamic>;
      final confirmedBookings =
          bookings.where((b) => b['status'] == 'confirmed').length;
      final pendingBookings =
          bookings.where((b) => b['status'] == 'pending').length;
      final totalRevenue = bookings
          .where(
              (b) => b['status'] == 'confirmed' || b['status'] == 'completed')
          .fold(
              0.0, (sum, b) => sum + double.parse(b['total_price'].toString()));

      return {
        'confirmed_bookings': confirmedBookings,
        'pending_bookings': pendingBookings,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to load booking statistics: $e');
    }
  }

  // Helper method to map database status to BookingStatus enum
  BookingStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending; // Default fallback
    }
  }

  // Helper method to map BookingStatus enum to database status
  String _mapStatusToDatabase(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.overdue:
        return 'completed'; // Map overdue to completed in database
    }
  }
}
