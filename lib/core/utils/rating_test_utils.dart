import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/app_rating_service.dart';
import 'package:rent_ease/core/services/app_navigation_service.dart';

/// Test utilities for the rating system (debug builds only)
class RatingTestUtils {
  /// Test: Manually trigger a rating prompt
  static void testRatingPrompt() {
    if (!kDebugMode) return;

    debugPrint('🧪 Testing rating prompt...');

    const testPrompt = RatingPromptEvent(
      rentalId: 'test-rental-123',
      itemName: 'Test Camera Equipment',
      counterPartyName: 'John Doe',
      counterPartyId: 'test-user-456',
      isRenterRating: true,
    );

    AppNavigationService.showRatingPrompt(testPrompt);
  }

  /// Test: Check for pending ratings (useful after completing a rental)
  static Future<void> testCheckPendingRatings() async {
    if (!kDebugMode) return;

    debugPrint('🧪 Testing pending ratings check...');
    await AppRatingService.checkPendingRatings();
  }

  /// Test: Simulate notification tap for rating
  static Future<void> testRatingNotificationTap({
    required String rentalId,
  }) async {
    if (!kDebugMode) return;

    debugPrint('🧪 Testing rating notification tap...');

    final notificationData = {
      'action': 'rate_rental',
      'rental_id': rentalId,
      'route': '/rate-rental/$rentalId',
    };

    await AppNavigationService.handleNotificationTap(notificationData);
  }

  /// Test: Create a test review to trigger the database trigger
  static Map<String, String> getTestInstructions() {
    return {
      'title': 'Rating System Test Instructions',
      'steps': '''
1. Complete a rental (set status to 'completed' in database)
2. Wait for rating prompt to appear automatically
3. Or call RatingTestUtils.testRatingPrompt() from debug console
4. Rate the experience in the bottom sheet
5. Check that the other party gets notified
6. Verify database updates in 'rentals' and 'reviews' tables

NEW: Manual Leave Review Test:
1. Go to My Rentals > Past tab
2. Find a completed rental
3. Tap "Leave Review" button
4. Rate in the bottom sheet
5. Button should change to "Reviewed" after rating
6. Owner should get push notification
      ''',
      'database_check': '''
Database verification:
- Check rentals table for customer_rated_at/owner_rated_at timestamps
- Check reviews table for new review entry
- Check push_notification_logs for notification entries
      ''',
    };
  }

  /// Test the leave review flow from rentals screen
  static void testLeaveReviewFlow() {
    if (!kDebugMode) return;

    debugPrint('🧪 Testing Leave Review flow...');
    debugPrint('📋 Instructions:');
    debugPrint('1. Navigate to My Rentals > Past tab');
    debugPrint('2. Find a completed rental without customer_rated_at');
    debugPrint('3. Tap "Leave Review" button');
    debugPrint('4. Complete the rating');
    debugPrint('5. Verify button changes to "Reviewed"');
    debugPrint('6. Check database for rating data');
  }
}
