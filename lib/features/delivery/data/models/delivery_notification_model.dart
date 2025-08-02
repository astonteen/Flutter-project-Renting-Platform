import 'package:equatable/equatable.dart';

enum DeliveryNotificationType {
  deliveryRequested,
  driverAssigned,
  headingToPickup,
  itemPickedUp,
  headingToDelivery,
  itemDelivered,
  returnScheduled,
  returnCompleted,
}

class DeliveryNotificationModel extends Equatable {
  final String id;
  final String deliveryId;
  final String recipientId;
  final DeliveryNotificationType notificationType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool pushNotificationSent;
  final bool emailSent;

  const DeliveryNotificationModel({
    required this.id,
    required this.deliveryId,
    required this.recipientId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
    this.pushNotificationSent = false,
    this.emailSent = false,
  });

  /// Factory constructor from JSON
  factory DeliveryNotificationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryNotificationModel(
      id: json['id'] ?? '',
      deliveryId: json['delivery_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      notificationType: _parseNotificationType(json['notification_type']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      sentAt:
          DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      pushNotificationSent: json['push_notification_sent'] ?? false,
      emailSent: json['email_sent'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'recipient_id': recipientId,
      'notification_type': _notificationTypeToString(notificationType),
      'title': title,
      'message': message,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'push_notification_sent': pushNotificationSent,
      'email_sent': emailSent,
    };
  }

  /// Parse notification type from string
  static DeliveryNotificationType _parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'delivery_requested':
        return DeliveryNotificationType.deliveryRequested;
      case 'driver_assigned':
        return DeliveryNotificationType.driverAssigned;
      case 'heading_to_pickup':
        return DeliveryNotificationType.headingToPickup;
      case 'item_picked_up':
        return DeliveryNotificationType.itemPickedUp;
      case 'heading_to_delivery':
        return DeliveryNotificationType.headingToDelivery;
      case 'item_delivered':
        return DeliveryNotificationType.itemDelivered;
      case 'return_scheduled':
        return DeliveryNotificationType.returnScheduled;
      case 'return_completed':
        return DeliveryNotificationType.returnCompleted;
      default:
        return DeliveryNotificationType.deliveryRequested;
    }
  }

  /// Convert notification type to string
  static String _notificationTypeToString(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.deliveryRequested:
        return 'delivery_requested';
      case DeliveryNotificationType.driverAssigned:
        return 'driver_assigned';
      case DeliveryNotificationType.headingToPickup:
        return 'heading_to_pickup';
      case DeliveryNotificationType.itemPickedUp:
        return 'item_picked_up';
      case DeliveryNotificationType.headingToDelivery:
        return 'heading_to_delivery';
      case DeliveryNotificationType.itemDelivered:
        return 'item_delivered';
      case DeliveryNotificationType.returnScheduled:
        return 'return_scheduled';
      case DeliveryNotificationType.returnCompleted:
        return 'return_completed';
    }
  }

  /// Get icon for notification type
  String get iconData {
    switch (notificationType) {
      case DeliveryNotificationType.deliveryRequested:
        return '📦';
      case DeliveryNotificationType.driverAssigned:
        return '🚗';
      case DeliveryNotificationType.headingToPickup:
        return '🏃‍♂️';
      case DeliveryNotificationType.itemPickedUp:
        return '✅';
      case DeliveryNotificationType.headingToDelivery:
        return '🚚';
      case DeliveryNotificationType.itemDelivered:
        return '🎉';
      case DeliveryNotificationType.returnScheduled:
        return '🔄';
      case DeliveryNotificationType.returnCompleted:
        return '✅';
    }
  }

  /// Get priority level (1-3, where 3 is highest)
  int get priority {
    switch (notificationType) {
      case DeliveryNotificationType.deliveryRequested:
        return 3; // High priority - needs approval
      case DeliveryNotificationType.itemDelivered:
        return 3; // High priority - completion
      case DeliveryNotificationType.driverAssigned:
        return 2; // Medium priority
      case DeliveryNotificationType.headingToPickup:
        return 2; // Medium priority
      case DeliveryNotificationType.itemPickedUp:
        return 2; // Medium priority
      case DeliveryNotificationType.headingToDelivery:
        return 2; // Medium priority
      case DeliveryNotificationType.returnScheduled:
        return 2; // Medium priority
      case DeliveryNotificationType.returnCompleted:
        return 1; // Low priority
    }
  }

  /// Whether this notification requires action
  bool get requiresAction {
    return notificationType == DeliveryNotificationType.deliveryRequested;
  }

  /// Time since notification was sent
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Create a copy with updated fields
  DeliveryNotificationModel copyWith({
    String? id,
    String? deliveryId,
    String? recipientId,
    DeliveryNotificationType? notificationType,
    String? title,
    String? message,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
    bool? pushNotificationSent,
    bool? emailSent,
  }) {
    return DeliveryNotificationModel(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      recipientId: recipientId ?? this.recipientId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      pushNotificationSent: pushNotificationSent ?? this.pushNotificationSent,
      emailSent: emailSent ?? this.emailSent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deliveryId,
        recipientId,
        notificationType,
        title,
        message,
        isRead,
        sentAt,
        readAt,
        pushNotificationSent,
        emailSent,
      ];

  @override
  String toString() {
    return 'DeliveryNotificationModel(id: $id, type: $notificationType, isRead: $isRead)';
  }
}
