import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

class StatusMessages {
  /// Get user-friendly status message based on status and user role
  static String getStatusMessage(dynamic status, String userRole,
      {String? itemName}) {
    if (status is BookingStatus) {
      return _getBookingStatusMessage(status, userRole, itemName: itemName);
    } else if (status is DeliveryStatus) {
      return _getDeliveryStatusMessage(status, userRole, itemName: itemName);
    }
    return 'Status: ${status.toString()}';
  }

  /// Get status description for additional context
  static String getStatusDescription(dynamic status, String userRole) {
    if (status is BookingStatus) {
      return _getBookingStatusDescription(status, userRole);
    } else if (status is DeliveryStatus) {
      return _getDeliveryStatusDescription(status, userRole);
    }
    return '';
  }

  /// Get appropriate color for status
  static Color getStatusColor(dynamic status) {
    if (status is BookingStatus) {
      return _getBookingStatusColor(status);
    } else if (status is DeliveryStatus) {
      return _getDeliveryStatusColor(status);
    }
    return ColorConstants.grey;
  }

  /// Get next action text for the user
  static String? getNextAction(dynamic status, String userRole) {
    if (status is BookingStatus) {
      return _getBookingNextAction(status, userRole);
    } else if (status is DeliveryStatus) {
      return _getDeliveryNextAction(status, userRole);
    }
    return null;
  }

  /// Get secondary action text for the user
  static String? getSecondaryAction(dynamic status, String userRole) {
    if (status is BookingStatus) {
      return _getBookingSecondaryAction(status, userRole);
    } else if (status is DeliveryStatus) {
      return _getDeliverySecondaryAction(status, userRole);
    }
    return null;
  }

  // Private methods for booking status
  static String _getBookingStatusMessage(BookingStatus status, String userRole,
      {String? itemName}) {
    final isLender = userRole == 'lender';
    final isRenter = userRole == 'renter';
    final item = itemName != null ? ' for $itemName' : '';

    switch (status) {
      case BookingStatus.pending:
        return isLender
            ? 'New booking request$item awaiting approval'
            : 'Booking request sent - waiting for approval';

      case BookingStatus.confirmed:
        return isLender
            ? 'Booking confirmed$item - prepare for pickup'
            : 'Booking approved! You\'ll be notified when ready';

      case BookingStatus.inProgress:
        return isRenter
            ? 'Enjoy your rental$item!'
            : 'Item$item is currently rented out';

      case BookingStatus.completed:
        return 'Rental$item completed successfully!';

      case BookingStatus.cancelled:
        return 'Booking$item was cancelled';

      case BookingStatus.overdue:
        return isRenter
            ? 'Item$item return is overdue'
            : 'Rental$item is overdue';
    }
  }

  static String _getBookingStatusDescription(
      BookingStatus status, String userRole) {
    final isLender = userRole == 'lender';
    final isRenter = userRole == 'renter';

    switch (status) {
      case BookingStatus.pending:
        return isLender
            ? 'Review the booking details and approve or decline'
            : 'The lender will review your request shortly';

      case BookingStatus.confirmed:
        return isLender
            ? 'Get your item ready for pickup or delivery'
            : 'You\'ll receive pickup instructions soon';

      case BookingStatus.inProgress:
        return isRenter
            ? 'Remember to return the item on time'
            : 'The renter is using your item';

      case BookingStatus.completed:
        return 'Thank you for using RentEase';

      case BookingStatus.cancelled:
        return 'No charges were made for this booking';

      case BookingStatus.overdue:
        return isRenter
            ? 'Please return immediately to avoid additional charges'
            : 'Contact the renter about the overdue return';
    }
  }

  static Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return ColorConstants.warningColor;
      case BookingStatus.confirmed:
        return ColorConstants.successColor;
      case BookingStatus.inProgress:
        return ColorConstants.infoColor;
      case BookingStatus.completed:
        return ColorConstants.successColor;
      case BookingStatus.cancelled:
        return ColorConstants.errorColor;
      case BookingStatus.overdue:
        return ColorConstants.errorColor;
    }
  }

  static String? _getBookingNextAction(BookingStatus status, String userRole) {
    final isLender = userRole == 'lender';
    final isRenter = userRole == 'renter';

    switch (status) {
      case BookingStatus.pending:
        return isLender ? 'Approve Booking' : 'View Details';
      case BookingStatus.confirmed:
        return isLender ? 'Mark Ready for Pickup' : 'View Timeline';
      case BookingStatus.inProgress:
        return isRenter ? 'Prepare for Return' : 'Track Rental';
      case BookingStatus.completed:
        return 'Leave Review';
      case BookingStatus.cancelled:
        return 'Find Similar Items';
      case BookingStatus.overdue:
        return isRenter ? 'Return Now' : 'Contact Renter';
    }
  }

  static String? _getBookingSecondaryAction(
      BookingStatus status, String userRole) {
    final isLender = userRole == 'lender';
    final isRenter = userRole == 'renter';

    switch (status) {
      case BookingStatus.pending:
        return isLender ? 'Decline' : null;
      case BookingStatus.confirmed:
        return 'Contact ${isLender ? 'Renter' : 'Lender'}';
      case BookingStatus.inProgress:
        return 'Contact ${isRenter ? 'Lender' : 'Renter'}';
      case BookingStatus.completed:
        return 'Rent Again';
      case BookingStatus.overdue:
        return isRenter ? 'Contact Support' : 'Report Issue';
      default:
        return null;
    }
  }

  // Private methods for delivery status
  static String _getDeliveryStatusMessage(
      DeliveryStatus status, String userRole,
      {String? itemName}) {
    final item = itemName != null ? ' for $itemName' : '';

    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Delivery$item needs approval';
      case DeliveryStatus.driverAssigned:
        return 'Driver assigned$item';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Driver heading to pickup$item';
      case DeliveryStatus.itemCollected:
        return 'Item$item collected by driver';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Out for delivery$item';
      case DeliveryStatus.itemDelivered:
        return 'Item$item delivered successfully!';
      case DeliveryStatus.returnRequested:
        return 'Return requested$item';
      case DeliveryStatus.completed:
        return 'Delivery$item completed';
      default:
        return 'Delivery Status: ${status.toString()}';
    }
  }

  static String _getDeliveryStatusDescription(
      DeliveryStatus status, String userRole) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Review delivery details and approve driver assignment';
      case DeliveryStatus.driverAssigned:
        return 'Your driver will contact you soon';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Prepare your item and wait for the driver';
      case DeliveryStatus.itemCollected:
        return 'Driver is now heading to the delivery address';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Your item is on the way to the destination';
      case DeliveryStatus.itemDelivered:
        return 'The recipient has received the item';
      case DeliveryStatus.returnRequested:
        return 'A return delivery has been requested';
      case DeliveryStatus.completed:
        return 'All delivery services have been completed';
      default:
        return '';
    }
  }

  static Color _getDeliveryStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return ColorConstants.warningColor;
      case DeliveryStatus.approved:
      case DeliveryStatus.driverAssigned:
        return ColorConstants.infoColor;
      case DeliveryStatus.driverHeadingToPickup:
      case DeliveryStatus.driverHeadingToDelivery:
        return ColorConstants.primaryColor;
      case DeliveryStatus.itemCollected:
      case DeliveryStatus.itemDelivered:
      case DeliveryStatus.completed:
        return ColorConstants.successColor;
      case DeliveryStatus.returnRequested:
        return ColorConstants.warningColor;
      case DeliveryStatus.cancelled:
        return ColorConstants.errorColor;
      default:
        return ColorConstants.grey;
    }
  }

  static String? _getDeliveryNextAction(
      DeliveryStatus status, String userRole) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Approve Delivery';
      case DeliveryStatus.driverAssigned:
        return 'Track Driver';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Track Progress';
      case DeliveryStatus.itemDelivered:
        return 'View Proof';
      case DeliveryStatus.completed:
        return 'Rate Driver';
      default:
        return null;
    }
  }

  static String? _getDeliverySecondaryAction(
      DeliveryStatus status, String userRole) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'View Details';
      case DeliveryStatus.driverAssigned:
      case DeliveryStatus.driverHeadingToPickup:
        return 'Contact Driver';
      case DeliveryStatus.itemDelivered:
        return 'Rate Driver';
      default:
        return null;
    }
  }

  /// Get progress value for status (0.0 to 1.0)
  static double getProgressValue(dynamic status) {
    if (status is BookingStatus) {
      switch (status) {
        case BookingStatus.pending:
          return 0.1;
        case BookingStatus.confirmed:
          return 0.3;
        case BookingStatus.inProgress:
          return 0.7;
        case BookingStatus.completed:
          return 1.0;
        default:
          return 0.0;
      }
    } else if (status is DeliveryStatus) {
      switch (status) {
        case DeliveryStatus.pendingApproval:
          return 0.1;
        case DeliveryStatus.approved:
        case DeliveryStatus.driverAssigned:
          return 0.3;
        case DeliveryStatus.driverHeadingToPickup:
          return 0.5;
        case DeliveryStatus.itemCollected:
          return 0.7;
        case DeliveryStatus.driverHeadingToDelivery:
          return 0.8;
        case DeliveryStatus.itemDelivered:
        case DeliveryStatus.completed:
          return 1.0;
        default:
          return 0.0;
      }
    }
    return 0.0;
  }

  /// Get estimated time remaining message
  static String? getTimeEstimate(dynamic status) {
    if (status is BookingStatus) {
      switch (status) {
        case BookingStatus.pending:
          return 'Usually approved within 2 hours';
        case BookingStatus.confirmed:
          return 'Item will be ready within 24 hours';

        default:
          return null;
      }
    } else if (status is DeliveryStatus) {
      switch (status) {
        case DeliveryStatus.driverHeadingToPickup:
          return 'Driver arriving in 10-30 minutes';
        case DeliveryStatus.driverHeadingToDelivery:
          return 'Delivery in 30-60 minutes';
        default:
          return null;
      }
    }
    return null;
  }
}
