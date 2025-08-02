import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ActionPriority {
  urgent, // Red - Overdue/critical issues
  today, // Orange - Due today
  scheduled, // Green - Scheduled/informational
  upcoming, // Blue - Preparation tasks
}

enum ActionType {
  approveDelivery,
  prepareForPickup,
  confirmReturn,
  respondToMessage,
  contactRenter,
  rescheduleDelivery,
  markItemReady,
  reviewOverdue,
}

extension ActionPriorityExtension on ActionPriority {
  Color get color {
    switch (this) {
      case ActionPriority.urgent:
        return Colors.red.shade600;
      case ActionPriority.today:
        return Colors.orange.shade600;
      case ActionPriority.scheduled:
        return Colors.green.shade600;
      case ActionPriority.upcoming:
        return Colors.blue.shade600;
    }
  }

  IconData get icon {
    switch (this) {
      case ActionPriority.urgent:
        return Icons.error;
      case ActionPriority.today:
        return Icons.schedule;
      case ActionPriority.scheduled:
        return Icons.check_circle_outline;
      case ActionPriority.upcoming:
        return Icons.upcoming;
    }
  }

  String get label {
    switch (this) {
      case ActionPriority.urgent:
        return 'URGENT';
      case ActionPriority.today:
        return 'TODAY';
      case ActionPriority.scheduled:
        return 'SCHEDULED';
      case ActionPriority.upcoming:
        return 'UPCOMING';
    }
  }
}

extension ActionTypeExtension on ActionType {
  IconData get icon {
    switch (this) {
      case ActionType.approveDelivery:
        return Icons.local_shipping;
      case ActionType.prepareForPickup:
        return Icons.inventory;
      case ActionType.confirmReturn:
        return Icons.assignment_return;
      case ActionType.respondToMessage:
        return Icons.message;
      case ActionType.contactRenter:
        return Icons.phone;
      case ActionType.rescheduleDelivery:
        return Icons.schedule;
      case ActionType.markItemReady:
        return Icons.check_box;
      case ActionType.reviewOverdue:
        return Icons.warning;
    }
  }

  String get actionButtonText {
    switch (this) {
      case ActionType.approveDelivery:
        return 'Approve';
      case ActionType.prepareForPickup:
        return 'Mark Ready';
      case ActionType.confirmReturn:
        return 'Confirm';
      case ActionType.respondToMessage:
        return 'Reply';
      case ActionType.contactRenter:
        return 'Contact';
      case ActionType.rescheduleDelivery:
        return 'Reschedule';
      case ActionType.markItemReady:
        return 'Mark Ready';
      case ActionType.reviewOverdue:
        return 'Review';
    }
  }
}

class LenderActionItem extends Equatable {
  final String id;
  final ActionType type;
  final ActionPriority priority;
  final String title;
  final String subtitle;
  final String renterName;
  final String itemName;
  final DateTime? dueTime;
  final String? additionalInfo;
  final String? relatedId; // booking ID, delivery ID, etc.
  final bool isCompleted;

  const LenderActionItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.renterName,
    required this.itemName,
    this.dueTime,
    this.additionalInfo,
    this.relatedId,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        priority,
        title,
        subtitle,
        renterName,
        itemName,
        dueTime,
        additionalInfo,
        relatedId,
        isCompleted,
      ];

  LenderActionItem copyWith({
    String? id,
    ActionType? type,
    ActionPriority? priority,
    String? title,
    String? subtitle,
    String? renterName,
    String? itemName,
    DateTime? dueTime,
    String? additionalInfo,
    String? relatedId,
    bool? isCompleted,
  }) {
    return LenderActionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      renterName: renterName ?? this.renterName,
      itemName: itemName ?? this.itemName,
      dueTime: dueTime ?? this.dueTime,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      relatedId: relatedId ?? this.relatedId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
