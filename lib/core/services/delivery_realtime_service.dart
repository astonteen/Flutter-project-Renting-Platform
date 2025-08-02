import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryRealtimeService {
  static DeliveryRealtimeService? _instance;
  static DeliveryRealtimeService get instance {
    _instance ??= DeliveryRealtimeService._internal();
    return _instance!;
  }

  DeliveryRealtimeService._internal();

  RealtimeChannel? _deliveryChannel;
  final StreamController<DeliveryJobModel> _deliveryUpdatesController =
      StreamController<DeliveryJobModel>.broadcast();

  /// Stream of delivery updates
  Stream<DeliveryJobModel> get deliveryUpdates =>
      _deliveryUpdatesController.stream;

  /// Subscribe to delivery updates for all deliveries the user is involved with
  void subscribeToDeliveryUpdates(String userId) {
    try {
      debugPrint(
          '🔄 Setting up delivery real-time subscription for user: $userId');

      // Unsubscribe from any existing channel
      unsubscribeFromDeliveryUpdates();

      _deliveryChannel = SupabaseService.client
          .channel('delivery_updates_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'deliveries',
            callback: (payload) {
              debugPrint('🔔 Delivery update received: ${payload.eventType}');
              _handleDeliveryUpdate(payload, userId);
            },
          )
          .subscribe();

      debugPrint('✅ Successfully subscribed to delivery updates');
    } catch (e) {
      debugPrint('❌ Error setting up delivery subscription: $e');
    }
  }

  /// Handle incoming delivery updates and filter for user
  void _handleDeliveryUpdate(PostgresChangePayload payload, String userId) {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isNotEmpty) {
        // Check if this delivery involves the current user
        final ownerId = newRecord['owner_id']?.toString();
        final renterId = newRecord['renter_id']?.toString();

        if (ownerId == userId || renterId == userId) {
          final delivery = DeliveryJobModel.fromJson(newRecord);
          debugPrint(
              '📦 Broadcasting delivery update: ${delivery.id} - ${delivery.status}');
          _deliveryUpdatesController.add(delivery);
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing delivery update: $e');
    }
  }

  /// Unsubscribe from delivery updates
  void unsubscribeFromDeliveryUpdates() {
    try {
      if (_deliveryChannel != null) {
        SupabaseService.client.removeChannel(_deliveryChannel!);
        _deliveryChannel = null;
        debugPrint('🔌 Unsubscribed from delivery updates');
      }
    } catch (e) {
      debugPrint('❌ Error unsubscribing from delivery updates: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    unsubscribeFromDeliveryUpdates();
    _deliveryUpdatesController.close();
  }
}
