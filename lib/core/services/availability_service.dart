import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';

class AvailabilityService {
  // COMPATIBILITY METHODS - for backward compatibility with existing code

  /// Legacy method - redirects to unified checkAvailability
  static Future<Map<String, dynamic>> checkItemAvailability({
    required String itemId,
    required DateTime date,
    int quantityNeeded = 1,
  }) async {
    final result = await checkAvailability(
      itemId: itemId,
      startDate: date,
      quantityNeeded: quantityNeeded,
    );
    return result[date] ??
        {
          'available': false,
          'total_quantity': 0,
          'available_quantity': 0,
          'blocked_quantity': 0,
          'booked_quantity': 0,
        };
  }

  /// Legacy method - redirects to unified checkAvailability
  static Future<Map<DateTime, Map<String, dynamic>>> getItemAvailabilityRange({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await checkAvailability(
      itemId: itemId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Unified availability check for single date or date range
  static Future<Map<DateTime, Map<String, dynamic>>> checkAvailability({
    required String itemId,
    required DateTime startDate,
    DateTime? endDate,
    int quantityNeeded = 1,
  }) async {
    final actualEndDate = endDate ?? startDate;

    try {
      // Use database function for efficient availability checking
      final response = await SupabaseService.client.rpc(
        'check_item_availability',
        params: {
          'p_item_id': itemId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date':
              actualEndDate.add(const Duration(days: 1)).toIso8601String(),
          'p_quantity_needed': quantityNeeded,
        },
      );

      if (response.isEmpty) {
        return {
          startDate: {
            'available': false,
            'total_quantity': 0,
            'available_quantity': 0,
            'blocked_quantity': 0,
            'booked_quantity': 0,
            'bookings': <Map<String, dynamic>>[],
            'blocks': <Map<String, dynamic>>[],
          }
        };
      }

      // For single date, return simple response
      if (endDate == null || startDate.isAtSameMomentAs(actualEndDate)) {
        final result = response.first as Map<String, dynamic>;
        return {
          startDate: {
            ...result,
            'bookings': <Map<String, dynamic>>[],
            'blocks': <Map<String, dynamic>>[],
          }
        };
      }

      // For date ranges, get detailed data
      return await _getDetailedAvailabilityRange(
        itemId: itemId,
        startDate: startDate,
        endDate: actualEndDate,
      );
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }

  /// Get detailed availability for date ranges with booking and block info
  static Future<Map<DateTime, Map<String, dynamic>>>
      _getDetailedAvailabilityRange({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<DateTime, Map<String, dynamic>> availabilityMap = {};

    // Get bookings and blocks for the entire range
    final bookings = await _getBookingsForItemInRange(
      itemId: itemId,
      startDate: startDate,
      endDate: endDate,
    );

    final blocks = await _getAvailabilityBlocksForItemInRange(
      itemId: itemId,
      startDate: startDate,
      endDate: endDate,
    );

    // Get item total quantity (assume 1 for simplification)
    final itemData = await SupabaseService.client
        .from('items')
        .select('quantity')
        .eq('id', itemId)
        .single();

    final totalQuantity = itemData['quantity'] as int? ?? 1;

    // Process each date in the range
    var currentDate = startDate;
    while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      final dateKey =
          DateTime(currentDate.year, currentDate.month, currentDate.day);

      // Dynamic quantity-based availability calculation
      final dayBookings = bookings
          .where((booking) =>
              _isDateInRange(dateKey, booking.startDate, booking.endDate))
          .toList();

      final dayBlocks = blocks
          .where((block) => _isDateInRange(
                dateKey,
                block['blocked_from'] as DateTime,
                block['blocked_until'] as DateTime,
              ))
          .toList();

      // Calculate actual quantities (not simplified boolean)
      final bookedQuantity = dayBookings.length; // Each booking = 1 unit
      final blockedQuantity = dayBlocks.fold<int>(
          0, (sum, block) => sum + (block['quantity_blocked'] as int? ?? 1));
      final availableQuantity =
          (totalQuantity - bookedQuantity - blockedQuantity)
              .clamp(0, totalQuantity);
      final isAvailable = availableQuantity > 0;

      availabilityMap[dateKey] = {
        'available': isAvailable,
        'total_quantity': totalQuantity,
        'available_quantity': availableQuantity,
        'blocked_quantity': blockedQuantity,
        'booked_quantity': bookedQuantity,
        'bookings': dayBookings.map((b) => b.toJson()).toList(),
        'blocks': dayBlocks,
      };

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return availabilityMap;
  }

  /// Helper method to check if a date falls within a range
  static bool _isDateInRange(
      DateTime date, DateTime startDate, DateTime endDate) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return (dateOnly.isAtSameMomentAs(startOnly) ||
            dateOnly.isAfter(startOnly)) &&
        (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
  }

  /// Get bookings for an item in a specific date range
  static Future<List<BookingModel>> _getBookingsForItemInRange({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
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
              name
            ),
            deliveries!deliveries_rental_id_fkey(
              id,
              delivery_type,
              status
            )
          ''')
          .eq('item_id', itemId)
          .gte('end_date', startDate.toIso8601String())
          .lte('start_date', endDate.toIso8601String())
          .filter('status', 'in', '(confirmed,in_progress,pending,completed)');

      return response.map<BookingModel>((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final item = json['items'] as Map<String, dynamic>?;

        // Extract delivery information
        final deliveries = json['deliveries'] as List<dynamic>? ?? [];
        final returnDelivery =
            deliveries.cast<Map<String, dynamic>>().firstWhere(
                  (delivery) => delivery['delivery_type'] == 'return_pickup',
                  orElse: () => <String, dynamic>{},
                );

        final hasReturnDelivery = returnDelivery.isNotEmpty;
        final returnDeliveryStatus =
            hasReturnDelivery ? (returnDelivery['status'] as String?) : null;
        final isReturnCompleted = hasReturnDelivery &&
            returnDeliveryStatus != null &&
            (returnDeliveryStatus == 'item_delivered' ||
                returnDeliveryStatus == 'return_delivered' ||
                returnDeliveryStatus == 'completed');

        return BookingModel(
          id: json['id'] as String,
          listingId: json['item_id'] as String,
          listingName: item?['name'] as String? ?? 'Unknown Item',
          listingImageUrl: '',
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
          specialRequests: '', // Not available in rentals table
          notes: '', // Not available in rentals table
          isDeliveryRequired: json['delivery_required'] as bool? ?? false,
          deliveryAddress: '', // Not available in rentals table
          deliveryFee: json['delivery_fee'] != null
              ? double.parse(json['delivery_fee'].toString())
              : null,
          isDepositPaid: json['payment_status'] == 'paid',
          isItemReady: json['is_item_ready'] as bool? ?? false,
          conversationId: null, // Not available in rentals table
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          hasReturnDelivery: hasReturnDelivery,
          returnDeliveryStatus: returnDeliveryStatus,
          isReturnCompleted: isReturnCompleted,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get bookings for item: $e');
    }
  }

  /// Get availability blocks for an item in a specific date range
  /// Note: This excludes 'post_rental' blocks since return indicators are now separate
  static Future<List<Map<String, dynamic>>>
      _getAvailabilityBlocksForItemInRange({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('availability_blocks')
          .select('*')
          .eq('item_id', itemId)
          .gte('blocked_until', startDate.toIso8601String())
          .lte('blocked_from', endDate.toIso8601String())
          // Exclude post_rental blocks - they are now return indicators (lender-only)
          .neq('block_type', 'post_rental');

      return response.map<Map<String, dynamic>>((json) {
        return {
          'id': json['id'],
          'item_id': json['item_id'],
          'rental_id': json['rental_id'],
          'blocked_from': DateTime.parse(json['blocked_from'] as String),
          'blocked_until': DateTime.parse(json['blocked_until'] as String),
          'block_type': json['block_type'] as String? ?? 'manual',
          'reason': json['reason'] as String?,
          'quantity_blocked': json['quantity_blocked'] as int? ?? 1,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get availability blocks for item: $e');
    }
  }

  /// Complete a rental to trigger automatic return indicator creation
  /// Return indicators are now separate from availability blocking
  static Future<void> completeRentalWithAutoBuffer({
    required String rentalId,
  }) async {
    try {
      await SupabaseService.client.from('rentals').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rentalId);

      debugPrint(
          '✅ Rental completed - return indicator will be created by database trigger');
    } catch (e) {
      throw Exception('Failed to complete rental: $e');
    }
  }

  /// Get return indicators for lender-only visibility
  static Future<List<Map<String, dynamic>>> getReturnIndicatorsForItem({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('return_indicators')
          .select('''
            *,
            rentals!return_indicators_rental_id_fkey(
              renter_id,
              start_date,
              end_date,
              total_price
            )
          ''')
          .eq('item_id', itemId)
          .gte('expected_return_date', startDate.toIso8601String())
          .lte('expected_return_date', endDate.toIso8601String())
          .order('expected_return_date', ascending: true);

      return response.map<Map<String, dynamic>>((json) {
        final rental = json['rentals'] as Map<String, dynamic>?;
        return {
          'id': json['id'],
          'item_id': json['item_id'],
          'rental_id': json['rental_id'],
          'expected_return_date':
              DateTime.parse(json['expected_return_date'] as String),
          'actual_return_date': json['actual_return_date'] != null
              ? DateTime.parse(json['actual_return_date'] as String)
              : null,
          'return_status': json['return_status'] as String? ?? 'pending',
          'buffer_days': json['buffer_days'] as int? ?? 0,
          'reason': json['reason'] as String?,
          'notes': json['notes'] as String?,
          'rental_start_date': rental != null
              ? DateTime.parse(rental['start_date'] as String)
              : null,
          'rental_end_date': rental != null
              ? DateTime.parse(rental['end_date'] as String)
              : null,
          'rental_price': rental?['total_price'],
          'renter_id': rental?['renter_id'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get return indicators: $e');
    }
  }

  /// Complete a return indicator and optionally create maintenance block
  static Future<void> completeReturnIndicator({
    required String rentalId,
    bool createMaintenanceBlock = false,
    int? maintenanceDays,
  }) async {
    try {
      final result = await SupabaseService.client.rpc(
        'complete_return_indicator',
        params: {
          'p_rental_id': rentalId,
          'p_create_maintenance_block': createMaintenanceBlock,
          'p_maintenance_days': maintenanceDays,
        },
      );

      if (result == false) {
        throw Exception('Failed to complete return indicator');
      }

      debugPrint(
          '✅ Return indicator completed${createMaintenanceBlock ? ' with maintenance block' : ''}');
    } catch (e) {
      throw Exception('Failed to complete return indicator: $e');
    }
  }

  /// Extend return deadline for flexible return management
  static Future<void> extendReturnDeadline({
    required String rentalId,
    required int additionalDays,
    String? reason,
  }) async {
    try {
      final result = await SupabaseService.client.rpc(
        'extend_return_deadline',
        params: {
          'p_rental_id': rentalId,
          'p_additional_days': additionalDays,
          'p_reason': reason,
        },
      );

      if (result == false) {
        throw Exception('Failed to extend return deadline');
      }

      debugPrint('✅ Return deadline extended by $additionalDays days');
    } catch (e) {
      throw Exception('Failed to extend return deadline: $e');
    }
  }

  /// Remove auto-block for a specific rental
  static Future<void> removeAutoBlockForRental({
    required String rentalId,
  }) async {
    try {
      await SupabaseService.client
          .from('availability_blocks')
          .delete()
          .eq('rental_id', rentalId)
          .eq('block_type', 'post_rental');
    } catch (e) {
      throw Exception('Failed to remove auto-block: $e');
    }
  }

  /// Create manual block for specific dates
  static Future<void> createManualBlock({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    int quantityToBlock = 1,
  }) async {
    try {
      await SupabaseService.client.from('availability_blocks').insert({
        'item_id': itemId,
        'blocked_from': startDate.toIso8601String(),
        'blocked_until': endDate.toIso8601String(),
        'block_type': 'manual',
        'reason': reason,
        'quantity_blocked': quantityToBlock,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create manual block: $e');
    }
  }

  /// Remove manual block by ID
  static Future<void> removeManualBlock({
    required String blockId,
  }) async {
    try {
      await SupabaseService.client
          .from('availability_blocks')
          .delete()
          .eq('id', blockId)
          .eq('block_type', 'manual');
    } catch (e) {
      throw Exception('Failed to remove manual block: $e');
    }
  }

  /// Create maintenance block with predefined durations
  static Future<void> createMaintenanceBlock({
    required String itemId,
    required DateTime startDate,
    required String maintenanceType, // cleaning, inspection, repair
    required String reason,
    int quantityToBlock = 1,
  }) async {
    try {
      // Simplified duration mapping
      final duration = switch (maintenanceType) {
        'cleaning' => 1,
        'inspection' => 1,
        'repair' => 3,
        _ => 1,
      };

      final endDate = startDate.add(Duration(days: duration));

      await SupabaseService.client.from('availability_blocks').insert({
        'item_id': itemId,
        'blocked_from': startDate.toIso8601String(),
        'blocked_until': endDate.toIso8601String(),
        'block_type': 'maintenance',
        'reason': '$maintenanceType: $reason',
        'quantity_blocked': quantityToBlock,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint(
          '✅ Maintenance block created: $maintenanceType for $duration days');
    } catch (e) {
      throw Exception('Failed to create maintenance block: $e');
    }
  }

  /// Helper method to map database status to BookingStatus enum
  static BookingStatus _mapStatus(String status) {
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
        return BookingStatus.pending;
    }
  }

  /// Debug method to check if auto-blocks are working properly
  static Future<Map<String, dynamic>> debugAutoBlocks({
    required String itemId,
  }) async {
    try {
      // Check item configuration
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('id, name, blocking_days, blocking_reason')
          .eq('id', itemId)
          .single();

      // Check ALL rentals for this item
      final allRentalsResponse = await getAllRentalsForItem(itemId: itemId);

      // Check completed rentals for this item
      final completedRentalsResponse = await SupabaseService.client
          .from('rentals')
          .select('id, status, start_date, end_date')
          .eq('item_id', itemId)
          .eq('status', 'completed')
          .order('end_date', ascending: false)
          .limit(5);

      // Check existing auto-blocks
      final blocksResponse = await SupabaseService.client
          .from('availability_blocks')
          .select('*')
          .eq('item_id', itemId)
          .eq('block_type', 'post_rental')
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'item_config': itemResponse,
        'all_rentals': allRentalsResponse,
        'completed_rentals': completedRentalsResponse,
        'auto_blocks': blocksResponse,
        'debug_info': {
          'blocking_days': itemResponse['blocking_days'],
          'all_rentals_count': allRentalsResponse.length,
          'completed_rentals_count': completedRentalsResponse.length,
          'auto_blocks_count': blocksResponse.length,
        }
      };
    } catch (e) {
      throw Exception('Failed to debug auto-blocks: $e');
    }
  }

  /// Mark a rental as completed to trigger auto-block creation
  static Future<void> markRentalCompleted({
    required String rentalId,
  }) async {
    try {
      await SupabaseService.client.from('rentals').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rentalId);
    } catch (e) {
      throw Exception('Failed to mark rental as completed: $e');
    }
  }

  /// Complete a rental using the database function (with authorization)
  static Future<void> completeRental({
    required String rentalId,
    String? lenderId,
  }) async {
    try {
      final response = await SupabaseService.client.rpc(
        'complete_rental',
        params: {
          'p_rental_id': rentalId,
          if (lenderId != null) 'p_lender_id': lenderId,
        },
      );

      if (response == false) {
        throw Exception('Failed to complete rental - check permissions');
      }
    } catch (e) {
      throw Exception('Failed to complete rental: $e');
    }
  }

  /// Auto-complete expired rentals (manual trigger)
  static Future<int> autoCompleteExpiredRentals() async {
    try {
      final result =
          await SupabaseService.client.rpc('auto_complete_expired_rentals');
      return result as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to auto-complete rentals: $e');
    }
  }

  /// Complete all confirmed/inProgress rentals that have ended for an item
  /// This will trigger auto-blocks for rentals that should have been completed
  static Future<Map<String, dynamic>> completeExpiredRentalsForItem({
    required String itemId,
  }) async {
    try {
      // Get all confirmed/inProgress rentals that have ended
      final now = DateTime.now();
      final expiredRentals = await SupabaseService.client
          .from('rentals')
          .select('id, status, start_date, end_date')
          .eq('item_id', itemId)
          .inFilter('status', ['confirmed', 'inProgress'])
          .lt('end_date', now.toIso8601String())
          .order('end_date', ascending: false);

      int completedCount = 0;
      List<String> completedRentalIds = [];

      // Mark each expired rental as completed
      for (final rental in expiredRentals) {
        try {
          await markRentalCompleted(rentalId: rental['id']);
          completedCount++;
          completedRentalIds.add(rental['id']);
        } catch (e) {
          debugPrint('Failed to complete rental ${rental['id']}: $e');
        }
      }

      return {
        'total_expired': expiredRentals.length,
        'completed_count': completedCount,
        'completed_rental_ids': completedRentalIds,
        'expired_rentals': expiredRentals,
      };
    } catch (e) {
      throw Exception('Failed to complete expired rentals: $e');
    }
  }

  /// Get all rentals for an item (for debugging)
  static Future<List<Map<String, dynamic>>> getAllRentalsForItem({
    required String itemId,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('rentals')
          .select('id, status, start_date, end_date, renter_id')
          .eq('item_id', itemId)
          .order('end_date', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get rentals: $e');
    }
  }

  /// Debug delivery approval auto-blocks for an item
  static Future<Map<String, dynamic>> debugDeliveryAutoBlocks({
    required String itemId,
  }) async {
    try {
      // Check item configuration
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('id, name, blocking_days, blocking_reason')
          .eq('id', itemId)
          .single();

      // Check rentals with deliveries for this item
      final rentalsWithDeliveries = await SupabaseService.client
          .from('rentals')
          .select(
              'id, status, start_date, end_date, deliveries(id, status, lender_approved_at)')
          .eq('item_id', itemId)
          .order('end_date', ascending: false)
          .limit(5);

      // Check existing auto-blocks
      final blocksResponse = await SupabaseService.client
          .from('availability_blocks')
          .select('*')
          .eq('item_id', itemId)
          .eq('block_type', 'post_rental')
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'item_config': itemResponse,
        'rentals_with_deliveries': rentalsWithDeliveries,
        'auto_blocks': blocksResponse,
        'debug_info': {
          'blocking_days': itemResponse['blocking_days'],
          'rentals_count': rentalsWithDeliveries.length,
          'auto_blocks_count': blocksResponse.length,
        }
      };
    } catch (e) {
      throw Exception('Failed to debug delivery auto-blocks: $e');
    }
  }

  /// Manually approve a delivery to trigger auto-block creation (for testing)
  static Future<void> manuallyApproveDelivery({
    required String deliveryId,
  }) async {
    try {
      await SupabaseService.client.from('deliveries').update({
        'status': 'approved',
        'lender_approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);
    } catch (e) {
      throw Exception('Failed to approve delivery: $e');
    }
  }

  /// Manually trigger auto-block creation for testing
  static Future<void> manuallyCreateAutoBlock({
    required String itemId,
    required String rentalId,
    required DateTime rentalEndDate,
  }) async {
    try {
      // Get item configuration
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('blocking_days, blocking_reason')
          .eq('id', itemId)
          .single();

      final blockingDays = itemResponse['blocking_days'] as int? ?? 2;
      final blockingReason = itemResponse['blocking_reason'] as String? ??
          'Post-rental review and maintenance';

      if (blockingDays > 0) {
        final blockStartDate = rentalEndDate;
        final blockEndDate = rentalEndDate.add(Duration(days: blockingDays));

        await SupabaseService.client.from('availability_blocks').insert({
          'item_id': itemId,
          'rental_id': rentalId,
          'blocked_from': blockStartDate.toIso8601String(),
          'blocked_until': blockEndDate.toIso8601String(),
          'block_type': 'post_rental',
          'reason': 'Manually created for testing: $blockingReason',
          'quantity_blocked': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to manually create auto-block: $e');
    }
  }

  /// Legacy method - redirects to completeRentalWithAutoBuffer
  static Future<void> createAutoBlockAfterBooking({
    required String itemId,
    required String rentalId,
    required DateTime bookingEndDate,
    int quantityToBlock = 1,
  }) async {
    await completeRentalWithAutoBuffer(rentalId: rentalId);
  }

  /// Legacy method - calculate return buffer days (now handled by database trigger)
  /// This is kept for backward compatibility but returns default values
  static int calculateReturnBufferDays({
    required String categoryName,
    required String condition,
    required double totalAmount,
    required bool hasDeliveryReturn,
  }) {
    // Simple calculation for backward compatibility
    // The actual calculation is now done in the database trigger
    int bufferDays = 2; // default

    // Basic category mapping
    if (categoryName.toLowerCase().contains('electronic')) bufferDays = 3;
    if (categoryName.toLowerCase().contains('automotive')) bufferDays = 4;
    if (categoryName.toLowerCase().contains('clothing')) bufferDays = 1;

    // Condition adjustment
    if (condition == 'fair') bufferDays += 1;
    if (condition == 'poor') bufferDays += 2;

    // High-value adjustment
    if (totalAmount > 500.0) bufferDays += 1;

    // Delivery return adjustment
    if (hasDeliveryReturn) bufferDays += 1;

    return bufferDays.clamp(1, 7);
  }
}
