import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';

/// Service to handle delivery scheduling and timing
/// This service ensures deliveries are only made available to drivers at appropriate times
class DeliverySchedulingService {
  static Timer? _schedulingTimer;
  static const Duration _checkInterval = Duration(hours: 1); // Check every hour

  /// Start the delivery scheduling service
  static void startScheduling() {
    debugPrint('🕐 Starting delivery scheduling service');

    // Run immediately on start
    _checkAndUpdateDeliveries();

    // Then run periodically
    _schedulingTimer = Timer.periodic(_checkInterval, (timer) {
      _checkAndUpdateDeliveries();
    });
  }

  /// Stop the delivery scheduling service
  static void stopScheduling() {
    debugPrint('🛑 Stopping delivery scheduling service');
    _schedulingTimer?.cancel();
    _schedulingTimer = null;
  }

  /// Check and update deliveries that should become available
  static Future<void> _checkAndUpdateDeliveries() async {
    try {
      debugPrint('🔄 Checking for deliveries to make available...');

      final result =
          await SupabaseService.client.rpc('make_deliveries_available');

      final updatedCount = result as int? ?? 0;

      if (updatedCount > 0) {
        debugPrint('✅ Made $updatedCount deliveries available to drivers');
      } else {
        debugPrint('📋 No deliveries needed to be updated');
      }
    } catch (e) {
      debugPrint('❌ Error in delivery scheduling service: $e');
    }
  }

  /// Manually trigger delivery availability check (useful for testing)
  static Future<int> checkDeliveriesNow() async {
    try {
      debugPrint('🔄 Manual check for deliveries to make available...');

      final result =
          await SupabaseService.client.rpc('make_deliveries_available');

      final updatedCount = result as int? ?? 0;
      debugPrint('✅ Made $updatedCount deliveries available to drivers');

      return updatedCount;
    } catch (e) {
      debugPrint('❌ Error in manual delivery check: $e');
      return 0;
    }
  }

  /// Check if a delivery should be available based on rental dates
  static bool shouldDeliveryBeAvailable(DateTime rentalStartDate) {
    final now = DateTime.now();
    final daysDifference = rentalStartDate.difference(now).inDays;

    // Delivery should be available 2 days before to 1 day after rental start
    return daysDifference >= -1 && daysDifference <= 2;
  }

  /// Get the estimated time when a delivery will become available
  static DateTime getDeliveryAvailableTime(DateTime rentalStartDate) {
    // Make delivery available 2 days before rental start
    return rentalStartDate.subtract(const Duration(days: 2));
  }

  /// Format time remaining until delivery becomes available
  static String formatTimeUntilAvailable(DateTime rentalStartDate) {
    final availableTime = getDeliveryAvailableTime(rentalStartDate);
    final now = DateTime.now();

    if (now.isAfter(availableTime)) {
      return 'Available now';
    }

    final difference = availableTime.difference(now);

    if (difference.inDays > 0) {
      return 'Available in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Available in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Available in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }
}
