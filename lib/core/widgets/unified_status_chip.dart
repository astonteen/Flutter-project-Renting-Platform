import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

enum StatusType {
  booking,
  delivery,
  listing,
  payment,
  user,
}

class UnifiedStatusChip extends StatelessWidget {
  final dynamic status;
  final StatusType type;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showIcon;
  final String? customText;

  const UnifiedStatusChip({
    super.key,
    required this.status,
    required this.type,
    this.fontSize,
    this.padding,
    this.showIcon = true,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withAlpha(75), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && config.icon != null) ...[
            Icon(
              config.icon,
              size: (fontSize ?? 12) + 2,
              color: config.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            customText ?? config.text,
            style: TextStyle(
              color: config.color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (type) {
      case StatusType.booking:
        return _getBookingStatusConfig(status as BookingStatus);
      case StatusType.delivery:
        return _getDeliveryStatusConfig(status as DeliveryStatus);
      case StatusType.listing:
        return _getListingStatusConfig(status as bool);
      case StatusType.payment:
        return _getPaymentStatusConfig(status as String);
      case StatusType.user:
        return _getUserStatusConfig(status as String);
    }
  }

  _StatusConfig _getBookingStatusConfig(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const _StatusConfig(
          color: ColorConstants.warningColor,
          text: 'Pending Payment',
          icon: Icons.schedule,
          description: 'Awaiting payment confirmation',
        );
      case BookingStatus.confirmed:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Confirmed',
          icon: Icons.check_circle,
          description: 'Payment received, booking confirmed',
        );
      case BookingStatus.inProgress:
        return const _StatusConfig(
          color: ColorConstants.infoColor,
          text: 'Active',
          icon: Icons.play_circle,
          description: 'Currently rented out',
        );
      case BookingStatus.completed:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Completed',
          icon: Icons.check_circle_outline,
          description: 'Successfully completed',
        );
      case BookingStatus.cancelled:
        return const _StatusConfig(
          color: ColorConstants.errorColor,
          text: 'Cancelled',
          icon: Icons.cancel,
          description: 'Booking was cancelled',
        );
      case BookingStatus.overdue:
        return const _StatusConfig(
          color: ColorConstants.errorColor,
          text: 'Overdue',
          icon: Icons.warning,
          description: 'Return date has passed',
        );
    }
  }

  _StatusConfig _getDeliveryStatusConfig(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return const _StatusConfig(
          color: ColorConstants.warningColor,
          text: 'Needs Approval',
          icon: Icons.pending_actions,
          description: 'Waiting for lender approval',
        );
      case DeliveryStatus.approved:
        return const _StatusConfig(
          color: ColorConstants.infoColor,
          text: 'Approved',
          icon: Icons.thumb_up,
          description: 'Delivery approved by lender',
        );
      case DeliveryStatus.driverAssigned:
        return const _StatusConfig(
          color: ColorConstants.infoColor,
          text: 'Driver Assigned',
          icon: Icons.person_pin,
          description: 'Driver found and assigned',
        );
      case DeliveryStatus.driverHeadingToPickup:
        return const _StatusConfig(
          color: ColorConstants.primaryColor,
          text: 'En Route to Pickup',
          icon: Icons.directions_car,
          description: 'Driver heading to collect item',
        );
      case DeliveryStatus.itemCollected:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Item Collected',
          icon: Icons.inventory,
          description: 'Item picked up successfully',
        );
      case DeliveryStatus.driverHeadingToDelivery:
        return const _StatusConfig(
          color: ColorConstants.primaryColor,
          text: 'Out for Delivery',
          icon: Icons.local_shipping,
          description: 'On the way to delivery address',
        );
      case DeliveryStatus.itemDelivered:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Delivered',
          icon: Icons.check_circle,
          description: 'Successfully delivered',
        );
      case DeliveryStatus.returnRequested:
        return const _StatusConfig(
          color: ColorConstants.warningColor,
          text: 'Return Requested',
          icon: Icons.keyboard_return,
          description: 'Return delivery requested',
        );
      case DeliveryStatus.returnScheduled:
        return const _StatusConfig(
          color: ColorConstants.infoColor,
          text: 'Return Scheduled',
          icon: Icons.event_available,
          description: 'Return pickup scheduled',
        );
      case DeliveryStatus.returnCollected:
        return const _StatusConfig(
          color: ColorConstants.primaryColor,
          text: 'Return Collected',
          icon: Icons.assignment_returned,
          description: 'Item collected for return',
        );
      case DeliveryStatus.returnDelivered:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Return Delivered',
          icon: Icons.assignment_turned_in,
          description: 'Item returned to lender',
        );
      case DeliveryStatus.completed:
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Completed',
          icon: Icons.done_all,
          description: 'Delivery process complete',
        );
      case DeliveryStatus.cancelled:
        return const _StatusConfig(
          color: ColorConstants.errorColor,
          text: 'Cancelled',
          icon: Icons.cancel,
          description: 'Delivery was cancelled',
        );
    }
  }

  _StatusConfig _getListingStatusConfig(bool isActive) {
    if (isActive) {
      return const _StatusConfig(
        color: ColorConstants.successColor,
        text: 'Active',
        icon: Icons.visibility,
        description: 'Visible to renters',
      );
    } else {
      return const _StatusConfig(
        color: ColorConstants.grey,
        text: 'Inactive',
        icon: Icons.visibility_off,
        description: 'Hidden from renters',
      );
    }
  }

  _StatusConfig _getPaymentStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const _StatusConfig(
          color: ColorConstants.warningColor,
          text: 'Payment Pending',
          icon: Icons.schedule,
          description: 'Payment processing',
        );
      case 'completed':
      case 'paid':
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Paid',
          icon: Icons.check_circle,
          description: 'Payment successful',
        );
      case 'failed':
        return const _StatusConfig(
          color: ColorConstants.errorColor,
          text: 'Payment Failed',
          icon: Icons.error,
          description: 'Payment unsuccessful',
        );
      case 'refunded':
        return const _StatusConfig(
          color: ColorConstants.infoColor,
          text: 'Refunded',
          icon: Icons.undo,
          description: 'Amount refunded',
        );
      default:
        return const _StatusConfig(
          color: ColorConstants.grey,
          text: 'Unknown',
          icon: Icons.help,
          description: 'Unknown payment status',
        );
    }
  }

  _StatusConfig _getUserStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Online',
          icon: Icons.circle,
          description: 'User is online',
        );
      case 'offline':
        return const _StatusConfig(
          color: ColorConstants.grey,
          text: 'Offline',
          icon: Icons.circle_outlined,
          description: 'User is offline',
        );
      case 'verified':
        return const _StatusConfig(
          color: ColorConstants.successColor,
          text: 'Verified',
          icon: Icons.verified,
          description: 'Account verified',
        );
      case 'unverified':
        return const _StatusConfig(
          color: ColorConstants.warningColor,
          text: 'Unverified',
          icon: Icons.warning,
          description: 'Account needs verification',
        );
      case 'suspended':
        return const _StatusConfig(
          color: ColorConstants.errorColor,
          text: 'Suspended',
          icon: Icons.block,
          description: 'Account suspended',
        );
      default:
        return const _StatusConfig(
          color: ColorConstants.grey,
          text: 'Unknown',
          icon: Icons.help,
          description: 'Unknown user status',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final String text;
  final IconData? icon;
  final String description;

  const _StatusConfig({
    required this.color,
    required this.text,
    this.icon,
    required this.description,
  });
}

// Utility extension methods for easier usage
extension StatusChipHelpers on Widget {
  Widget withStatusTooltip(String description) {
    return Tooltip(
      message: description,
      child: this,
    );
  }
}

// Factory constructors for common use cases
class StatusChip {
  static Widget booking(BookingStatus status,
          {double? fontSize, bool showIcon = true}) =>
      UnifiedStatusChip(
        status: status,
        type: StatusType.booking,
        fontSize: fontSize,
        showIcon: showIcon,
      );

  static Widget delivery(DeliveryStatus status,
          {double? fontSize, bool showIcon = true}) =>
      UnifiedStatusChip(
        status: status,
        type: StatusType.delivery,
        fontSize: fontSize,
        showIcon: showIcon,
      );

  static Widget listing(bool isActive,
          {double? fontSize, bool showIcon = true}) =>
      UnifiedStatusChip(
        status: isActive,
        type: StatusType.listing,
        fontSize: fontSize,
        showIcon: showIcon,
      );

  static Widget payment(String status,
          {double? fontSize, bool showIcon = true}) =>
      UnifiedStatusChip(
        status: status,
        type: StatusType.payment,
        fontSize: fontSize,
        showIcon: showIcon,
      );

  static Widget user(String status, {double? fontSize, bool showIcon = true}) =>
      UnifiedStatusChip(
        status: status,
        type: StatusType.user,
        fontSize: fontSize,
        showIcon: showIcon,
      );

  static Widget custom(String text, Color color,
          {IconData? icon, double? fontSize}) =>
      UnifiedStatusChip(
        status: '',
        type: StatusType.user,
        customText: text,
        fontSize: fontSize,
        showIcon: icon != null,
      );
}
