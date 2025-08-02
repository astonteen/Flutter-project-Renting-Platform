class AppConstants {
  // App info
  static const String appName = 'RentEase';
  static const String appTagline = 'Rent, List, Deliver – All in One Place';
  static const String appVersion = '1.0.0';

  // API endpoints
  static const String baseUrl = 'https://api.rentease.com';

  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Pagination
  static const int defaultPageSize = 10;

  // Map defaults
  static const double defaultMapZoom = 14.0;

  // Image quality
  static const int imageQuality = 85;
  static const double maxImageWidth = 1080.0;
  static const double maxImageHeight = 1920.0;

  // Booking Management
  static const int maxRecentBookings = 5;
  static const Duration bookingCacheTimeout = Duration(minutes: 10);

  // Mark Ready Timing Rules
  static const int maxDaysEarlyPickup = 2;
  static const int maxDaysEarlyDelivery = 3;

  // Simplified Maintenance Types
  static const List<String> maintenanceTypes = [
    'cleaning',
    'inspection',
    'repair',
  ];

  // Legacy constants for backward compatibility
  // These are kept for existing tests but the actual logic is now in the database trigger
  static const Map<String, int> returnBufferDaysByCategory = {
    'electronics': 3,
    'clothing': 1,
    'tools': 2,
    'sports': 2,
    'automotive': 4,
    'photography': 3,
    'musical_instruments': 3,
    'furniture': 2,
    'outdoor': 2,
    'default': 2,
  };

  static const Map<String, int> returnBufferDaysByCondition = {
    'excellent': 0,
    'good': 0,
    'fair': 1,
    'poor': 2,
  };

  static const int additionalBufferForDeliveryReturn = 1;
  static const int additionalBufferForHighValue = 1;

  static const Map<String, int> preventiveMaintenanceDays = {
    'electronics': 30,
    'automotive': 14,
    'tools': 21,
    'sports': 28,
    'default': 30,
  };

  static const Map<String, int> maintenanceAfterRentals = {
    'electronics': 10,
    'automotive': 5,
    'tools': 8,
    'sports': 12,
    'default': 10,
  };

  static const Map<String, int> maintenanceBlockDuration = {
    'cleaning': 1,
    'inspection': 1,
    'repair': 3,
    'deep_maintenance': 2,
    'preventive': 1,
  };

  // App Lifecycle
}
