import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/rental/data/models/booking_model.dart';
import 'package:rent_ease/features/rental/data/models/rental_booking_model.dart';

class BookingRepository {
  // Create a new booking (rental) in the database
  Future<BookingModel> createBooking({
    required String itemId,
    required String renterId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalAmount,
    required double securityDeposit,
    bool deliveryRequired = false,
    String? deliveryAddress,
    String? deliveryInstructions,
  }) async {
    try {
      // Convert inclusive end date to exclusive for database operations
      final exclusiveEndDate = endDate.add(const Duration(days: 1));

      // Check availability first using the database function
      final availabilityResponse =
          await SupabaseService.client.rpc('check_item_availability', params: {
        'p_item_id': itemId,
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': exclusiveEndDate.toIso8601String(),
        'p_quantity_needed': 1,
      });

      if (availabilityResponse.isEmpty ||
          !availabilityResponse[0]['available']) {
        final totalQuantity = availabilityResponse.isNotEmpty
            ? availabilityResponse[0]['total_quantity'] ?? 0
            : 0;
        final availableQuantity = availabilityResponse.isNotEmpty
            ? availabilityResponse[0]['available_quantity'] ?? 0
            : 0;

        throw Exception('Item is not available for the selected dates. '
            'Available units: $availableQuantity/$totalQuantity');
      }

      // Get item details to find owner
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('owner_id')
          .eq('id', itemId)
          .single();

      final ownerId = itemResponse['owner_id'] as String;

      // Create rental record with race condition handling
      final rentalData = {
        'item_id': itemId,
        'renter_id': renterId,
        'owner_id': ownerId,
        'start_date': startDate.toIso8601String(),
        'end_date': exclusiveEndDate.toIso8601String(),
        'total_price': totalAmount,
        'security_deposit': securityDeposit,
        'status': 'pending',
        'payment_status': 'pending',
        'delivery_required': deliveryRequired,
      };

      try {
        final response = await SupabaseService.client
            .from('rentals')
            .insert(rentalData)
            .select()
            .single();

        final booking = BookingModel.fromJson(response);

        // If delivery is required and address is provided, update the delivery record
        if (deliveryRequired &&
            deliveryAddress != null &&
            deliveryAddress.isNotEmpty) {
          await _updateDeliveryAddress(
              booking.id, deliveryAddress, deliveryInstructions);
        }

        return booking;
      } catch (insertError) {
        // Handle potential race condition by rechecking availability
        debugPrint('Insert failed, rechecking availability: $insertError');

        final recheckResponse = await SupabaseService.client
            .rpc('check_item_availability', params: {
          'p_item_id': itemId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
          'p_quantity_needed': 1,
        });

        if (recheckResponse.isEmpty || !recheckResponse[0]['available']) {
          throw Exception(
              'Item became unavailable while processing your booking. '
              'Please try selecting different dates.');
        }

        // If still available, rethrow the original error
        throw Exception('Failed to create booking: $insertError');
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // Helper method to update delivery address after booking creation
  Future<void> _updateDeliveryAddress(
    String rentalId,
    String deliveryAddress,
    String? deliveryInstructions,
  ) async {
    try {
      await SupabaseService.client.from('deliveries').update({
        'dropoff_address': deliveryAddress,
        'special_instructions': deliveryInstructions,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('rental_id', rentalId);

      debugPrint(
          '✅ Successfully updated delivery address for rental: $rentalId');
    } catch (e) {
      debugPrint('❌ Error updating delivery address: $e');
      // Don't throw here as the booking was successful
      // The delivery address can be updated later by the customer
    }
  }

  // Get user's bookings (as renter)
  Future<List<RentalBookingModel>> getUserBookings(String userId) async {
    try {
      final response = await SupabaseService.client.from('rentals').select('''
            *,
            items(name, description, price_per_day, image_urls, primary_image_url),
            profiles!rentals_owner_id_fkey(full_name, avatar_url)
          ''').eq('renter_id', userId).order('created_at', ascending: false);

      return (response as List)
          .map((json) => RentalBookingModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading user bookings: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  // Get owner's bookings (rentals of their items)
  Future<List<RentalBookingModel>> getOwnerBookings(String userId) async {
    try {
      final response = await SupabaseService.client.from('rentals').select('''
            *,
            items(name, description, price_per_day, image_urls, primary_image_url),
            profiles!rentals_renter_id_fkey(full_name, avatar_url)
          ''').eq('owner_id', userId).order('created_at', ascending: false);

      return (response as List)
          .map((json) => RentalBookingModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading owner bookings: $e');
      throw Exception('Failed to load owner bookings: $e');
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await SupabaseService.client.from('rentals').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(
      String bookingId, String paymentStatus) async {
    try {
      await SupabaseService.client.from('rentals').update({
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response = await SupabaseService.client.from('rentals').select('''
            *,
            items(name, description, price_per_day),
            profiles!rentals_owner_id_fkey(full_name),
            profiles!rentals_renter_id_fkey(full_name)
          ''').eq('id', bookingId).single();

      return BookingModel.fromJson(response);
    } catch (e) {
      debugPrint('Error loading booking: $e');
      return null;
    }
  }

  // Create transaction record
  Future<void> createTransaction({
    required String rentalId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String paymentStatus,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    try {
      await SupabaseService.client.from('transactions').insert({
        'rental_id': rentalId,
        'transaction_id': transactionId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'gateway_response': gatewayResponse,
      });
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
    String transactionId,
    String status,
  ) async {
    try {
      await SupabaseService.client.from('transactions').update({
        'payment_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('transaction_id', transactionId);
    } catch (e) {
      debugPrint('Error updating transaction status: $e');
      throw Exception('Failed to update transaction status: $e');
    }
  }
}
