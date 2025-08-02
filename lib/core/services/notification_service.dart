import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_notification_model.dart';
import 'package:rent_ease/core/services/expo_notification_service.dart';

/// Booking notification types for backwards compatibility
enum BookingNotificationType {
  bookingConfirmed,
  bookingCancelled,
  paymentRequired,
  reminderNotification,
  itemReady,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<DeliveryNotificationModel> _notifications = [];
  final List<Function(DeliveryNotificationModel)> _listeners = [];

  // Realtime subscriptions
  RealtimeChannel? _deliveryChannel;
  RealtimeChannel? _notificationChannel;

  /// Initialize the notification service
  static Future<void> initialize() async {
    await _instance._setupRealtimeSubscriptions();
    // Initialize Expo notifications
    await ExpoNotificationService.initialize();
    debugPrint('✅ NotificationService initialized');
  }

  /// Setup Supabase real-time subscriptions for live updates
  Future<void> _setupRealtimeSubscriptions() async {
    try {
      // Subscribe to delivery status changes
      _deliveryChannel = SupabaseService.client
          .channel('delivery_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'deliveries',
            callback: _handleDeliveryUpdate,
          )
          .subscribe();

      // Subscribe to new notifications (temporarily disabled - table missing)
      // TODO: Re-enable when delivery_notifications table is created
      // _notificationChannel = SupabaseService.client
      //     .channel('notification_updates')
      //     .onPostgresChanges(
      //       event: PostgresChangeEvent.insert,
      //       schema: 'public',
      //       table: 'delivery_notifications',
      //       callback: _handleNewNotification,
      //     )
      //     .subscribe();

      debugPrint('🔔 Real-time subscriptions active');
    } catch (e) {
      debugPrint('❌ Error setting up real-time subscriptions: $e');
    }
  }

  /// Handle delivery status updates
  void _handleDeliveryUpdate(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final delivery = DeliveryJobModel.fromJson(newRecord);
      _createStatusNotification(delivery);
      debugPrint('📦 Delivery status updated: ${delivery.statusDisplayText}');
    } catch (e) {
      debugPrint('❌ Error handling delivery update: $e');
    }
  }

  /// Create status-based notifications for delivery updates
  void _createStatusNotification(DeliveryJobModel delivery) {
    final notification = DeliveryNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deliveryId: delivery.id,
      recipientId: SupabaseService.currentUser?.id ?? '',
      notificationType: _getNotificationTypeFromStatus(delivery.status),
      title: _getNotificationTitle(
          delivery.status, delivery.itemName, delivery.isReturnDelivery),
      message: _getNotificationMessage(
          delivery.status, delivery.itemName, delivery.isReturnDelivery),
      sentAt: DateTime.now(),
    );

    _addNotification(notification);
    _showInAppNotification(notification);
  }

  /// Get notification type from delivery status
  DeliveryNotificationType _getNotificationTypeFromStatus(
      DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return DeliveryNotificationType.deliveryRequested;
      case DeliveryStatus.approved:
        return DeliveryNotificationType.deliveryRequested;
      case DeliveryStatus.driverAssigned:
        return DeliveryNotificationType.driverAssigned;
      case DeliveryStatus.driverHeadingToPickup:
        return DeliveryNotificationType.headingToPickup;
      case DeliveryStatus.itemCollected:
        return DeliveryNotificationType.itemPickedUp;
      case DeliveryStatus.driverHeadingToDelivery:
        return DeliveryNotificationType.headingToDelivery;
      case DeliveryStatus.itemDelivered:
        return DeliveryNotificationType.itemDelivered;
      case DeliveryStatus.returnRequested:
        return DeliveryNotificationType.returnScheduled;
      case DeliveryStatus.returnScheduled:
        return DeliveryNotificationType.returnScheduled;
      case DeliveryStatus.returnCollected:
        return DeliveryNotificationType.returnCompleted;
      case DeliveryStatus.returnDelivered:
        return DeliveryNotificationType.returnCompleted;
      case DeliveryStatus.completed:
        return DeliveryNotificationType.returnCompleted;
      case DeliveryStatus.cancelled:
        return DeliveryNotificationType.deliveryRequested;
    }
  }

  /// Get user-friendly notification titles
  String _getNotificationTitle(
      DeliveryStatus status, String itemName, bool isReturnDelivery) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return isReturnDelivery
            ? 'Return Request Submitted'
            : 'Delivery Request Created';
      case DeliveryStatus.approved:
        return isReturnDelivery
            ? 'Return Request Approved'
            : 'Delivery Approved';
      case DeliveryStatus.driverAssigned:
        return isReturnDelivery
            ? 'Driver Assigned for Return'
            : 'Driver Assigned';
      case DeliveryStatus.driverHeadingToPickup:
        return isReturnDelivery
            ? 'Driver En Route for Return Pickup'
            : 'Driver En Route to Pickup';
      case DeliveryStatus.itemCollected:
        return isReturnDelivery
            ? 'Item Collected for Return'
            : 'Item Picked Up';
      case DeliveryStatus.driverHeadingToDelivery:
        return isReturnDelivery
            ? 'Returning Item to Owner'
            : 'Out for Delivery';
      case DeliveryStatus.itemDelivered:
        return isReturnDelivery
            ? 'Return Completed! 🎉'
            : 'Delivered Successfully! 🎉';
      case DeliveryStatus.returnScheduled:
        return 'Return Pickup Scheduled';
      case DeliveryStatus.returnDelivered:
        return 'Return Completed';
      case DeliveryStatus.returnRequested:
        return 'Return Requested';
      case DeliveryStatus.returnCollected:
        return 'Return Item Collected';
      case DeliveryStatus.completed:
        return 'Delivery Completed';
      case DeliveryStatus.cancelled:
        return isReturnDelivery
            ? 'Return Request Cancelled'
            : 'Delivery Cancelled';
    }
  }

  /// Get detailed notification messages
  String _getNotificationMessage(
      DeliveryStatus status, String itemName, bool isReturnDelivery) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return isReturnDelivery
            ? 'Your return request for "$itemName" has been submitted and is awaiting owner approval.'
            : 'Your delivery request for "$itemName" is awaiting owner approval.';
      case DeliveryStatus.approved:
        return isReturnDelivery
            ? 'Great! Your return request for "$itemName" has been approved. Looking for a driver...'
            : 'Great! Your delivery for "$itemName" has been approved. Looking for a driver...';
      case DeliveryStatus.driverAssigned:
        return isReturnDelivery
            ? 'A driver has been assigned to collect "$itemName" for return. They\'ll be in touch soon!'
            : 'A driver has been assigned to deliver your "$itemName". They\'ll be in touch soon!';
      case DeliveryStatus.driverHeadingToPickup:
        return isReturnDelivery
            ? 'Your driver is heading to collect "$itemName" for return. Estimated pickup in 15-30 minutes.'
            : 'Your driver is heading to collect "$itemName". Estimated pickup in 15-30 minutes.';
      case DeliveryStatus.itemCollected:
        return isReturnDelivery
            ? 'Great! "$itemName" has been collected and is being returned to the owner.'
            : 'Great! Your "$itemName" has been collected and is now heading to you.';
      case DeliveryStatus.driverHeadingToDelivery:
        return isReturnDelivery
            ? 'Your "$itemName" is being returned to the owner. The rental is almost complete!'
            : 'Your "$itemName" is out for delivery! Track your order for live updates.';
      case DeliveryStatus.itemDelivered:
        return isReturnDelivery
            ? 'Your "$itemName" has been successfully returned to the owner. Thank you for your rental!'
            : 'Your "$itemName" has been delivered successfully. Enjoy your rental!';
      case DeliveryStatus.returnScheduled:
        return 'Return pickup for "$itemName" has been scheduled. A driver will collect it soon.';
      case DeliveryStatus.returnDelivered:
        return 'Your "$itemName" has been successfully returned to the owner. Thank you!';
      case DeliveryStatus.returnRequested:
        return 'Return has been requested for "$itemName". Awaiting schedule confirmation.';
      case DeliveryStatus.returnCollected:
        return 'Your "$itemName" has been collected for return and is being delivered back to the owner.';
      case DeliveryStatus.completed:
        return 'The delivery service for "$itemName" has been completed successfully.';
      case DeliveryStatus.cancelled:
        return isReturnDelivery
            ? 'Your return request for "$itemName" has been cancelled. Contact support if you need help.'
            : 'Your delivery for "$itemName" has been cancelled. Contact support if you need help.';
    }
  }

  /// Add notification to local storage
  void _addNotification(DeliveryNotificationModel notification) {
    _notifications.insert(0, notification); // Add to beginning for latest first

    // Keep only last 50 notifications to prevent memory issues
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(notification);
      } catch (e) {
        debugPrint('❌ Error in notification listener: $e');
      }
    }
  }

  /// Show in-app notification overlay
  void _showInAppNotification(DeliveryNotificationModel notification) {
    // Find the current context (this would be better with a navigation service)
    final context = WidgetsBinding.instance.rootElement;
    if (context == null) return;

    // Show overlay notification
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getNotificationColor(notification.notificationType),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.notificationType)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notification.iconData,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => overlayEntry.remove(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Entry might already be removed
      }
    });
  }

  /// Get color for notification type
  Color _getNotificationColor(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.deliveryRequested:
        return Colors.orange;
      case DeliveryNotificationType.driverAssigned:
        return Colors.blue;
      case DeliveryNotificationType.headingToPickup:
        return Colors.purple;
      case DeliveryNotificationType.itemPickedUp:
        return Colors.teal;
      case DeliveryNotificationType.headingToDelivery:
        return Colors.cyan;
      case DeliveryNotificationType.itemDelivered:
        return Colors.green;
      case DeliveryNotificationType.returnScheduled:
        return Colors.indigo;
      case DeliveryNotificationType.returnCompleted:
        return Colors.green;
    }
  }

  /// Get all notifications
  List<DeliveryNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );

        // Update in database if it's a real notification (temporarily disabled)
        // TODO: Re-enable when delivery_notifications table is created
        // await SupabaseService.client.from('delivery_notifications').update({
        //   'is_read': true,
        //   'read_at': DateTime.now().toIso8601String(),
        // }).eq('id', notificationId);
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadIds =
          _notifications.where((n) => !n.isRead).map((n) => n.id).toList();

      if (unreadIds.isEmpty) return;

      // Update local notifications
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }

      // Update in database (temporarily disabled)
      // TODO: Re-enable when delivery_notifications table is created
      // final userId = SupabaseService.currentUser?.id;
      // if (userId != null) {
      //   await SupabaseService.client
      //       .from('delivery_notifications')
      //       .update({
      //         'is_read': true,
      //         'read_at': DateTime.now().toIso8601String(),
      //       })
      //       .eq('recipient_id', userId)
      //       .eq('is_read', false);
      // }
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Add notification listener
  void addListener(Function(DeliveryNotificationModel) listener) {
    _listeners.add(listener);
  }

  /// Remove notification listener
  void removeListener(Function(DeliveryNotificationModel) listener) {
    _listeners.remove(listener);
  }

  /// Load existing notifications from database
  Future<void> loadNotifications() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      // Load from database (temporarily disabled - table missing)
      // TODO: Re-enable when delivery_notifications table is created
      // final response = await SupabaseService.client
      //     .from('delivery_notifications')
      //     .select('*')
      //     .eq('recipient_id', userId)
      //     .order('sent_at', ascending: false)
      //     .limit(50);

      // _notifications.clear();
      // _notifications.addAll(
      //     response.map((json) => DeliveryNotificationModel.fromJson(json)));

      // For now, just clear notifications
      _notifications.clear();

      debugPrint('📥 Loaded ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
    }
  }

  /// Send test notification
  static void sendTestNotification(String title, String message) {
    final notification = DeliveryNotificationModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      deliveryId: 'test_delivery',
      recipientId: SupabaseService.currentUser?.id ?? '',
      notificationType: DeliveryNotificationType.itemDelivered,
      title: title,
      message: message,
      sentAt: DateTime.now(),
    );

    _instance._addNotification(notification);
    _instance._showInAppNotification(notification);
  }

  /// Create notification for lender approval request (temporarily disabled)
  static Future<void> sendApprovalRequest({
    required String deliveryId,
    required String lenderId,
    required String itemName,
  }) async {
    // Temporarily disabled until delivery_notifications table is created
    debugPrint(
        '📤 Approval request notification for delivery $deliveryId (currently disabled - table missing)');

    // TODO: Re-enable when delivery_notifications table is created in database
    // try {
    //   await SupabaseService.client.rpc('create_delivery_notification', params: {
    //     'p_delivery_id': deliveryId,
    //     'p_recipient_id': lenderId,
    //     'p_notification_type': 'delivery_requested',
    //     'p_title': 'Delivery Approval Required',
    //     'p_message':
    //         'Please approve the delivery request for "$itemName". It will auto-approve in 2 hours if not reviewed.',
    //   });
    //   debugPrint('📤 Approval request notification sent');
    // } catch (e) {
    //   debugPrint('❌ Error sending approval request notification: $e');
    // }
  }

  /// Dispose resources and cleanup subscriptions
  void dispose() {
    _deliveryChannel?.unsubscribe();
    _notificationChannel?.unsubscribe();
    _listeners.clear();
  }

  // ====== LEGACY NOTIFICATION METHODS FOR BACKWARDS COMPATIBILITY ======

  /// Check if notifications are enabled (legacy method for settings screen)
  static Future<bool> areNotificationsEnabled() async {
    // Simple implementation - in a real app you'd check system notification permissions
    return true;
  }

  /// Show a local notification (legacy method for settings screen)
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Simple implementation - just print for now
    debugPrint('📱 Local Notification: $title - $body');

    // In a real implementation, you would use flutter_local_notifications
    // For now, just acknowledge the call
  }

  /// Show a booking notification (legacy method for booking bloc)
  static Future<void> showBookingNotification({
    required String bookingId,
    required String title,
    required String message,
    required BookingNotificationType type,
  }) async {
    debugPrint('📅 Booking Notification: $title - $message');

    // In a real implementation, you would:
    // 1. Store the notification in a booking_notifications table
    // 2. Send push notification if enabled
    // 3. Show in-app notification

    // For now, just acknowledge the call
  }

  /// Show item ready notification to renter
  static Future<void> showItemReadyNotification({
    required String bookingId,
    required String itemName,
    required String renterName,
    required String renterId,
  }) async {
    const title = 'Item Ready for Pickup! 📦';
    final message = 'Your rental "$itemName" is ready for pickup.';

    debugPrint(
        '✅ Item Ready Notification: $title - $message for user $renterId');

    // Show booking notification using existing method
    await showBookingNotification(
      bookingId: bookingId,
      title: title,
      message: message,
      type: BookingNotificationType.itemReady,
    );
  }

  /// Schedule a booking reminder (legacy method for booking bloc)
  static Future<void> scheduleBookingReminder({
    required String bookingId,
    required String itemName,
    required DateTime reminderTime,
  }) async {
    debugPrint('⏰ Booking Reminder scheduled for $itemName at $reminderTime');

    // In a real implementation, you would:
    // 1. Use flutter_local_notifications to schedule
    // 2. Store in database for server-side scheduling
    // 3. Handle timezone conversions

    // For now, just acknowledge the call
  }
}
