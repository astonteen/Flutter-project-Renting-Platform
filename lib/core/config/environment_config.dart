import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service
/// Manages all environment variables with proper grouping and naming
class EnvironmentConfig {
  static bool _isInitialized = false;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment file based on build mode
      String envFile = '.env.development';

      if (kReleaseMode) {
        envFile = '.env.production';
      } else if (kProfileMode) {
        envFile = '.env.staging';
      }

      await dotenv.load(fileName: envFile);
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Environment loaded: $envFile');
        debugPrint('Environment: $appEnvironment');
      }
    } catch (e) {
      // Fallback to hardcoded values for development
      debugPrint('Failed to load environment file, using fallback values: $e');
      _isInitialized = true;
    }
  }

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://iwefwascboexieneeaks.supabase.co';

  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '15') ?? 15;

  // Database Configuration
  static String get dbSupabaseUrl =>
      dotenv.env['DB_SUPABASE_URL'] ??
      'https://iwefwascboexieneeaks.supabase.co';

  static String get dbSupabaseAnonKey =>
      dotenv.env['DB_SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3ZWZ3YXNjYm9leGllbmVlYWtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3OTk4NzksImV4cCI6MjA2NTM3NTg3OX0.-nE7W4PonUzDjimyEEY9xvqm8rKvYa1ASjJvaRi1w44';

  // Authentication Configuration
  static int get authSessionTimeoutDays =>
      int.tryParse(dotenv.env['AUTH_SESSION_TIMEOUT_DAYS'] ?? '30') ?? 30;

  static int get authInactivityLogoutDays =>
      int.tryParse(dotenv.env['AUTH_INACTIVITY_LOGOUT_DAYS'] ?? '7') ?? 7;

  static bool get authRequireEmailVerification =>
      dotenv.env['AUTH_REQUIRE_EMAIL_VERIFICATION']?.toLowerCase() == 'true';

  static bool get authEnableBiometric =>
      dotenv.env['AUTH_ENABLE_BIOMETRIC']?.toLowerCase() != 'false';

  static String get authPasswordResetRedirect =>
      dotenv.env['AUTH_PASSWORD_RESET_REDIRECT'] ??
      'com.rentease.app://reset-password';

  // Storage Configuration
  static String get storageBucketAvatars =>
      dotenv.env['STORAGE_BUCKET_AVATARS'] ?? 'avatars';

  static String get storageBucketListings =>
      dotenv.env['STORAGE_BUCKET_LISTINGS'] ?? 'listing-images';

  static String get storageBucketDocuments =>
      dotenv.env['STORAGE_BUCKET_DOCUMENTS'] ?? 'documents';

  static int get storageMaxFileSizeMB =>
      int.tryParse(dotenv.env['STORAGE_MAX_FILE_SIZE_MB'] ?? '10') ?? 10;

  // Notification Configuration
  static bool get notificationsEnabled =>
      dotenv.env['NOTIFICATIONS_ENABLED']?.toLowerCase() != 'false';

  static String get notificationsFcmSenderId =>
      dotenv.env['NOTIFICATIONS_FCM_SENDER_ID'] ?? '';

  // Analytics Configuration
  static bool get analyticsEnabled =>
      dotenv.env['ANALYTICS_ENABLED']?.toLowerCase() == 'true';

  static bool get analyticsDebugMode =>
      dotenv.env['ANALYTICS_DEBUG_MODE']?.toLowerCase() == 'true';

  // Google Services Configuration
  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Rent Ease';

  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static String get appEnvironment =>
      dotenv.env['APP_ENVIRONMENT'] ?? 'development';

  static bool get appDebugMode =>
      dotenv.env['APP_DEBUG_MODE']?.toLowerCase() != 'false';

  // Feature Flags
  static bool get featurePaymentEnabled =>
      dotenv.env['FEATURE_PAYMENT_ENABLED']?.toLowerCase() == 'true';

  static bool get featureDeliveryEnabled =>
      dotenv.env['FEATURE_DELIVERY_ENABLED']?.toLowerCase() != 'false';

  static bool get featureMessagingEnabled =>
      dotenv.env['FEATURE_MESSAGING_ENABLED']?.toLowerCase() != 'false';

  static bool get featureAnalyticsEnabled =>
      dotenv.env['FEATURE_ANALYTICS_ENABLED']?.toLowerCase() == 'true';

  // Utility methods
  static bool get isProduction => appEnvironment == 'production';
  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isStaging => appEnvironment == 'staging';

  // Debug information
  static Map<String, dynamic> get debugInfo => {
        'environment': appEnvironment,
        'isInitialized': _isInitialized,
        'apiBaseUrl': apiBaseUrl,
        'dbSupabaseUrl': dbSupabaseUrl,
        'authEnableBiometric': authEnableBiometric,
        'notificationsEnabled': notificationsEnabled,
        'analyticsEnabled': analyticsEnabled,
        'featureFlags': {
          'payment': featurePaymentEnabled,
          'delivery': featureDeliveryEnabled,
          'messaging': featureMessagingEnabled,
          'analytics': featureAnalyticsEnabled,
        },
      };
}
