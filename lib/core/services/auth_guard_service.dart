import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class AuthGuardService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _profileSetupCompletedKey = 'profile_setup_completed';

  /// Check if user has completed onboarding
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      debugPrint('Error setting onboarding completed: $e');
    }
  }

  /// Check if user has completed profile setup
  static Future<bool> isProfileSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_profileSetupCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking profile setup status: $e');
      return false;
    }
  }

  /// Mark profile setup as completed
  static Future<void> setProfileSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_profileSetupCompletedKey, true);
    } catch (e) {
      debugPrint('Error setting profile setup completed: $e');
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    try {
      if (!SupabaseService.isInitialized) {
        return false;
      }
      return SupabaseService.currentUser != null;
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      return false;
    }
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    try {
      if (!SupabaseService.isInitialized) {
        return null;
      }
      return SupabaseService.currentUser?.id;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  /// Check if user has a valid session
  static bool hasValidSession() {
    try {
      if (!SupabaseService.isInitialized) {
        return false;
      }
      final user = SupabaseService.currentUser;
      return user != null && user.emailConfirmedAt != null;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }

  /// Check if user profile exists in database (for existing users)
  static Future<bool> hasExistingProfile() async {
    try {
      if (!SupabaseService.isInitialized) {
        return false;
      }

      final userId = getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final profile = await SupabaseService.getUserProfile(userId);
      return profile != null && profile['primary_role'] != null;
    } catch (e) {
      debugPrint('Error checking existing profile: $e');
      return false;
    }
  }

  /// Determine the appropriate route based on authentication state
  static Future<String?> getRedirectRoute(String currentLocation) async {
    try {
      // Skip redirect for splash screen initially
      if (currentLocation == '/splash') {
        return null;
      }

      final isOnboardingDone = await isOnboardingCompleted();
      final isProfileSetupDone = await isProfileSetupCompleted();
      final isAuth = isAuthenticated();

      debugPrint('Auth Guard Check:');
      debugPrint('  Current location: $currentLocation');
      debugPrint('  Onboarding completed: $isOnboardingDone');
      debugPrint('  Profile setup completed: $isProfileSetupDone');
      debugPrint('  Is authenticated: $isAuth');

      // Priority 1: If fully set up, ensure user is on the correct main screen based on active role
      if (isOnboardingDone && isAuth && isProfileSetupDone) {
        // Determine the correct landing route for the active role
        String targetRoute = '/home'; // default for renters
        try {
          final roleSwitchingService = getIt<RoleSwitchingService>();
          final activeRole = roleSwitchingService.activeRole;
          if (activeRole == 'driver') {
            targetRoute = '/driver-dashboard';
          } else if (activeRole == 'lender') {
            // Lenders land on calendar for now – adjust if needed
            targetRoute = '/calendar';
          }
        } catch (_) {
          // Fallback to default if service not available yet
        }

        if (_isAuthRoute(currentLocation) ||
            _isProfileSetupRoute(currentLocation) ||
            currentLocation == '/onboarding' ||
            currentLocation == '/') {
          debugPrint('  Redirecting to $targetRoute (fully set up)');
          return targetRoute;
        }
        return null; // User is in main app, no redirect needed
      }

      // Priority 2: If authenticated but profile not set up
      if (isAuth && !isProfileSetupDone) {
        // Check if user has existing profile in database (returning user)
        final hasProfile = await hasExistingProfile();
        if (hasProfile) {
          // Existing user - mark profile as complete and redirect to home
          await setProfileSetupCompleted();
          debugPrint('  Found existing profile, redirecting to home');
          return '/home';
        } else {
          // New user - needs profile setup
          if (currentLocation != '/role-selection' &&
              currentLocation != '/profile-setup') {
            debugPrint('  Redirecting to role selection (new user)');
            return '/role-selection';
          }
        }
        return null; // User is in profile setup flow
      }

      // Priority 3: If onboarded but not authenticated
      if (isOnboardingDone && !isAuth) {
        if (!_isAuthRoute(currentLocation)) {
          debugPrint('  Redirecting to login (onboarded but not auth)');
          return '/login';
        }
        return null; // User is in auth flow
      }

      // Priority 4: If not onboarded
      if (!isOnboardingDone) {
        if (currentLocation != '/onboarding') {
          debugPrint('  Redirecting to onboarding (not onboarded)');
          return '/onboarding';
        }
        return null; // User is in onboarding
      }

      debugPrint('  No redirect needed');
      return null;
    } catch (e) {
      debugPrint('Error in auth guard: $e');
      return null;
    }
  }

  /// Check if the current route is an authentication route
  static bool _isAuthRoute(String location) {
    return location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/forgot-password') ||
        location.startsWith('/reset-password') ||
        location.startsWith('/splash');
  }

  /// Check if the current route is a profile setup route
  static bool _isProfileSetupRoute(String location) {
    return location.startsWith('/role-selection') ||
        location.startsWith('/profile-setup');
  }

  /// Clear stored data for logout (preserve onboarding for existing users)
  static Future<void> clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only clear profile setup, but preserve onboarding for existing users
      await prefs.remove(_profileSetupCompletedKey);

      // Clear role switching data
      try {
        final roleSwitchingService = getIt<RoleSwitchingService>();
        await roleSwitchingService.clearRoleData();
      } catch (e) {
        debugPrint('Error clearing role switching data: $e');
      }

      // Don't clear onboarding for existing users
      debugPrint('Cleared profile setup data, preserved onboarding status');
    } catch (e) {
      debugPrint('Error clearing stored data: $e');
    }
  }

  /// Clear all data including onboarding (for complete reset)
  static Future<void> clearAllStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_profileSetupCompletedKey);
      debugPrint('Cleared all stored data');
    } catch (e) {
      debugPrint('Error clearing all stored data: $e');
    }
  }

  /// Reset onboarding status (for testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }
}
