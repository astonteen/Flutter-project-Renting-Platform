import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/services/app_rating_service.dart';
import 'package:rent_ease/features/reviews/presentation/widgets/rate_rental_sheet.dart';

/// Service to handle app-wide navigation, especially from notifications
class AppNavigationService {
  static AppNavigationService? _instance;
  static AppNavigationService get instance =>
      _instance ??= AppNavigationService._internal();
  AppNavigationService._internal();

  BuildContext? _context;

  /// Set the current navigation context
  static void setContext(BuildContext context) {
    instance._context = context;
  }

  /// Handle notification tap navigation
  static Future<void> handleNotificationTap(Map<String, dynamic>? data) async {
    if (data == null) return;

    final route = data['route'] as String?;
    final action = data['action'] as String?;

    debugPrint('🔔 Handling notification tap: route=$route, action=$action');

    if (action == 'rate_rental' && route != null) {
      await _handleRatingNotification(data);
    } else if (route != null) {
      await _navigateToRoute(route);
    }
  }

  static Future<void> _handleRatingNotification(
      Map<String, dynamic> data) async {
    final context = instance._context;
    if (context == null || !context.mounted) {
      debugPrint('⚠️  No navigation context available');
      return;
    }

    final rentalId = data['rental_id'] as String?;
    if (rentalId == null) {
      debugPrint('⚠️  No rental ID in rating notification');
      return;
    }

    try {
      // Fetch rental details to create a rating prompt
      final rentalDetails = await _fetchRentalDetailsForRating(rentalId);
      if (rentalDetails != null) {
        // Show rating bottom sheet
        if (context.mounted) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RateRentalSheet(
              promptData: rentalDetails,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling rating notification: $e');
    }
  }

  static Future<RatingPromptEvent?> _fetchRentalDetailsForRating(
      String rentalId) async {
    try {
      // This would fetch rental details and create a RatingPromptEvent
      // For now, return a placeholder
      return RatingPromptEvent(
        rentalId: rentalId,
        itemName: 'Item', // TODO: Fetch actual item name
        counterPartyName: 'User', // TODO: Fetch actual user name
        counterPartyId: 'user-id', // TODO: Fetch actual user ID
        isRenterRating: true, // TODO: Determine based on current user
      );
    } catch (e) {
      debugPrint('❌ Error fetching rental details: $e');
      return null;
    }
  }

  static Future<void> _navigateToRoute(String route) async {
    final context = instance._context;
    if (context == null || !context.mounted) {
      debugPrint('⚠️  No navigation context available');
      return;
    }

    try {
      context.go(route);
    } catch (e) {
      debugPrint('❌ Error navigating to route $route: $e');
    }
  }

  /// Navigate to a specific screen programmatically
  static void navigateTo(String route) {
    final context = instance._context;
    if (context != null && context.mounted) {
      context.go(route);
    }
  }

  /// Show rating prompt manually (useful for testing)
  static void showRatingPrompt(RatingPromptEvent promptData) {
    final context = instance._context;
    if (context != null && context.mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RateRentalSheet(
          promptData: promptData,
        ),
      );
    }
  }
}
