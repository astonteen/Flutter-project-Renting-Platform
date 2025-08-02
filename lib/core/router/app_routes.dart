import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

class AppRoutes {
  // Route names
  static const String home = '/';
  static const String createListing = '/create-listing';
  static const String notifications = '/notifications';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String deliveryApproval = '/delivery/approval';
  static const String deliveryTracking = '/delivery/tracking';
  static const String lenderCalendar = '/lender/calendar';
  static const String earnings = '/earnings';
  static const String settings = '/settings';
  static const String savedAddresses = '/saved-addresses';
  static const String addEditAddress = '/add-edit-address';
  static const String addressSelection = '/address-selection';
  static const String bookingList = '/bookings';
  static const String bookingDetails = '/booking';

  // Navigation methods
  static void goHome(BuildContext context) {
    context.go(home);
  }

  static void goToCreateListing(BuildContext context) {
    context.go(createListing);
  }

  static void goToNotifications(BuildContext context) {
    context.go(notifications);
  }

  static void goToBookingList(BuildContext context) {
    context.go(bookingList);
  }

  static void goToProfile(BuildContext context) {
    context.go(profile);
  }

  static void goToDeliveryApproval(BuildContext context, String deliveryId) {
    context.go('$deliveryApproval/$deliveryId');
  }

  static void goToDeliveryTracking(BuildContext context, String deliveryId) {
    context.go('$deliveryTracking/$deliveryId');
  }

  static void goToLenderCalendar(BuildContext context) {
    context.go(lenderCalendar);
  }

  static void goToEarnings(BuildContext context) {
    context.go(earnings);
  }

  static void goToSettings(BuildContext context) {
    context.go(settings);
  }

  static void goToSavedAddresses(BuildContext context) {
    context.go(savedAddresses);
  }

  static void goToAddEditAddress(BuildContext context, {String? addressId}) {
    if (addressId != null) {
      context.go('$addEditAddress/$addressId');
    } else {
      context.go(addEditAddress);
    }
  }

  static void goToAddressSelection(BuildContext context,
      {String? returnRoute}) {
    if (returnRoute != null) {
      context.go('$addressSelection?return=$returnRoute');
    } else {
      context.go(addressSelection);
    }
  }

  static void goToBookingDetails(BuildContext context, String bookingId) {
    context.go('$bookingDetails/$bookingId');
  }

  // Push methods (for modal navigation)
  static void pushDeliveryApproval(BuildContext context, String deliveryId) {
    context.push('$deliveryApproval/$deliveryId');
  }

  static void pushAddEditAddress(BuildContext context, {String? addressId}) {
    if (addressId != null) {
      context.push('$addEditAddress/$addressId');
    } else {
      context.push(addEditAddress);
    }
  }

  static void pushAddressSelection(BuildContext context,
      {String? returnRoute}) {
    if (returnRoute != null) {
      context.push('$addressSelection?return=$returnRoute');
    } else {
      context.push(addressSelection);
    }
  }

  // Pop methods
  static void pop(BuildContext context) {
    context.pop();
  }

  static void popWithResult<T>(BuildContext context, T result) {
    context.pop(result);
  }

  // Replace methods (for auth flows)
  static void replaceWithHome(BuildContext context) {
    context.pushReplacement(home);
  }

  // Utility methods
  static String buildDeliveryApprovalRoute(String deliveryId) {
    return '$deliveryApproval/$deliveryId';
  }

  static String buildDeliveryTrackingRoute(String deliveryId) {
    return '$deliveryTracking/$deliveryId';
  }

  static String buildAddEditAddressRoute(String? addressId) {
    return addressId != null ? '$addEditAddress/$addressId' : addEditAddress;
  }
}
