import 'package:rent_ease/features/home/data/models/lender_action_item.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

class LenderActionService {
  static const instance = LenderActionService._();
  const LenderActionService._();

  /// Generate action items from current bookings and deliveries
  List<LenderActionItem> generateActionItems({
    required List<BookingModel> bookings,
    required List<DeliveryJobModel> deliveries,
    required int unreadMessages,
  }) {
    final List<LenderActionItem> actions = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Add unread messages action if any
    if (unreadMessages > 0) {
      actions.add(LenderActionItem(
        id: 'unread_messages',
        type: ActionType.respondToMessage,
        priority:
            unreadMessages > 5 ? ActionPriority.urgent : ActionPriority.today,
        title: 'Respond to messages',
        subtitle:
            '$unreadMessages unread message${unreadMessages > 1 ? 's' : ''}',
        renterName: 'Multiple renters',
        itemName: '',
        dueTime: now,
      ));
    }

    // Process delivery actions
    for (final delivery in deliveries) {
      final deliveryActions = _generateDeliveryActions(delivery, today, now);
      actions.addAll(deliveryActions);
    }

    // Process booking actions
    for (final booking in bookings) {
      final bookingActions =
          _generateBookingActions(booking, today, tomorrow, now);
      actions.addAll(bookingActions);
    }

    // Sort by priority and due time
    actions.sort((a, b) {
      // First sort by priority
      final priorityComparison = _getPriorityOrder(a.priority)
          .compareTo(_getPriorityOrder(b.priority));
      if (priorityComparison != 0) return priorityComparison;

      // Then by due time
      if (a.dueTime != null && b.dueTime != null) {
        return a.dueTime!.compareTo(b.dueTime!);
      } else if (a.dueTime != null) {
        return -1; // a has due time, b doesn't - a comes first
      } else if (b.dueTime != null) {
        return 1; // b has due time, a doesn't - b comes first
      }

      return 0;
    });

    return actions;
  }

  int _getPriorityOrder(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.urgent:
        return 0;
      case ActionPriority.today:
        return 1;
      case ActionPriority.scheduled:
        return 2;
      case ActionPriority.upcoming:
        return 3;
    }
  }

  List<LenderActionItem> _generateDeliveryActions(
    DeliveryJobModel delivery,
    DateTime today,
    DateTime now,
  ) {
    final List<LenderActionItem> actions = [];

    switch (delivery.status) {
      case DeliveryStatus.pendingApproval:
        if (delivery.lenderApprovalRequired) {
          final isUrgent = delivery.lenderApprovalTimeout != null &&
              delivery.lenderApprovalTimeout!
                  .isBefore(now.add(const Duration(hours: 1)));

          actions.add(LenderActionItem(
            id: 'delivery_approval_${delivery.id}',
            type: ActionType.approveDelivery,
            priority: isUrgent ? ActionPriority.urgent : ActionPriority.today,
            title: 'Approve delivery request',
            subtitle: isUrgent
                ? 'Approval expires soon!'
                : 'Delivery to ${delivery.deliveryAddress}',
            renterName: delivery.customerName ?? 'Unknown',
            itemName: delivery.itemName,
            dueTime: delivery.lenderApprovalTimeout,
            relatedId: delivery.id,
          ));
        }
        break;

      case DeliveryStatus.approved:
        actions.add(LenderActionItem(
          id: 'delivery_finding_driver_${delivery.id}',
          type: ActionType.prepareForPickup,
          priority: ActionPriority.scheduled,
          title: 'Prepare item for pickup',
          subtitle:
              'Driver will be assigned at the appropriate time before rental',
          renterName: delivery.customerName ?? 'Unknown',
          itemName: delivery.itemName,
          dueTime: delivery.estimatedPickupTime,
          relatedId: delivery.id,
        ));
        break;

      case DeliveryStatus.driverAssigned:
      case DeliveryStatus.driverHeadingToPickup:
        final isToday = delivery.estimatedPickupTime != null &&
            _isSameDay(delivery.estimatedPickupTime!, today);

        actions.add(LenderActionItem(
          id: 'delivery_pickup_ready_${delivery.id}',
          type: ActionType.prepareForPickup,
          priority: isToday ? ActionPriority.today : ActionPriority.upcoming,
          title: isToday ? 'Item pickup today' : 'Prepare for pickup',
          subtitle: delivery.status == DeliveryStatus.driverHeadingToPickup
              ? 'Driver is on the way'
              : 'Driver assigned - prepare item',
          renterName: delivery.customerName ?? 'Unknown',
          itemName: delivery.itemName,
          dueTime: delivery.estimatedPickupTime,
          relatedId: delivery.id,
        ));
        break;

      case DeliveryStatus.returnRequested:
        actions.add(LenderActionItem(
          id: 'return_request_${delivery.id}',
          type: ActionType.confirmReturn,
          priority: ActionPriority.today,
          title: 'Return requested',
          subtitle: 'Renter wants to schedule return',
          renterName: delivery.customerName ?? 'Unknown',
          itemName: delivery.itemName,
          dueTime: now,
          relatedId: delivery.id,
        ));
        break;

      case DeliveryStatus.returnCollected:
        actions.add(LenderActionItem(
          id: 'return_delivery_${delivery.id}',
          type: ActionType.confirmReturn,
          priority: ActionPriority.scheduled,
          title: 'Item being returned',
          subtitle: 'Driver is bringing your item back',
          renterName: delivery.customerName ?? 'Unknown',
          itemName: delivery.itemName,
          dueTime: delivery.estimatedDeliveryTime,
          relatedId: delivery.id,
        ));
        break;

      case DeliveryStatus.itemCollected:
      case DeliveryStatus.driverHeadingToDelivery:
      case DeliveryStatus.itemDelivered:
      case DeliveryStatus.returnScheduled:
      case DeliveryStatus.returnDelivered:
      case DeliveryStatus.completed:
      case DeliveryStatus.cancelled:
        // These statuses don't require lender actions
        break;
    }

    return actions;
  }

  List<LenderActionItem> _generateBookingActions(
    BookingModel booking,
    DateTime today,
    DateTime tomorrow,
    DateTime now,
  ) {
    final List<LenderActionItem> actions = [];

    switch (booking.status) {
      case BookingStatus.pending:
        actions.add(LenderActionItem(
          id: 'booking_approval_${booking.id}',
          type: ActionType.markItemReady,
          priority: ActionPriority.today,
          title: 'Review booking request',
          subtitle: 'Pending your approval',
          renterName: booking.renterName,
          itemName: booking.listingName,
          dueTime: now,
          relatedId: booking.id,
        ));
        break;

      case BookingStatus.confirmed:
        final startsToday = _isSameDay(booking.startDate, today);
        final startsTomorrow = _isSameDay(booking.startDate, tomorrow);
        final startsThisWeek =
            booking.startDate.isBefore(today.add(const Duration(days: 7)));

        if (startsToday) {
          actions.add(LenderActionItem(
            id: 'booking_starts_today_${booking.id}',
            type: ActionType.prepareForPickup,
            priority: ActionPriority.today,
            title: 'Rental starts today',
            subtitle: booking.isDeliveryRequired
                ? 'Delivery scheduled'
                : 'Pickup scheduled',
            renterName: booking.renterName,
            itemName: booking.listingName,
            dueTime: booking.startDate,
            relatedId: booking.id,
          ));
        } else if (startsTomorrow) {
          actions.add(LenderActionItem(
            id: 'booking_starts_tomorrow_${booking.id}',
            type: ActionType.prepareForPickup,
            priority: ActionPriority.upcoming,
            title: 'Rental starts tomorrow',
            subtitle: 'Prepare ${booking.listingName}',
            renterName: booking.renterName,
            itemName: booking.listingName,
            dueTime: booking.startDate,
            relatedId: booking.id,
          ));
        } else if (startsThisWeek) {
          actions.add(LenderActionItem(
            id: 'booking_starts_week_${booking.id}',
            type: ActionType.prepareForPickup,
            priority: ActionPriority.upcoming,
            title: 'Rental starts ${_formatDayName(booking.startDate)}',
            subtitle: 'Prepare ${booking.listingName}',
            renterName: booking.renterName,
            itemName: booking.listingName,
            dueTime: booking.startDate,
            relatedId: booking.id,
          ));
        }
        break;

      case BookingStatus.inProgress:
        final endsToday = _isSameDay(booking.endDate, today);
        final endsTomorrow = _isSameDay(booking.endDate, tomorrow);

        if (endsToday) {
          actions.add(LenderActionItem(
            id: 'booking_ends_today_${booking.id}',
            type: ActionType.confirmReturn,
            priority: ActionPriority.today,
            title: 'Return due today',
            subtitle: booking.isDeliveryRequired
                ? 'Expect return delivery'
                : 'Expect return pickup',
            renterName: booking.renterName,
            itemName: booking.listingName,
            dueTime: booking.endDate,
            relatedId: booking.id,
          ));
        } else if (endsTomorrow) {
          actions.add(LenderActionItem(
            id: 'booking_ends_tomorrow_${booking.id}',
            type: ActionType.confirmReturn,
            priority: ActionPriority.upcoming,
            title: 'Return due tomorrow',
            subtitle: 'Rental period ending',
            renterName: booking.renterName,
            itemName: booking.listingName,
            dueTime: booking.endDate,
            relatedId: booking.id,
          ));
        }
        break;

      case BookingStatus.overdue:
        actions.add(LenderActionItem(
          id: 'booking_overdue_${booking.id}',
          type: ActionType.contactRenter,
          priority: ActionPriority.urgent,
          title: 'Item overdue',
          subtitle: 'Contact ${booking.renterName} immediately',
          renterName: booking.renterName,
          itemName: booking.listingName,
          dueTime: booking.endDate,
          relatedId: booking.id,
        ));
        break;

      // Note: Additional booking workflow statuses may be handled by UI workflow buttons

      case BookingStatus.completed:
      case BookingStatus.cancelled:
        // These statuses don't require lender actions
        break;
    }

    return actions;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDayName(DateTime date) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[date.weekday - 1];
  }

  /// Filter actions for today tab
  List<LenderActionItem> getTodayActions(List<LenderActionItem> actions) {
    return actions
        .where((action) =>
            action.priority == ActionPriority.urgent ||
            action.priority == ActionPriority.today ||
            action.priority == ActionPriority.scheduled)
        .toList();
  }

  /// Filter actions for upcoming tab
  List<LenderActionItem> getUpcomingActions(List<LenderActionItem> actions) {
    return actions
        .where((action) => action.priority == ActionPriority.upcoming)
        .toList();
  }
}
